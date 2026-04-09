-- Check the schema of lesson_options table
-- Run this query in Supabase SQL Editor to see the actual columns

SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'lesson_options'
ORDER BY ordinal_position;

-- If lesson_options table exists, this will show all columns
-- Common structures might be:
-- 1. id, created_at, question_id, option_text, is_correct, display_order
-- 2. id, created_at, lesson_id, option_text, is_correct, display_order
-- 3. Other variations

-- Run this to get more info:
\d lesson_options
