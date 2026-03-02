-- =====================================================
-- DATABASE MIGRATION - Add Quiz Features
-- Run this if you already have an existing database
-- =====================================================

-- Add new fields to lesson_questions table
ALTER TABLE lesson_questions 
ADD COLUMN IF NOT EXISTS question_type VARCHAR(50) DEFAULT 'multiple_choice',
ADD COLUMN IF NOT EXISTS image_url VARCHAR(255),
ADD COLUMN IF NOT EXISTS correct_answer TEXT,
ADD COLUMN IF NOT EXISTS vietnamese_text TEXT,
ADD COLUMN IF NOT EXISTS conversation_context TEXT,
ADD COLUMN IF NOT EXISTS points INT DEFAULT 10;

-- Add new fields to lesson_options table
ALTER TABLE lesson_options
ADD COLUMN IF NOT EXISTS option_image_url VARCHAR(255),
ADD COLUMN IF NOT EXISTS match_pair_id VARCHAR(50);

-- Update existing questions to have question_type if null
UPDATE lesson_questions 
SET question_type = 'multiple_choice' 
WHERE question_type IS NULL;

-- Create index for question_type for faster filtering
CREATE INDEX IF NOT EXISTS idx_question_type ON lesson_questions(question_type);
CREATE INDEX IF NOT EXISTS idx_match_pair ON lesson_options(match_pair_id);

-- =====================================================
-- Sample diverse quiz questions for testing
-- =====================================================

-- Example: Fill in the blank question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, correct_answer, question_order, explanation) 
VALUES (
  (SELECT id FROM lessons WHERE title = 'Basic Colors' LIMIT 1),
  'fill_blank',
  'The color of the ocean is ______.',
  'blue',
  10,
  'Oceans appear blue due to water absorbing other colors of light.'
);

-- Example: Translation question  
INSERT INTO lesson_questions (lesson_id, question_type, question_text, vietnamese_text, correct_answer, question_order, explanation)
VALUES (
  (SELECT id FROM lessons WHERE title = 'Hot Drinks' LIMIT 1),
  'translation',
  'Translate to English: Cà phê',
  'Cà phê',
  'coffee',
  20,
  'Cà phê is the Vietnamese word for coffee.'
);

-- Example: Conversation question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, conversation_context, question_order, explanation)
VALUES (
  (SELECT id FROM lessons WHERE title = 'Hot Drinks' LIMIT 1),
  'conversation',
  'Waiter: "What would you like to drink?" You: "_______"',
  'At a restaurant',
  21,
  'Common restaurant conversation for ordering drinks.'
);

-- Add options for conversation question
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order)
SELECT 
  id,
  'I would like a coffee, please',
  true,
  1
FROM lesson_questions 
WHERE question_text LIKE 'Waiter: "What would you like to drink?"%%'
LIMIT 1;

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order)
SELECT 
  id,
  'I am fine, thank you',
  false,
  2
FROM lesson_questions 
WHERE question_text LIKE 'Waiter: "What would you like to drink?"%%'
LIMIT 1;

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order)
SELECT 
  id,
  'The weather is nice',
  false,
  3
FROM lesson_questions 
WHERE question_text LIKE 'Waiter: "What would you like to drink?"%%'
LIMIT 1;

-- Example: Matching question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation)
VALUES (
  (SELECT id FROM lessons WHERE title = 'Basic Colors' LIMIT 1),
  'matching',
  'Match the English color names with their Vietnamese translations',
  11,
  'Practice color vocabulary in both languages.'
);

-- Add matching pairs
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id)
SELECT 
  id,
  'Yellow',
  true,
  1,
  'color_yellow'
FROM lesson_questions 
WHERE question_text LIKE 'Match the English color names%%' AND question_order = 11
LIMIT 1;

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id)
SELECT 
  id,
  'Màu vàng',
  true,
  2,
  'color_yellow'
FROM lesson_questions 
WHERE question_text LIKE 'Match the English color names%%' AND question_order = 11
LIMIT 1;

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id)
SELECT 
  id,
  'Purple',
  true,
  3,
  'color_purple'
FROM lesson_questions 
WHERE question_text LIKE 'Match the English color names%%' AND question_order = 11
LIMIT 1;

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id)
SELECT 
  id,
  'Màu tím',
  true,
  4,
  'color_purple'
FROM lesson_questions 
WHERE question_text LIKE 'Match the English color names%%' AND question_order = 11
LIMIT 1;

COMMIT;
