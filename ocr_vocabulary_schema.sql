-- Create OCR Vocabulary table with example field
create table if not exists public.ocr_vocabulary (
  id uuid not null default gen_random_uuid (),
  lesson_id uuid not null,
  term text not null,
  pronunciation text null default ''::text,
  word_class text null default 'noun'::text,
  meaning text not null,
  example text null default ''::text,
  vietnamese_term text null,
  vietnamese_meaning text null,
  vietnamese_example text null,
  created_at timestamp without time zone null default now(),
  updated_at timestamp without time zone null default now(),
  constraint ocr_vocabulary_pkey primary key (id),
  constraint ocr_vocabulary_lesson_id_term_key unique (lesson_id, term),
  constraint ocr_vocabulary_lesson_id_fkey foreign KEY (lesson_id) references ocr_lessons (id) on update CASCADE on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_ocr_vocabulary_lesson_id on public.ocr_vocabulary using btree (lesson_id) TABLESPACE pg_default;

create index IF not exists idx_ocr_vocabulary_term on public.ocr_vocabulary using btree (term) TABLESPACE pg_default;

-- Add example column to custom_lessons_vocabulary if it doesn't exist
ALTER TABLE IF EXISTS public.custom_lessons_vocabulary 
ADD COLUMN IF NOT EXISTS example TEXT NULL DEFAULT ''::text;

-- Add vietnamese_example column
ALTER TABLE IF EXISTS public.custom_lessons_vocabulary 
ADD COLUMN IF NOT EXISTS vietnamese_example TEXT NULL DEFAULT ''::text;
