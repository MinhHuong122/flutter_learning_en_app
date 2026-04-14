-- Create word_puzzle_questions table for word crossword puzzle game
-- Run this in Supabase SQL Editor

CREATE TABLE IF NOT EXISTS word_puzzle_questions (
  id BIGSERIAL PRIMARY KEY,
  level_number INT NOT NULL,
  word VARCHAR(255) NOT NULL,
  question VARCHAR(500), -- Vietnamese clue/question
  hint VARCHAR(255),
  start_row INT NOT NULL,
  start_col INT NOT NULL,
  direction VARCHAR(10) NOT NULL, -- 'across' or 'down'
  question_number INT NOT NULL,
  image_url VARCHAR(500),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT check_direction CHECK (direction IN ('across', 'down')),
  CONSTRAINT check_level CHECK (level_number >= 1 AND level_number <= 100)
);

-- Create index for faster queries
CREATE INDEX idx_word_puzzle_level ON word_puzzle_questions(level_number);

-- Insert sample data for level 1 - Food theme
INSERT INTO word_puzzle_questions (level_number, word, question, hint, start_row, start_col, direction, question_number)
VALUES
  (1, 'PORK', 'Thịt từ lợn', 'Pork meat - meat from a pig', 0, 5, 'across', 1),
  (1, 'BEEF', 'Thịt từ bò', 'Beef - meat from a cow', 1, 1, 'across', 2),
  (1, 'WATER', 'Nước uống', 'Water - essential liquid for life', 2, 0, 'across', 3),
  (1, 'NOODLES', 'Mì ăn liền', 'Noodles - popular Asian food', 2, 4, 'down', 4),
  (1, 'LEMONADE', 'Nước chanh', 'Lemonade - sweet lemon drink', 4, 0, 'across', 5),
  (1, 'CHICKEN', 'Thịt gà', 'Chicken - meat from poultry', 6, 2, 'across', 6);

-- Insert sample data for level 2 - Fruits theme
INSERT INTO word_puzzle_questions (level_number, word, question, hint, start_row, start_col, direction, question_number)
VALUES
  (2, 'APPLE', 'Quả táo', 'Apple - red or green fruit', 0, 2, 'across', 1),
  (2, 'ORANGE', 'Quả cam', 'Orange - citrus fruit with orange color', 1, 0, 'across', 2),
  (2, 'BANANA', 'Quả chuối', 'Banana - yellow tropical fruit', 2, 5, 'across', 3),
  (2, 'GRAPE', 'Quả nho', 'Grape - small round fruit', 2, 0, 'down', 4),
  (2, 'MANGO', 'Quả xoài', 'Mango - king of fruits', 4, 3, 'across', 5);

-- Insert sample data for level 3 - Clothing theme
INSERT INTO word_puzzle_questions (level_number, word, question, hint, start_row, start_col, direction, question_number)
VALUES
  (3, 'SHIRT', 'Áo sơ mi', 'Shirt - upper body clothing', 0, 2, 'across', 1),
  (3, 'PANTS', 'Quần dài', 'Pants - lower body clothing', 1, 0, 'across', 2),
  (3, 'SHOES', 'Giày', 'Shoes - footwear', 2, 3, 'across', 3),
  (3, 'COAT', 'Áo khoác', 'Coat - outer wearing garment', 2, 0, 'down', 4),
  (3, 'HAT', 'Mũ', 'Hat - head covering', 4, 5, 'across', 5);

-- Insert sample data for level 4 - Colors theme
INSERT INTO word_puzzle_questions (level_number, word, question, hint, start_row, start_col, direction, question_number)
VALUES
  (4, 'RED', 'Màu đỏ', 'Red - color of blood', 0, 3, 'across', 1),
  (4, 'BLUE', 'Màu xanh lam', 'Blue - color of sky', 1, 0, 'across', 2),
  (4, 'GREEN', 'Màu xanh lá', 'Green - color of grass', 2, 2, 'across', 3),
  (4, 'YELLOW', 'Màu vàng', 'Yellow - color of sun', 2, 0, 'down', 4),
  (4, 'BLACK', 'Màu đen', 'Black - darkest color', 4, 4, 'across', 5);

-- Insert sample data for level 5 - Animals theme
INSERT INTO word_puzzle_questions (level_number, word, question, hint, start_row, start_col, direction, question_number)
VALUES
  (5, 'CAT', 'Con mèo', 'Cat - domestic pet animal', 0, 3, 'across', 1),
  (5, 'DOG', 'Con chó', 'Dog - mans best friend', 1, 0, 'across', 2),
  (5, 'BIRD', 'Con chim', 'Bird - animal that flies', 2, 2, 'across', 3),
  (5, 'FISH', 'Con cá', 'Fish - aquatic animal', 2, 0, 'down', 4),
  (5, 'HORSE', 'Con ngựa', 'Horse - large farm animal', 4, 4, 'across', 5);

-- Insert sample data for level 6 - School theme
INSERT INTO word_puzzle_questions (level_number, word, question, hint, start_row, start_col, direction, question_number)
VALUES
  (6, 'STUDENT', 'Học sinh', 'Student - person who studies', 0, 1, 'across', 1),
  (6, 'TEACHER', 'Giáo viên', 'Teacher - person who teaches', 1, 0, 'across', 2),
  (6, 'BOOK', 'Cuốn sách', 'Book - object for reading', 2, 3, 'across', 3),
  (6, 'SCHOOL', 'Trường học', 'School - place of education', 2, 0, 'down', 4),
  (6, 'PENCIL', 'Cái bút chì', 'Pencil - writing tool', 4, 3, 'across', 5);

-- Insert sample data for level 7 - Days of week theme
INSERT INTO word_puzzle_questions (level_number, word, question, hint, start_row, start_col, direction, question_number)
VALUES
  (7, 'MONDAY', 'Thứ hai', 'Monday - first day of work week', 0, 0, 'across', 1),
  (7, 'TUESDAY', 'Thứ ba', 'Tuesday - second day of week', 1, 2, 'across', 2),
  (7, 'WEDNESDAY', 'Thứ tư', 'Wednesday - middle of week', 2, 0, 'across', 3),
  (7, 'FRIDAY', 'Thứ sáu', 'Friday - day before weekend', 3, 3, 'across', 4),
  (7, 'SUNDAY', 'Chủ nhật', 'Sunday - last day of week', 4, 1, 'across', 5);

-- Insert sample data for level 8 - Time of day theme
INSERT INTO word_puzzle_questions (level_number, word, question, hint, start_row, start_col, direction, question_number)
VALUES
  (8, 'MORNING', 'Buổi sáng', 'Morning - early part of day', 0, 1, 'across', 1),
  (8, 'AFTERNOON', 'Buổi chiều', 'Afternoon - middle part of day', 1, 0, 'across', 2),
  (8, 'EVENING', 'Buổi tối', 'Evening - end of day', 2, 2, 'across', 3),
  (8, 'NIGHT', 'Ban đêm', 'Night - dark part of day', 2, 0, 'down', 4),
  (8, 'SLEEP', 'Ngủ', 'Sleep - rest at night', 4, 4, 'across', 5);

-- Insert sample data for level 9 - Family theme
INSERT INTO word_puzzle_questions (level_number, word, question, hint, start_row, start_col, direction, question_number)
VALUES
  (9, 'FATHER', 'Cha', 'Father - male parent', 0, 1, 'across', 1),
  (9, 'MOTHER', 'Mẹ', 'Mother - female parent', 1, 0, 'across', 2),
  (9, 'SISTER', 'Chị em gái', 'Sister - female sibling', 2, 2, 'across', 3),
  (9, 'BROTHER', 'Anh em trai', 'Brother - male sibling', 2, 0, 'down', 4),
  (9, 'FAMILY', 'Gia đình', 'Family - parents and siblings', 4, 3, 'across', 5);

-- Insert sample data for level 10 - Meals theme
INSERT INTO word_puzzle_questions (level_number, word, question, hint, start_row, start_col, direction, question_number)
VALUES
  (10, 'BREAKFAST', 'Bữa sáng', 'Breakfast - first meal of day', 0, 0, 'across', 1),
  (10, 'LUNCH', 'Bữa trưa', 'Lunch - midday meal', 1, 3, 'across', 2),
  (10, 'DINNER', 'Bữa tối', 'Dinner - evening meal', 2, 1, 'across', 3),
  (10, 'SNACK', 'Bữa ăn nhẹ', 'Snack - light food between meals', 3, 0, 'across', 4),
  (10, 'DRINK', 'Đồ uống', 'Drink - liquid beverage', 4, 2, 'across', 5);

-- Enable RLS if needed (optional)
-- ALTER TABLE word_puzzle_questions ENABLE ROW LEVEL SECURITY;
