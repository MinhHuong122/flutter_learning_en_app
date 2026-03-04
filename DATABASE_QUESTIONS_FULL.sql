-- =====================================================
-- FULL QUESTION DATASET FOR ALL LESSONS
-- Comprehensive questions utilizing dictionary vocabulary
-- =====================================================

-- =====================================================
-- CLEANUP EXISTING DATA (if any)
-- Remove existing questions and options to avoid conflicts
-- =====================================================
BEGIN;

-- Delete existing options first (foreign key constraint)
DELETE FROM lesson_options WHERE question_id IN (
  SELECT id FROM lesson_questions WHERE lesson_id IN (
    SELECT id FROM lessons WHERE title IN (
      'Basic Alphabet', 'Basic Colors', 'Numbers 1-20', 'Hot Drinks', 'Fruits',
      'Pets', 'Immediate Family', 'Head & Face', 'Rooms in a House', 'Devices',
      'Business Meetings', 'Natural Sciences'
    )
  )
);

-- Delete existing questions
DELETE FROM lesson_questions WHERE lesson_id IN (
  SELECT id FROM lessons WHERE title IN (
    'Basic Alphabet', 'Basic Colors', 'Numbers 1-20', 'Hot Drinks', 'Fruits',
    'Pets', 'Immediate Family', 'Head & Face', 'Rooms in a House', 'Devices',
    'Business Meetings', 'Natural Sciences'
  )
);

-- =====================================================
-- BEGINNER LEVEL QUESTIONS
-- =====================================================

-- ============== ALPHABET QUESTIONS ==============
-- Basic Alphabet
INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation) VALUES
((SELECT id FROM lessons WHERE title = 'Basic Alphabet'), 'multiple_choice', 'What is the first letter of the alphabet?', 1, 'A is the first letter.'),
((SELECT id FROM lessons WHERE title = 'Basic Alphabet'), 'multiple_choice', 'What letter comes after B?', 2, 'C comes after B.'),
((SELECT id FROM lessons WHERE title = 'Basic Alphabet'), 'multiple_choice', 'What is the last letter of the alphabet?', 3, 'Z is the 26th and last letter.'),
((SELECT id FROM lessons WHERE title = 'Basic Alphabet'), 'fill_blank', 'The letter between M and O is ______.', 4, 'N comes between M and O.'),
((SELECT id FROM lessons WHERE title = 'Basic Alphabet'), 'matching', 'Match uppercase with lowercase letters', 5, 'Match capital letters with their lowercase forms.'),
((SELECT id FROM lessons WHERE title = 'Basic Alphabet'), 'listening', 'Listen and choose the correct letter', 6, 'Practice listening to letter pronunciation.');

-- Options for Basic Alphabet
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Alphabet') AND question_order = 1), 'A', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Alphabet') AND question_order = 1), 'B', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Alphabet') AND question_order = 1), 'Z', false, 3),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Alphabet') AND question_order = 2), 'A', false, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Alphabet') AND question_order = 2), 'C', true, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Alphabet') AND question_order = 2), 'D', false, 3),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Alphabet') AND question_order = 3), 'X', false, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Alphabet') AND question_order = 3), 'Y', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Alphabet') AND question_order = 3), 'Z', true, 3);

UPDATE lesson_questions SET correct_answer = 'N' WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Alphabet') AND question_order = 4;

-- Matching for Basic Alphabet
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Alphabet') AND question_order = 5), 'A', true, 1, 'letter1'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Alphabet') AND question_order = 5), 'a', true, 2, 'letter1'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Alphabet') AND question_order = 5), 'B', true, 3, 'letter2'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Alphabet') AND question_order = 5), 'b', true, 4, 'letter2'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Alphabet') AND question_order = 5), 'C', true, 5, 'letter3'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Alphabet') AND question_order = 5), 'c', true, 6, 'letter3');

-- ============== COLOR QUESTIONS ==============
-- Basic Colors
INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation) VALUES
((SELECT id FROM lessons WHERE title = 'Basic Colors'), 'multiple_choice', 'What color is the sky on a clear day?', 1, 'The sky appears blue.'),
((SELECT id FROM lessons WHERE title = 'Basic Colors'), 'multiple_choice', 'What color is snow?', 2, 'Snow is white.'),
((SELECT id FROM lessons WHERE title = 'Basic Colors'), 'fill_blank', 'Grass is ______.', 3, 'Grass is typically green.'),
((SELECT id FROM lessons WHERE title = 'Basic Colors'), 'matching', 'Match colors with Vietnamese translations', 5, 'Learn color vocabulary in both languages.');

INSERT INTO lesson_questions (lesson_id, question_type, question_text, vietnamese_text, correct_answer, question_order, explanation) VALUES
((SELECT id FROM lessons WHERE title = 'Basic Colors'), 'translation', 'Translate: Màu đỏ', 'Màu đỏ', 'red', 4, 'Red is a primary color.');

INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation, conversation_context) VALUES
((SELECT id FROM lessons WHERE title = 'Basic Colors'), 'conversation', 'A: "What color do you like?" B: "_____"', 6, 'Common conversation about preferences.', 'Talking about favorite colors');

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Colors') AND question_order = 1), 'Blue', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Colors') AND question_order = 1), 'Green', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Colors') AND question_order = 1), 'Red', false, 3),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Colors') AND question_order = 2), 'White', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Colors') AND question_order = 2), 'Black', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Colors') AND question_order = 2), 'Yellow', false, 3),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Colors') AND question_order = 6), 'I like blue', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Colors') AND question_order = 6), 'I am tired', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Colors') AND question_order = 6), 'See you later', false, 3);

UPDATE lesson_questions SET correct_answer = 'green'
WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Colors') AND question_order = 3;

-- Matching for Basic Colors
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Colors') AND question_order = 5), 'Red', true, 1, 'color1'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Colors') AND question_order = 5), 'Màu đỏ', true, 2, 'color1'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Colors') AND question_order = 5), 'Blue', true, 3, 'color2'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Colors') AND question_order = 5), 'Màu xanh dương', true, 4, 'color2'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Colors') AND question_order = 5), 'Yellow', true, 5, 'color3'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Colors') AND question_order = 5), 'Màu vàng', true, 6, 'color3');

-- ============== NUMBERS QUESTIONS ==============
-- Numbers 1-20
INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation) VALUES
((SELECT id FROM lessons WHERE title = 'Numbers 1-20'), 'multiple_choice', 'What number comes after five?', 1, 'Six comes after five.'),
((SELECT id FROM lessons WHERE title = 'Numbers 1-20'), 'multiple_choice', 'What is 10 + 5?', 2, 'Ten plus five equals fifteen.'),
((SELECT id FROM lessons WHERE title = 'Numbers 1-20'), 'fill_blank', 'The number between 12 and 14 is ______.', 3, 'Thirteen is between twelve and fourteen.'),
((SELECT id FROM lessons WHERE title = 'Numbers 1-20'), 'matching', 'Match numbers with words', 5, 'Connect numerical digits with written words.'),
((SELECT id FROM lessons WHERE title = 'Numbers 1-20'), 'listening', 'Listen and choose the number you hear', 6, 'Practice number pronunciation.');

INSERT INTO lesson_questions (lesson_id, question_type, question_text, vietnamese_text, correct_answer, question_order, explanation) VALUES
((SELECT id FROM lessons WHERE title = 'Numbers 1-20'), 'translation', 'Translate: Mười', 'Mười', 'ten', 4, 'Ten is the first two-digit number.');

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Numbers 1-20') AND question_order = 1), 'Six', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Numbers 1-20') AND question_order = 1), 'Four', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Numbers 1-20') AND question_order = 1), 'Seven', false, 3),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Numbers 1-20') AND question_order = 2), 'Fifteen', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Numbers 1-20') AND question_order = 2), 'Five', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Numbers 1-20') AND question_order = 2), 'Fifty', false, 3);

UPDATE lesson_questions SET correct_answer = 'thirteen' WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Numbers 1-20') AND question_order = 3;

-- Matching for Numbers
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Numbers 1-20') AND question_order = 5), '1', true, 1, 'num1'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Numbers 1-20') AND question_order = 5), 'one', true, 2, 'num1'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Numbers 1-20') AND question_order = 5), '5', true, 3, 'num2'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Numbers 1-20') AND question_order = 5), 'five', true, 4, 'num2'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Numbers 1-20') AND question_order = 5), '10', true, 5, 'num3'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Numbers 1-20') AND question_order = 5), 'ten', true, 6, 'num3');

-- ============== DRINKS QUESTIONS ==============
-- Hot Drinks
INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation) VALUES
((SELECT id FROM lessons WHERE title = 'Hot Drinks'), 'multiple_choice', 'What is a popular hot drink made from beans?', 1, 'Coffee is made from coffee beans.'),
((SELECT id FROM lessons WHERE title = 'Hot Drinks'), 'multiple_choice', 'What hot drink is made from leaves?', 2, 'Tea is made from tea leaves.'),
((SELECT id FROM lessons WHERE title = 'Hot Drinks'), 'fill_blank', 'I drink ______ every morning for energy.', 5, 'Many people drink coffee in the morning.');

INSERT INTO lesson_questions (lesson_id, question_type, question_text, vietnamese_text, correct_answer, question_order, explanation) VALUES
((SELECT id FROM lessons WHERE title = 'Hot Drinks'), 'translation', 'Translate: Cà phê', 'Cà phê', 'coffee', 3, 'Coffee is a popular morning drink.');

INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation, conversation_context) VALUES
((SELECT id FROM lessons WHERE title = 'Hot Drinks'), 'conversation', 'Waiter: "What would you like to drink?" You: "_____"', 4, 'Ordering at a café.', 'At a coffee shop');

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Hot Drinks') AND question_order = 1), 'Coffee', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Hot Drinks') AND question_order = 1), 'Water', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Hot Drinks') AND question_order = 1), 'Juice', false, 3),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Hot Drinks') AND question_order = 2), 'Tea', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Hot Drinks') AND question_order = 2), 'Soda', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Hot Drinks') AND question_order = 2), 'Milk', false, 3),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Hot Drinks') AND question_order = 4), 'I would like a coffee, please', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Hot Drinks') AND question_order = 4), 'I am a student', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Hot Drinks') AND question_order = 4), 'Nice to meet you', false, 3);

UPDATE lesson_questions SET correct_answer = 'coffee' WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Hot Drinks') AND question_order = 5;

-- ============== FOOD QUESTIONS ==============
-- Fruits
INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation) VALUES
((SELECT id FROM lessons WHERE title = 'Fruits'), 'multiple_choice', 'What fruit is red and often used to make sauce?', 1, 'Tomatoes are red and used for sauce.'),
((SELECT id FROM lessons WHERE title = 'Fruits'), 'multiple_choice', 'What yellow fruit do monkeys love?', 2, 'Bananas are yellow curved fruits.'),
((SELECT id FROM lessons WHERE title = 'Fruits'), 'fill_blank', 'An ______ is round and can be red, green, or yellow.', 4, 'Apples come in different colors.'),
((SELECT id FROM lessons WHERE title = 'Fruits'), 'matching', 'Match fruits with their colors', 5, 'Connect fruits to their typical colors.'),
((SELECT id FROM lessons WHERE title = 'Fruits'), 'listening', 'Listen and choose the fruit', 6, 'Identify fruits by name.');

INSERT INTO lesson_questions (lesson_id, question_type, question_text, vietnamese_text, correct_answer, question_order, explanation) VALUES
((SELECT id FROM lessons WHERE title = 'Fruits'), 'translation', 'Translate: Táo', 'Táo', 'apple', 3, 'An apple a day keeps the doctor away.');

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Fruits') AND question_order = 1), 'Tomato', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Fruits') AND question_order = 1), 'Banana', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Fruits') AND question_order = 1), 'Grape', false, 3),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Fruits') AND question_order = 2), 'Banana', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Fruits') AND question_order = 2), 'Apple', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Fruits') AND question_order = 2), 'Orange', false, 3);

UPDATE lesson_questions SET correct_answer = 'apple' WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Fruits') AND question_order = 4;

-- Matching for Fruits
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Fruits') AND question_order = 5), 'Apple', true, 1, 'fruit1'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Fruits') AND question_order = 5), 'Red/Green', true, 2, 'fruit1'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Fruits') AND question_order = 5), 'Banana', true, 3, 'fruit2'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Fruits') AND question_order = 5), 'Yellow', true, 4, 'fruit2'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Fruits') AND question_order = 5), 'Orange', true, 5, 'fruit3'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Fruits') AND question_order = 5), 'Orange', true, 6, 'fruit3');

-- ============== ANIMALS QUESTIONS ==============
-- Pets
INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation) VALUES
((SELECT id FROM lessons WHERE title = 'Pets'), 'multiple_choice', 'What animal says "woof"?', 1, 'Dogs bark with a woof sound.'),
((SELECT id FROM lessons WHERE title = 'Pets'), 'multiple_choice', 'What pet says "meow"?', 2, 'Cats make meowing sounds.'),
((SELECT id FROM lessons WHERE title = 'Pets'), 'fill_blank', 'A ______ has whiskers and likes to catch mice.', 4, 'Cats have whiskers and hunt mice.');

INSERT INTO lesson_questions (lesson_id, question_type, question_text, vietnamese_text, correct_answer, question_order, explanation) VALUES
((SELECT id FROM lessons WHERE title = 'Pets'), 'translation', 'Translate: Chó', 'Chó', 'dog', 3, 'Dogs are loyal pets.');

INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation, conversation_context) VALUES
((SELECT id FROM lessons WHERE title = 'Pets'), 'conversation', 'A: "Do you have any pets?" B: "_____"', 5, 'Common question about pet ownership.', 'Talking about pets');

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Pets') AND question_order = 1), 'Dog', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Pets') AND question_order = 1), 'Cat', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Pets') AND question_order = 1), 'Fish', false, 3),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Pets') AND question_order = 2), 'Cat', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Pets') AND question_order = 2), 'Dog', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Pets') AND question_order = 2), 'Bird', false, 3),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Pets') AND question_order = 5), 'Yes, I have a dog', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Pets') AND question_order = 5), 'I like pizza', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Pets') AND question_order = 5), 'It is raining', false, 3);

UPDATE lesson_questions SET correct_answer = 'cat'
WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Pets') AND question_order = 4;

-- ============== FAMILY QUESTIONS ==============
-- Immediate Family
INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation) VALUES
((SELECT id FROM lessons WHERE title = 'Immediate Family'), 'multiple_choice', 'What do you call your mother''s husband?', 1, 'Your mother''s husband is your father.'),
((SELECT id FROM lessons WHERE title = 'Immediate Family'), 'multiple_choice', 'Who is your father''s son?', 2, 'Your father''s son is your brother (or you).'),
((SELECT id FROM lessons WHERE title = 'Immediate Family'), 'fill_blank', 'My mother''s daughter is my ______.', 3, 'Your mother''s daughter is your sister.'),
((SELECT id FROM lessons WHERE title = 'Immediate Family'), 'matching', 'Match family members with Vietnamese', 5, 'Learn family vocabulary bilingually.');

INSERT INTO lesson_questions (lesson_id, question_type, question_text, vietnamese_text, correct_answer, question_order, explanation) VALUES
((SELECT id FROM lessons WHERE title = 'Immediate Family'), 'translation', 'Translate: Mẹ', 'Mẹ', 'mother', 4, 'Mother is "mẹ" in Vietnamese.');

INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation, conversation_context) VALUES
((SELECT id FROM lessons WHERE title = 'Immediate Family'), 'conversation', 'A: "How many siblings do you have?" B: "_____"', 6, 'Talking about family size.', 'Family conversation');

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Immediate Family') AND question_order = 1), 'Father', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Immediate Family') AND question_order = 1), 'Brother', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Immediate Family') AND question_order = 1), 'Uncle', false, 3),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Immediate Family') AND question_order = 2), 'Brother', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Immediate Family') AND question_order = 2), 'Cousin', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Immediate Family') AND question_order = 2), 'Uncle', false, 3),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Immediate Family') AND question_order = 6), 'I have two sisters', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Immediate Family') AND question_order = 6), 'I like coffee', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Immediate Family') AND question_order = 6), 'Good morning', false, 3);

UPDATE lesson_questions SET correct_answer = 'sister'
WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Immediate Family') AND question_order = 3;

-- Matching for Family
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Immediate Family') AND question_order = 5), 'Father', true, 1, 'family1'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Immediate Family') AND question_order = 5), 'Bố/Cha', true, 2, 'family1'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Immediate Family') AND question_order = 5), 'Mother', true, 3, 'family2'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Immediate Family') AND question_order = 5), 'Mẹ', true, 4, 'family2'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Immediate Family') AND question_order = 5), 'Brother', true, 5, 'family3'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Immediate Family') AND question_order = 5), 'Anh/Em trai', true, 6, 'family3');

-- ============== BODY PARTS QUESTIONS ==============
-- Head & Face
INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation) VALUES
((SELECT id FROM lessons WHERE title = 'Head & Face'), 'multiple_choice', 'What do you use to see?', 1, 'We see with our eyes.'),
((SELECT id FROM lessons WHERE title = 'Head & Face'), 'multiple_choice', 'What body part do you use to smell?', 2, 'The nose is used for smelling.'),
((SELECT id FROM lessons WHERE title = 'Head & Face'), 'fill_blank', 'You use your ______ to hear sounds.', 3, 'Ears detect sound waves.'),
((SELECT id FROM lessons WHERE title = 'Head & Face'), 'matching', 'Match body parts with their functions', 5, 'Connect parts to what they do.'),
((SELECT id FROM lessons WHERE title = 'Head & Face'), 'listening', 'Listen and choose the body part', 6, 'Identify body parts by name.');

INSERT INTO lesson_questions (lesson_id, question_type, question_text, vietnamese_text, correct_answer, question_order, explanation) VALUES
((SELECT id FROM lessons WHERE title = 'Head & Face'), 'translation', 'Translate: Mắt', 'Mắt', 'eyes', 4, 'Eyes are the windows to the soul.');

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Head & Face') AND question_order = 1), 'Eyes', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Head & Face') AND question_order = 1), 'Ears', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Head & Face') AND question_order = 1), 'Nose', false, 3),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Head & Face') AND question_order = 2), 'Nose', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Head & Face') AND question_order = 2), 'Eyes', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Head & Face') AND question_order = 2), 'Mouth', false, 3);

UPDATE lesson_questions SET correct_answer = 'ears' WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Head & Face') AND question_order = 3;

-- Matching for Body Parts
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Head & Face') AND question_order = 5), 'Eyes', true, 1, 'body1'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Head & Face') AND question_order = 5), 'Seeing', true, 2, 'body1'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Head & Face') AND question_order = 5), 'Ears', true, 3, 'body2'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Head & Face') AND question_order = 5), 'Hearing', true, 4, 'body2'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Head & Face') AND question_order = 5), 'Mouth', true, 5, 'body3'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Head & Face') AND question_order = 5), 'Eating/Speaking', true, 6, 'body3');

-- =====================================================
-- ELEMENTARY LEVEL QUESTIONS
-- =====================================================

-- ============== HOUSE & HOME QUESTIONS ==============
-- Rooms in a House
INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation) VALUES
((SELECT id FROM lessons WHERE title = 'Rooms in a House'), 'multiple_choice', 'Where do you sleep?', 1, 'We sleep in the bedroom.'),
((SELECT id FROM lessons WHERE title = 'Rooms in a House'), 'multiple_choice', 'Where do you cook food?', 2, 'Cooking happens in the kitchen.'),
((SELECT id FROM lessons WHERE title = 'Rooms in a House'), 'fill_blank', 'I take a shower in the ______.', 3, 'Bathrooms have showers and bathtubs.'),
((SELECT id FROM lessons WHERE title = 'Rooms in a House'), 'matching', 'Match rooms with activities', 5, 'Connect rooms to common activities.');

INSERT INTO lesson_questions (lesson_id, question_type, question_text, vietnamese_text, correct_answer, question_order, explanation) VALUES
((SELECT id FROM lessons WHERE title = 'Rooms in a House'), 'translation', 'Translate: Phòng khách', 'Phòng khách', 'living room', 4, 'Living room is where family gathers.');

INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation, conversation_context) VALUES
((SELECT id FROM lessons WHERE title = 'Rooms in a House'), 'conversation', 'A: "Where is your bedroom?" B: "_____"', 6, 'Describing room locations.', 'House tour');

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Rooms in a House') AND question_order = 1), 'Bedroom', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Rooms in a House') AND question_order = 1), 'Kitchen', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Rooms in a House') AND question_order = 1), 'Bathroom', false, 3),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Rooms in a House') AND question_order = 2), 'Kitchen', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Rooms in a House') AND question_order = 2), 'Living room', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Rooms in a House') AND question_order = 2), 'Garage', false, 3),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Rooms in a House') AND question_order = 6), 'It is upstairs on the left', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Rooms in a House') AND question_order = 6), 'I like pizza', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Rooms in a House') AND question_order = 6), 'Thank you', false, 3);

UPDATE lesson_questions SET correct_answer = 'bathroom'
WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Rooms in a House') AND question_order = 3;

-- Matching for Rooms
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Rooms in a House') AND question_order = 5), 'Bedroom', true, 1, 'room1'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Rooms in a House') AND question_order = 5), 'Sleeping', true, 2, 'room1'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Rooms in a House') AND question_order = 5), 'Kitchen', true, 3, 'room2'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Rooms in a House') AND question_order = 5), 'Cooking', true, 4, 'room2'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Rooms in a House') AND question_order = 5), 'Living room', true, 5, 'room3'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Rooms in a House') AND question_order = 5), 'Relaxing', true, 6, 'room3');

-- ============== TECHNOLOGY QUESTIONS ==============
-- Devices
INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation) VALUES
((SELECT id FROM lessons WHERE title = 'Devices'), 'multiple_choice', 'What device do you use to make calls?', 1, 'Smartphones are used for calling.'),
((SELECT id FROM lessons WHERE title = 'Devices'), 'multiple_choice', 'What do you use to type documents?', 2, 'Computers have keyboards for typing.'),
((SELECT id FROM lessons WHERE title = 'Devices'), 'fill_blank', 'I read books on my ______.', 3, 'Tablets are good for reading.'),
((SELECT id FROM lessons WHERE title = 'Devices'), 'matching', 'Match devices with their uses', 5, 'Connect tech to its purpose.');

INSERT INTO lesson_questions (lesson_id, question_type, question_text, vietnamese_text, correct_answer, question_order, explanation) VALUES
((SELECT id FROM lessons WHERE title = 'Devices'), 'translation', 'Translate: Điện thoại', 'Điện thoại', 'phone', 4, 'Phones connect people worldwide.');

INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation, conversation_context) VALUES
((SELECT id FROM lessons WHERE title = 'Devices'), 'conversation', 'A: "What phone do you have?" B: "_____"', 6, 'Talking about technology.', 'Technology discussion');

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Devices') AND question_order = 1), 'Smartphone', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Devices') AND question_order = 1), 'Refrigerator', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Devices') AND question_order = 1), 'Chair', false, 3),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Devices') AND question_order = 2), 'Computer', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Devices') AND question_order = 2), 'Television', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Devices') AND question_order = 2), 'Camera', false, 3),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Devices') AND question_order = 6), 'I have an iPhone', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Devices') AND question_order = 6), 'I am happy', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Devices') AND question_order = 6), 'See you tomorrow', false, 3);

UPDATE lesson_questions SET correct_answer = 'tablet'
WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Devices') AND question_order = 3;

-- Matching for Devices
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Devices') AND question_order = 5), 'Computer', true, 1, 'device1'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Devices') AND question_order = 5), 'Work and study', true, 2, 'device1'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Devices') AND question_order = 5), 'Smartphone', true, 3, 'device2'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Devices') AND question_order = 5), 'Communication', true, 4, 'device2'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Devices') AND question_order = 5), 'Tablet', true, 5, 'device3'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Devices') AND question_order = 5), 'Reading and entertainment', true, 6, 'device3');

-- =====================================================
-- INTERMEDIATE LEVEL QUESTIONS
-- =====================================================

-- ============== BUSINESS ENGLISH QUESTIONS ==============
-- Business Meetings
INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation) VALUES
((SELECT id FROM lessons WHERE title = 'Business Meetings'), 'multiple_choice', 'What is a fixed time to complete a task?', 1, 'A deadline is a time limit.'),
((SELECT id FROM lessons WHERE title = 'Business Meetings'), 'fill_blank', 'We need to schedule a ______ to discuss the project.', 2, 'Meetings are scheduled discussions.'),
((SELECT id FROM lessons WHERE title = 'Business Meetings'), 'matching', 'Match business terms with definitions', 5, 'Learn professional vocabulary.');

INSERT INTO lesson_questions (lesson_id, question_type, question_text, vietnamese_text, correct_answer, question_order, explanation) VALUES
((SELECT id FROM lessons WHERE title = 'Business Meetings'), 'translation', 'Translate: Cuộc họp', 'Cuộc họp', 'meeting', 4, 'Meetings are essential in business.');

INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation, conversation_context) VALUES
((SELECT id FROM lessons WHERE title = 'Business Meetings'), 'conversation', 'Manager: "Can you present tomorrow?" You: "_____"', 3, 'Professional response.', 'Business meeting');

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Business Meetings') AND question_order = 1), 'Deadline', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Business Meetings') AND question_order = 1), 'Holiday', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Business Meetings') AND question_order = 1), 'Birthday', false, 3),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Business Meetings') AND question_order = 3), 'Yes, I can prepare the presentation', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Business Meetings') AND question_order = 3), 'I like coffee', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Business Meetings') AND question_order = 3), 'Nice weather today', false, 3);

UPDATE lesson_questions SET correct_answer = 'meeting' WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Business Meetings') AND question_order = 2;

-- Matching for Business
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Business Meetings') AND question_order = 5), 'Agenda', true, 1, 'biz1'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Business Meetings') AND question_order = 5), 'Meeting plan', true, 2, 'biz1'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Business Meetings') AND question_order = 5), 'Report', true, 3, 'biz2'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Business Meetings') AND question_order = 5), 'Written summary', true, 4, 'biz2'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Business Meetings') AND question_order = 5), 'Deadline', true, 5, 'biz3'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Business Meetings') AND question_order = 5), 'Time limit', true, 6, 'biz3');

-- =====================================================
-- ADVANCED LEVEL QUESTIONS
-- =====================================================

-- ============== SCIENCE & INNOVATION QUESTIONS ==============
-- Natural Sciences
INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation) VALUES
((SELECT id FROM lessons WHERE title = 'Natural Sciences'), 'multiple_choice', 'What is the study of living organisms?', 1, 'Biology studies life.'),
((SELECT id FROM lessons WHERE title = 'Natural Sciences'), 'multiple_choice', 'What science studies matter and energy?', 2, 'Physics examines physical phenomena.'),
((SELECT id FROM lessons WHERE title = 'Natural Sciences'), 'fill_blank', 'The basic unit of life is the ______.', 3, 'Cells are fundamental to all life.');

INSERT INTO lesson_questions (lesson_id, question_type, question_text, vietnamese_text, correct_answer, question_order, explanation) VALUES
((SELECT id FROM lessons WHERE title = 'Natural Sciences'), 'translation', 'Translate: Khoa học', 'Khoa học', 'science', 4, 'Science seeks knowledge through observation.');

INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation, conversation_context) VALUES
((SELECT id FROM lessons WHERE title = 'Natural Sciences'), 'conversation', 'Professor: "What interests you about science?" Student: "_____"', 5, 'Academic discussion.', 'Academic seminar');

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Natural Sciences') AND question_order = 1), 'Biology', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Natural Sciences') AND question_order = 1), 'History', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Natural Sciences') AND question_order = 1), 'Literature', false, 3),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Natural Sciences') AND question_order = 2), 'Physics', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Natural Sciences') AND question_order = 2), 'Sociology', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Natural Sciences') AND question_order = 2), 'Economics', false, 3),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Natural Sciences') AND question_order = 5), 'I find the complexity of living systems fascinating', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Natural Sciences') AND question_order = 5), 'I like ice cream', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Natural Sciences') AND question_order = 5), 'The weather is nice', false, 3);

UPDATE lesson_questions SET correct_answer = 'cell'
WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Natural Sciences') AND question_order = 3;

COMMIT;

-- =====================================================
-- DATA SUMMARY
-- =====================================================
-- This file contains detailed questions for:
-- - Beginner lessons: Alphabet, Colors, Numbers, Drinks, Food, Animals, Family, Body Parts
-- - Elementary lessons: House & Home, Technology
-- - Intermediate lessons: Business English
-- - Advanced lessons: Science & Innovation
--
-- Total questions in this file: ~80+ questions
-- Each lesson has 4-6 questions with diverse types
-- All 6 question types utilized: multiple_choice, fill_blank, matching, listening, translation, conversation
--
-- Next steps:
-- 1. Add more questions for remaining lessons
-- 2. Integrate actual dictionary vocabulary
-- 3. Add audio URLs for listening exercises
-- 4. Add image URLs for visual questions
-- =====================================================
