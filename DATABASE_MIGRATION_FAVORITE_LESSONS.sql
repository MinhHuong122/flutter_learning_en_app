-- Supabase migration for lesson favorites sync
-- Run in Supabase SQL Editor before using lesson favorite sync.

CREATE TABLE IF NOT EXISTS user_favorite_lessons (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, lesson_id)
);

ALTER TABLE user_favorite_lessons ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own favorite lessons" ON user_favorite_lessons;
CREATE POLICY "Users can read own favorite lessons"
  ON user_favorite_lessons FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own favorite lessons" ON user_favorite_lessons;
CREATE POLICY "Users can insert own favorite lessons"
  ON user_favorite_lessons FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own favorite lessons" ON user_favorite_lessons;
CREATE POLICY "Users can delete own favorite lessons"
  ON user_favorite_lessons FOR DELETE
  USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_user_favorite_lessons_user_id
  ON user_favorite_lessons(user_id);

CREATE INDEX IF NOT EXISTS idx_user_favorite_lessons_lesson_id
  ON user_favorite_lessons(lesson_id);

-- Dictionary saved words table for favorite words sync
CREATE TABLE IF NOT EXISTS user_saved_words (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  term TEXT NOT NULL,
  language VARCHAR(10) NOT NULL,
  is_favorite BOOLEAN NOT NULL DEFAULT TRUE,
  mastery_level INT NOT NULL DEFAULT 1,
  saved_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, term, language),
  CHECK (language IN ('en', 'vi'))
);

ALTER TABLE user_saved_words ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own saved words" ON user_saved_words;
CREATE POLICY "Users can read own saved words"
  ON user_saved_words FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own saved words" ON user_saved_words;
CREATE POLICY "Users can insert own saved words"
  ON user_saved_words FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own saved words" ON user_saved_words;
CREATE POLICY "Users can update own saved words"
  ON user_saved_words FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own saved words" ON user_saved_words;
CREATE POLICY "Users can delete own saved words"
  ON user_saved_words FOR DELETE
  USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_user_saved_words_user_id
  ON user_saved_words(user_id);

CREATE INDEX IF NOT EXISTS idx_user_saved_words_term_lang
  ON user_saved_words(user_id, term, language);
