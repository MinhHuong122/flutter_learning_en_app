-- Create table for custom lesson favorites (OCR lessons)
CREATE TABLE IF NOT EXISTS public.user_favorite_custom_lessons (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  ocr_lesson_id uuid NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT user_favorite_custom_lessons_pkey PRIMARY KEY (id),
  CONSTRAINT user_favorite_custom_lessons_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT user_favorite_custom_lessons_ocr_lesson_id_fkey FOREIGN KEY (ocr_lesson_id) REFERENCES public.ocr_lessons(id),
  CONSTRAINT user_favorite_custom_lessons_unique UNIQUE (user_id, ocr_lesson_id)
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_user_favorite_custom_lessons_user_id 
  ON public.user_favorite_custom_lessons(user_id);

CREATE INDEX IF NOT EXISTS idx_user_favorite_custom_lessons_ocr_lesson_id 
  ON public.user_favorite_custom_lessons(ocr_lesson_id);

-- Enable RLS
ALTER TABLE public.user_favorite_custom_lessons ENABLE ROW LEVEL SECURITY;

-- Create RLS policy for users to only see their own favorites
CREATE POLICY "Users can view their own custom favorite lessons" ON public.user_favorite_custom_lessons
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own custom favorite lessons" ON public.user_favorite_custom_lessons
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own custom favorite lessons" ON public.user_favorite_custom_lessons
  FOR DELETE
  USING (auth.uid() = user_id);
