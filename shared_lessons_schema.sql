-- Create shared lessons table
create table if not exists public.shared_lessons (
  id uuid not null default gen_random_uuid (),
  original_lesson_id uuid,
  user_id uuid not null,
  title text not null,
  description text,
  flashcard_count int default 0,
  created_at timestamp without time zone null default now(),
  updated_at timestamp without time zone null default now(),
  constraint shared_lessons_pkey primary key (id),
  constraint shared_lessons_user_id_fkey foreign key (user_id) references auth.users (id) on update cascade on delete cascade
) tablespace pg_default;

create index if not exists idx_shared_lessons_user_id on public.shared_lessons using btree (user_id) tablespace pg_default;
create index if not exists idx_shared_lessons_created_at on public.shared_lessons using btree (created_at) tablespace pg_default;

-- Create shared flashcards table
create table if not exists public.shared_flashcards (
  id uuid not null default gen_random_uuid (),
  shared_lesson_id uuid not null,
  term text not null,
  meaning text not null,
  pronunciation text null default ''::text,
  word_class text null default 'noun'::text,
  example text null default ''::text,
  created_at timestamp without time zone null default now(),
  constraint shared_flashcards_pkey primary key (id),
  constraint shared_flashcards_lesson_id_fkey foreign key (shared_lesson_id) references shared_lessons (id) on update cascade on delete cascade,
  constraint shared_flashcards_lesson_id_term_key unique (shared_lesson_id, term)
) tablespace pg_default;

create index if not exists idx_shared_flashcards_lesson_id on public.shared_flashcards using btree (shared_lesson_id) tablespace pg_default;
create index if not exists idx_shared_flashcards_term on public.shared_flashcards using btree (term) tablespace pg_default;

-- Add column to track which users have saved each shared lesson
create table if not exists public.shared_lesson_saves (
  id uuid not null default gen_random_uuid (),
  shared_lesson_id uuid not null,
  user_id uuid not null,
  saved_as_lesson_id uuid,
  saved_at timestamp without time zone null default now(),
  constraint shared_lesson_saves_pkey primary key (id),
  constraint shared_lesson_saves_lesson_id_fkey foreign key (shared_lesson_id) references shared_lessons (id) on update cascade on delete cascade,
  constraint shared_lesson_saves_user_id_fkey foreign key (user_id) references auth.users (id) on update cascade on delete cascade,
  constraint shared_lesson_saves_lesson_id_user_id_key unique (shared_lesson_id, user_id)
) tablespace pg_default;

create index if not exists idx_shared_lesson_saves_user_id on public.shared_lesson_saves using btree (user_id) tablespace pg_default;
create index if not exists idx_shared_lesson_saves_lesson_id on public.shared_lesson_saves using btree (shared_lesson_id) tablespace pg_default;
