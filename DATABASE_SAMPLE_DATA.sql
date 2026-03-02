-- =====================================================
-- HIERARCHICAL LESSON STRUCTURE
-- Main Lessons (Topics) with Sub-lessons (Modules)
-- =====================================================

-- ============== LESSON 1: BẢNG CHỮ CÁI ==============
-- Main lesson: Bảng chữ cái
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Alphabet - Bảng chữ cái', 'Learn the English alphabet from A to Z', 'beginner', 'multiple_choice', 25, 0, NULL, 1);

-- Sub-lessons for Bảng chữ cái
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Basic Alphabet', 'Recognize letters A-Z', 'beginner', 'multiple_choice', 8, 5, 
  (SELECT id FROM lessons WHERE title = 'Alphabet - Bảng chữ cái' AND parent_lesson_id IS NULL), 1),
('Vowels', 'Learn 5 vowels: A, E, I, O, U', 'beginner', 'listening', 7, 5,
  (SELECT id FROM lessons WHERE title = 'Alphabet - Bảng chữ cái' AND parent_lesson_id IS NULL), 2),
('Consonants', 'Practice consonant letters', 'beginner', 'matching', 10, 8,
  (SELECT id FROM lessons WHERE title = 'Alphabet - Bảng chữ cái' AND parent_lesson_id IS NULL), 3);

-- ============== LESSON 2: MÀU SẮC ==============
-- Main lesson: Màu sắc
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Colors - Màu sắc', 'Master basic and advanced colors in English', 'beginner', 'multiple_choice', 20, 0, NULL, 2);

-- Sub-lessons for Màu sắc
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Basic Colors', 'Learn primary colors: red, blue, yellow', 'beginner', 'multiple_choice', 8, 6,
  (SELECT id FROM lessons WHERE title = 'Colors - Màu sắc' AND parent_lesson_id IS NULL), 1),
('Advanced Colors', 'Learn complex color names', 'intermediate', 'fill_blank', 12, 8,
  (SELECT id FROM lessons WHERE title = 'Colors - Màu sắc' AND parent_lesson_id IS NULL), 2);

-- ============== LESSON 3: SỐ ĐẾM ==============
-- Main lesson: Số đếm
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Numbers - Số đếm', 'Count from 1 to 100 in English', 'beginner', 'multiple_choice', 30, 0, NULL, 3);

-- Sub-lessons for Số đếm
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Numbers 1-10', 'Basic counting from 1 to 10', 'beginner', 'multiple_choice', 8, 5,
  (SELECT id FROM lessons WHERE title = 'Numbers - Số đếm' AND parent_lesson_id IS NULL), 1),
('Numbers 11-20', 'Count from 11 to 20', 'beginner', 'listening', 10, 5,
  (SELECT id FROM lessons WHERE title = 'Numbers - Số đếm' AND parent_lesson_id IS NULL), 2),
('Numbers 20-100', 'Advanced counting', 'intermediate', 'fill_blank', 12, 8,
  (SELECT id FROM lessons WHERE title = 'Numbers - Số đếm' AND parent_lesson_id IS NULL), 3);

-- ============== LESSON 4: ĐỒ UỐNG ==============
-- Main lesson: Đồ uống
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Drinks - Đồ uống', 'Learn names of common drinks', 'beginner', 'multiple_choice', 18, 0, NULL, 4);

-- Sub-lessons for Đồ uống
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Hot Drinks', 'Coffee, tea, hot chocolate', 'beginner', 'multiple_choice', 6, 4,
  (SELECT id FROM lessons WHERE title = 'Drinks - Đồ uống' AND parent_lesson_id IS NULL), 1),
('Cold Drinks', 'Juice, soda, water', 'beginner', 'matching', 6, 5,
  (SELECT id FROM lessons WHERE title = 'Drinks - Đồ uống' AND parent_lesson_id IS NULL), 2),
('Ordering Drinks', 'Practice ordering in a cafe', 'intermediate', 'conversation', 6, 3,
  (SELECT id FROM lessons WHERE title = 'Drinks - Đồ uống' AND parent_lesson_id IS NULL), 3);

-- ============== LESSON 5: ĐỒ ĂN ==============
-- Main lesson: Đồ ăn
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Food - Đồ ăn', 'Vocabulary for different types of food', 'beginner', 'multiple_choice', 25, 0, NULL, 5);

-- Sub-lessons for Đồ ăn
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Fruits', 'Apple, banana, orange, etc.', 'beginner', 'multiple_choice', 8, 6,
  (SELECT id FROM lessons WHERE title = 'Food - Đồ ăn' AND parent_lesson_id IS NULL), 1),
('Vegetables', 'Carrot, tomato, potato, etc.', 'beginner', 'fill_blank', 8, 6,
  (SELECT id FROM lessons WHERE title = 'Food - Đồ ăn' AND parent_lesson_id IS NULL), 2),
('Meals', 'Breakfast, lunch, dinner', 'intermediate', 'conversation', 9, 4,
  (SELECT id FROM lessons WHERE title = 'Food - Đồ ăn' AND parent_lesson_id IS NULL), 3);

-- ============== LESSON 6: ĐỘNG VẬT ==============
-- Main lesson: Động vật
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Animals - Động vật', 'Learn about different animals', 'beginner', 'multiple_choice', 22, 0, NULL, 6);

-- Sub-lessons for Động vật
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Pets', 'Dog, cat, fish, bird', 'beginner', 'multiple_choice', 7, 5,
  (SELECT id FROM lessons WHERE title = 'Animals - Động vật' AND parent_lesson_id IS NULL), 1),
('Farm Animals', 'Cow, pig, chicken, horse', 'beginner', 'matching', 8, 6,
  (SELECT id FROM lessons WHERE title = 'Animals - Động vật' AND parent_lesson_id IS NULL), 2),
('Wild Animals', 'Lion, tiger, elephant, monkey', 'intermediate', 'listening', 7, 5,
  (SELECT id FROM lessons WHERE title = 'Animals - Động vật' AND parent_lesson_id IS NULL), 3);

-- =====================================================
-- SAMPLE QUESTIONS FOR SUB-LESSONS
-- =====================================================

-- Questions for "Basic Alphabet"
INSERT INTO lesson_questions (lesson_id, question_text, question_order, explanation) VALUES
((SELECT id FROM lessons WHERE title = 'Basic Alphabet'), 'What is the first letter of the alphabet?', 1, 'A is the first letter.'),
((SELECT id FROM lessons WHERE title = 'Basic Alphabet'), 'What comes after B?', 2, 'C comes after B in the alphabet.'),
((SELECT id FROM lessons WHERE title = 'Basic Alphabet'), 'What is the last letter?', 3, 'Z is the last letter of the alphabet.');

-- Options for "Basic Alphabet" questions
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Alphabet') AND question_order = 1), 'A', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Alphabet') AND question_order = 1), 'B', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Alphabet') AND question_order = 1), 'Z', false, 3),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Alphabet') AND question_order = 2), 'A', false, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Alphabet') AND question_order = 2), 'C', true, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Alphabet') AND question_order = 2), 'D', false, 3),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Alphabet') AND question_order = 3), 'Y', false, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Alphabet') AND question_order = 3), 'X', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Alphabet') AND question_order = 3), 'Z', true, 3);

-- Questions for "Basic Colors"
INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation) VALUES
((SELECT id FROM lessons WHERE title = 'Basic Colors'), 'multiple_choice', 'What color is the sky?', 1, 'The sky is typically blue.'),
((SELECT id FROM lessons WHERE title = 'Basic Colors'), 'fill_blank', 'Grass is ______.', 2, 'Grass is green in color.'),
((SELECT id FROM lessons WHERE title = 'Basic Colors'), 'matching', 'Match the colors with their Vietnamese names', 3, 'Practice matching English-Vietnamese color pairs.');

-- Options for "Basic Colors" - Multiple Choice
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Colors') AND question_order = 1), 'Blue', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Colors') AND question_order = 1), 'Green', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Colors') AND question_order = 1), 'Red', false, 3);

-- Fill blank answer
UPDATE lesson_questions SET correct_answer = 'green' 
WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Colors') AND question_order = 2;

-- Options for "Basic Colors" - Matching
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Colors') AND question_order = 3), 'Red', true, 1, 'pair1'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Colors') AND question_order = 3), 'Màu đỏ', true, 2, 'pair1'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Colors') AND question_order = 3), 'Blue', true, 3, 'pair2'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Colors') AND question_order = 3), 'Màu xanh dương', true, 4, 'pair2'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Colors') AND question_order = 3), 'Green', true, 5, 'pair3'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Colors') AND question_order = 3), 'Màu xanh lá', true, 6, 'pair3');

-- Questions for "Hot Drinks"
INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation, conversation_context) VALUES
((SELECT id FROM lessons WHERE title = 'Hot Drinks'), 'conversation', 'Customer: "I''d like a ______, please."', 1, 'Common coffee shop order.', 'At a coffee shop'),
((SELECT id FROM lessons WHERE title = 'Hot Drinks'), 'translation', 'Translate to English: "Tôi muốn một tách trà"', 2, 'Simple drink order translation.', null),
((SELECT id FROM lessons WHERE title = 'Hot Drinks'), 'listening', 'Listen and choose the correct drink', 3, 'Practice listening to drink names.', null);

-- Options for "Hot Drinks" - Conversation
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Hot Drinks') AND question_order = 1), 'coffee', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Hot Drinks') AND question_order = 1), 'book', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Hot Drinks') AND question_order = 1), 'chair', false, 3);

-- Translation answer
UPDATE lesson_questions SET correct_answer = 'I want a cup of tea', vietnamese_text = 'Tôi muốn một tách trà'
WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Hot Drinks') AND question_order = 2;

-- Options for "Hot Drinks" - Listening
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Hot Drinks') AND question_order = 3), 'Hot Chocolate', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Hot Drinks') AND question_order = 3), 'Lemonade', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Hot Drinks') AND question_order = 3), 'Orange Juice', false, 3);
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Hot Drinks') AND question_order = 3), 'Hot Chocolate', true, 3);
