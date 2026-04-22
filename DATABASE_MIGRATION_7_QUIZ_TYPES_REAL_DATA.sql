-- ==============================================
-- 7 QUIZ TYPES (REAL DATA) MIGRATION
-- Source vocabulary table: public.lesson_vocabulary
-- Target tables: public.lesson_questions, public.lesson_options,
--                public.lesson_answer_keys, public.user_answers
-- ==============================================

-- 0) Extensions
create extension if not exists "uuid-ossp" with schema extensions;

-- 1) Recreate core quiz tables
-- NOTE: This will remove old quiz data.
drop table if exists public.user_answers cascade;
drop table if exists public.lesson_answer_keys cascade;
drop table if exists public.lesson_options cascade;
drop table if exists public.lesson_questions cascade;
drop table if exists public.lesson_question_types cascade;

create table public.lesson_question_types (
  code varchar(50) primary key,
  display_name varchar(100) not null,
  description text,
  created_at timestamp without time zone default now()
) tablespace pg_default;

insert into public.lesson_question_types (code, display_name, description)
values
  ('mcq_en_vi', 'Multiple Choice EN -> VI', 'Chọn nghĩa tiếng Việt đúng của từ tiếng Anh'),
  ('mcq_vi_en', 'Multiple Choice VI -> EN', 'Chọn từ tiếng Anh đúng theo nghĩa tiếng Việt'),
  ('fill_blank', 'Fill In Blank', 'Điền từ còn thiếu vào câu ví dụ'),
  ('unscramble', 'Unscramble Word', 'Sắp xếp chữ cái thành từ đúng'),
  ('true_false', 'True/False Meaning', 'Xác định phát biểu nghĩa đúng hay sai'),
  ('matching', 'Matching Pairs', 'Nối từ tiếng Anh với nghĩa tiếng Việt tương ứng'),
  ('spelling', 'Spelling From Meaning', 'Viết đúng chính tả từ theo nghĩa tiếng Việt')
on conflict (code) do nothing;

create table public.lesson_questions (
  id uuid not null default extensions.uuid_generate_v4(),
  created_at timestamp without time zone null default now(),
  lesson_id uuid not null,
  question_type character varying(50) not null,
  question_text text not null,
  audio_url character varying(255) null,
  image_url character varying(255) null,
  question_order integer not null,
  explanation text null,
  correct_answer text null,
  vietnamese_text text null,
  conversation_context text null,
  points integer null default 10,
  vocabulary_ids uuid[] null,
  difficulty_level integer null default 1,
  constraint lesson_questions_pkey primary key (id),
  constraint lesson_questions_lesson_id_question_order_key unique (lesson_id, question_order),
  constraint lesson_questions_lesson_id_fkey foreign key (lesson_id)
    references public.lessons (id) on delete cascade,
  constraint lesson_questions_type_fkey foreign key (question_type)
    references public.lesson_question_types (code)
) tablespace pg_default;

create index if not exists idx_lesson_questions_lesson_id
  on public.lesson_questions using btree (lesson_id) tablespace pg_default;

create index if not exists idx_lesson_questions_type
  on public.lesson_questions using btree (question_type) tablespace pg_default;

create table public.lesson_options (
  id uuid not null default extensions.uuid_generate_v4(),
  created_at timestamp without time zone null default now(),
  question_id uuid not null,
  option_text text not null,
  option_image_url character varying(255) null,
  is_correct boolean null default false,
  option_order integer not null,
  explanation text null,
  match_pair_id character varying(50) null,
  constraint lesson_options_pkey primary key (id),
  constraint lesson_options_question_id_fkey foreign key (question_id)
    references public.lesson_questions (id) on delete cascade
) tablespace pg_default;

create index if not exists idx_lesson_options_question_id
  on public.lesson_options using btree (question_id) tablespace pg_default;

alter table public.lesson_questions enable row level security;
alter table public.lesson_options enable row level security;

drop policy if exists "Questions are viewable by all" on public.lesson_questions;
drop policy if exists "Authenticated users can manage quiz questions" on public.lesson_questions;
create policy "Questions are viewable by all"
  on public.lesson_questions
  for select
  using (true);

create policy "Authenticated users can manage quiz questions"
  on public.lesson_questions
  for all
  to authenticated
  using (true)
  with check (true);

drop policy if exists "Options are viewable by all" on public.lesson_options;
drop policy if exists "Authenticated users can manage quiz options" on public.lesson_options;
create policy "Options are viewable by all"
  on public.lesson_options
  for select
  using (true);

create policy "Authenticated users can manage quiz options"
  on public.lesson_options
  for all
  to authenticated
  using (true)
  with check (true);

create table public.lesson_answer_keys (
  question_id uuid not null,
  answer_kind varchar(20) not null default 'text', -- text | json
  correct_text text null,
  correct_text_alt text[] null,
  correct_json jsonb null,
  case_sensitive boolean not null default false,
  created_at timestamp without time zone default now(),
  constraint lesson_answer_keys_pkey primary key (question_id),
  constraint lesson_answer_keys_question_id_fkey foreign key (question_id)
    references public.lesson_questions (id) on delete cascade
) tablespace pg_default;

create table public.user_answers (
  id uuid not null default extensions.uuid_generate_v4(),
  created_at timestamp without time zone null default now(),
  user_id uuid not null,
  question_id uuid not null,
  selected_option_id uuid null,
  is_correct boolean null,
  answer_text text null,
  score_awarded integer null default 0,
  time_spent_seconds integer null,
  constraint user_answers_pkey primary key (id),
  constraint user_answers_question_id_fkey foreign key (question_id)
    references public.lesson_questions (id) on delete cascade,
  constraint user_answers_selected_option_id_fkey foreign key (selected_option_id)
    references public.lesson_options (id),
  constraint user_answers_user_id_fkey foreign key (user_id)
    references auth.users (id) on delete cascade
) tablespace pg_default;

create index if not exists idx_user_answers_user_id
  on public.user_answers using btree (user_id) tablespace pg_default;

create index if not exists idx_user_answers_question_id
  on public.user_answers using btree (question_id) tablespace pg_default;

-- 2) Helper function for answer normalization
create or replace function public.normalize_answer(input_text text)
returns text
language sql
immutable
as $$
  select lower(regexp_replace(trim(coalesce(input_text, '')), '\\s+', ' ', 'g'))
$$;

-- 3) Generate questions for one lesson based on real vocabulary
create or replace function public.generate_questions_for_lesson(
  p_lesson_id uuid,
  p_words_per_type int default 8
)
returns void
language plpgsql
as $$
declare
  v_order int := 1;
  v_qid uuid;
  v_scrambled text;
  v_false_meaning text;
  v_is_true boolean;
  r record;
  m record;
begin
  -- Remove old generated questions for this lesson
  delete from public.lesson_questions where lesson_id = p_lesson_id;

  -- Safety check: lesson must have vocabulary
  if not exists (
    select 1
    from public.lesson_vocabulary lv
    where lv.lesson_id = p_lesson_id
      and coalesce(trim(lv.term), '') <> ''
      and coalesce(trim(lv.meaning), '') <> ''
  ) then
    raise notice 'No vocabulary found for lesson %', p_lesson_id;
    return;
  end if;

  -- =====================================
  -- TYPE 1: MCQ EN -> VI
  -- =====================================
  for r in
    select lv.id, lv.term, lv.meaning, coalesce(lv.vietnamese_meaning, lv.meaning) as vi_meaning
    from public.lesson_vocabulary lv
    where lv.lesson_id = p_lesson_id
      and coalesce(trim(lv.term), '') <> ''
      and coalesce(trim(lv.meaning), '') <> ''
    order by random()
    limit p_words_per_type
  loop
    insert into public.lesson_questions (
      lesson_id, question_type, question_text, question_order,
      explanation, correct_answer, vietnamese_text, vocabulary_ids, difficulty_level, points
    ) values (
      p_lesson_id,
      'mcq_en_vi',
      format('Nghĩa tiếng Việt đúng của từ "%s" là gì?', r.term),
      v_order,
      format('"%s" có nghĩa là "%s".', r.term, r.vi_meaning),
      r.vi_meaning,
      r.vi_meaning,
      array[r.id],
      1,
      10
    ) returning id into v_qid;

    with opts as (
      select r.vi_meaning::text as option_text, true as is_correct
      union all
      select x.vi_meaning::text as option_text, false as is_correct
      from (
        select distinct coalesce(lv2.vietnamese_meaning, lv2.meaning) as vi_meaning
        from public.lesson_vocabulary lv2
        where lv2.id <> r.id
          and coalesce(trim(lv2.meaning), '') <> ''
          and coalesce(trim(coalesce(lv2.vietnamese_meaning, lv2.meaning)), '') <> ''
        order by random()
        limit 3
      ) x
    ), shuffled as (
      select option_text, is_correct, row_number() over(order by random()) as rn
      from opts
    )
    insert into public.lesson_options (question_id, option_text, is_correct, option_order)
    select v_qid, option_text, is_correct, rn
    from shuffled;

    v_order := v_order + 1;
  end loop;

  -- =====================================
  -- TYPE 2: MCQ VI -> EN
  -- =====================================
  for r in
    select lv.id, lv.term, lv.meaning, coalesce(lv.vietnamese_meaning, lv.meaning) as vi_meaning
    from public.lesson_vocabulary lv
    where lv.lesson_id = p_lesson_id
      and coalesce(trim(lv.term), '') <> ''
      and coalesce(trim(lv.meaning), '') <> ''
    order by random()
    limit p_words_per_type
  loop
    insert into public.lesson_questions (
      lesson_id, question_type, question_text, question_order,
      explanation, correct_answer, vietnamese_text, vocabulary_ids, difficulty_level, points
    ) values (
      p_lesson_id,
      'mcq_vi_en',
      format('Từ tiếng Anh đúng cho nghĩa "%s" là gì?', r.vi_meaning),
      v_order,
      format('Nghĩa "%s" tương ứng với từ "%s".', r.vi_meaning, r.term),
      r.term,
      r.vi_meaning,
      array[r.id],
      1,
      10
    ) returning id into v_qid;

    with opts as (
      select r.term::text as option_text, true as is_correct
      union all
      select x.term::text as option_text, false as is_correct
      from (
        select distinct lv2.term
        from public.lesson_vocabulary lv2
        where lv2.id <> r.id
          and coalesce(trim(lv2.term), '') <> ''
        order by random()
        limit 3
      ) x
    ), shuffled as (
      select option_text, is_correct, row_number() over(order by random()) as rn
      from opts
    )
    insert into public.lesson_options (question_id, option_text, is_correct, option_order)
    select v_qid, option_text, is_correct, rn
    from shuffled;

    v_order := v_order + 1;
  end loop;

  -- =====================================
  -- TYPE 3: Fill in the blank (free text)
  -- =====================================
  for r in
    select lv.id, lv.term, lv.meaning,
           coalesce(lv.example_sentence, format('I use "%s" when talking about %s.', lv.term, lv.meaning)) as ex
    from public.lesson_vocabulary lv
    where lv.lesson_id = p_lesson_id
      and coalesce(trim(lv.term), '') <> ''
    order by random()
    limit p_words_per_type
  loop
    insert into public.lesson_questions (
      lesson_id, question_type, question_text, question_order,
      explanation, correct_answer, vocabulary_ids, difficulty_level, points
    ) values (
      p_lesson_id,
      'fill_blank',
      format(
        'Điền từ còn thiếu: %s',
        regexp_replace(r.ex, '(?i)' || regexp_replace(r.term, '([\\W])', '\\\\\1', 'g'), '____', 'g')
      ),
      v_order,
      format('Từ cần điền là "%s".', r.term),
      r.term,
      array[r.id],
      2,
      10
    ) returning id into v_qid;

    insert into public.lesson_answer_keys (question_id, answer_kind, correct_text, correct_text_alt, case_sensitive)
    values (v_qid, 'text', r.term, array[public.normalize_answer(r.term)], false);

    v_order := v_order + 1;
  end loop;

  -- =====================================
  -- TYPE 4: Unscramble word (free text)
  -- =====================================
  for r in
    select lv.id, lv.term, coalesce(lv.vietnamese_meaning, lv.meaning) as vi_meaning
    from public.lesson_vocabulary lv
    where lv.lesson_id = p_lesson_id
      and char_length(coalesce(lv.term, '')) >= 3
    order by random()
    limit p_words_per_type
  loop
    select string_agg(ch, '') into v_scrambled
    from (
      select substr(r.term, gs, 1) as ch
      from generate_series(1, char_length(r.term)) gs
      order by random()
    ) t;

    if v_scrambled = r.term then
      v_scrambled := reverse(r.term);
    end if;

    insert into public.lesson_questions (
      lesson_id, question_type, question_text, question_order,
      explanation, correct_answer, vietnamese_text, vocabulary_ids, difficulty_level, points
    ) values (
      p_lesson_id,
      'unscramble',
      format('Sắp xếp chữ cái thành từ đúng: %s', v_scrambled),
      v_order,
      format('Từ đúng là "%s" (nghĩa: %s).', r.term, r.vi_meaning),
      r.term,
      r.vi_meaning,
      array[r.id],
      2,
      10
    ) returning id into v_qid;

    insert into public.lesson_answer_keys (question_id, answer_kind, correct_text, correct_text_alt, case_sensitive)
    values (v_qid, 'text', r.term, array[public.normalize_answer(r.term)], false);

    v_order := v_order + 1;
  end loop;

  -- =====================================
  -- TYPE 5: True/False meaning
  -- =====================================
  for r in
    select lv.id, lv.term, coalesce(lv.vietnamese_meaning, lv.meaning) as vi_meaning
    from public.lesson_vocabulary lv
    where lv.lesson_id = p_lesson_id
      and coalesce(trim(lv.term), '') <> ''
      and coalesce(trim(coalesce(lv.vietnamese_meaning, lv.meaning)), '') <> ''
    order by random()
    limit p_words_per_type
  loop
    v_is_true := (random() >= 0.5);

    if v_is_true then
      v_false_meaning := r.vi_meaning;
    else
      select coalesce(lv2.vietnamese_meaning, lv2.meaning)
      into v_false_meaning
      from public.lesson_vocabulary lv2
      where lv2.id <> r.id
        and coalesce(trim(coalesce(lv2.vietnamese_meaning, lv2.meaning)), '') <> ''
      order by random()
      limit 1;
    end if;

    insert into public.lesson_questions (
      lesson_id, question_type, question_text, question_order,
      explanation, correct_answer, vietnamese_text, vocabulary_ids, difficulty_level, points
    ) values (
      p_lesson_id,
      'true_false',
      format('Đúng hay sai: "%s" nghĩa là "%s".', r.term, v_false_meaning),
      v_order,
      format('Nghĩa đúng của "%s" là "%s".', r.term, r.vi_meaning),
      case when v_is_true then 'true' else 'false' end,
      r.vi_meaning,
      array[r.id],
      2,
      10
    ) returning id into v_qid;

    insert into public.lesson_options (question_id, option_text, is_correct, option_order)
    values
      (v_qid, 'Đúng', v_is_true, 1),
      (v_qid, 'Sai', not v_is_true, 2);

    v_order := v_order + 1;
  end loop;

  -- =====================================
  -- TYPE 6: Matching (4 pairs / question)
  -- =====================================
  for m in
    with ranked as (
      select lv.id, lv.term, coalesce(lv.vietnamese_meaning, lv.meaning) as vi_meaning,
             row_number() over(order by random()) as rn
      from public.lesson_vocabulary lv
      where lv.lesson_id = p_lesson_id
        and coalesce(trim(lv.term), '') <> ''
        and coalesce(trim(coalesce(lv.vietnamese_meaning, lv.meaning)), '') <> ''
    ), grouped as (
      select ((rn - 1) / 4) as grp,
             array_agg(id order by rn) as ids,
             array_agg(term order by rn) as terms,
             array_agg(vi_meaning order by rn) as meanings
      from ranked
      group by ((rn - 1) / 4)
      having count(*) = 4
      limit greatest(1, p_words_per_type / 4)
    )
    select * from grouped
  loop
    insert into public.lesson_questions (
      lesson_id, question_type, question_text, question_order,
      explanation, vocabulary_ids, difficulty_level, points
    ) values (
      p_lesson_id,
      'matching',
      'Nối từ tiếng Anh với nghĩa tiếng Việt đúng.',
      v_order,
      'Mỗi từ chỉ khớp với một nghĩa chính xác.',
      m.ids,
      3,
      20
    ) returning id into v_qid;

    insert into public.lesson_options (question_id, option_text, is_correct, option_order, match_pair_id)
    values
      (v_qid, m.terms[1], true, 1, 'pair_1'),
      (v_qid, m.meanings[1], true, 2, 'pair_1'),
      (v_qid, m.terms[2], true, 3, 'pair_2'),
      (v_qid, m.meanings[2], true, 4, 'pair_2'),
      (v_qid, m.terms[3], true, 5, 'pair_3'),
      (v_qid, m.meanings[3], true, 6, 'pair_3'),
      (v_qid, m.terms[4], true, 7, 'pair_4'),
      (v_qid, m.meanings[4], true, 8, 'pair_4');

    v_order := v_order + 1;
  end loop;

  -- =====================================
  -- TYPE 7: Spelling from meaning (free text)
  -- =====================================
  for r in
    select lv.id, lv.term, coalesce(lv.vietnamese_meaning, lv.meaning) as vi_meaning
    from public.lesson_vocabulary lv
    where lv.lesson_id = p_lesson_id
      and coalesce(trim(lv.term), '') <> ''
      and coalesce(trim(coalesce(lv.vietnamese_meaning, lv.meaning)), '') <> ''
    order by random()
    limit p_words_per_type
  loop
    insert into public.lesson_questions (
      lesson_id, question_type, question_text, question_order,
      explanation, correct_answer, vietnamese_text, vocabulary_ids, difficulty_level, points
    ) values (
      p_lesson_id,
      'spelling',
      format('Viết đúng từ tiếng Anh cho nghĩa: "%s".', r.vi_meaning),
      v_order,
      format('Đáp án đúng là "%s".', r.term),
      r.term,
      r.vi_meaning,
      array[r.id],
      3,
      10
    ) returning id into v_qid;

    insert into public.lesson_answer_keys (question_id, answer_kind, correct_text, correct_text_alt, case_sensitive)
    values (v_qid, 'text', r.term, array[public.normalize_answer(r.term)], false);

    v_order := v_order + 1;
  end loop;

  raise notice 'Generated % questions for lesson %', v_order - 1, p_lesson_id;
end;
$$;

-- 4) Generate for all lessons
create or replace function public.generate_questions_for_all_lessons(
  p_words_per_type int default 8
)
returns void
language plpgsql
as $$
declare
  l record;
begin
  for l in select id from public.lessons loop
    perform public.generate_questions_for_lesson(l.id, p_words_per_type);
  end loop;
end;
$$;

-- 5) Suggested execution
-- Generate all lessons:
-- select public.generate_questions_for_all_lessons(8);
--
-- Generate one lesson only:
-- select public.generate_questions_for_lesson('YOUR_LESSON_UUID_HERE', 8);
