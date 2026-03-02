-- =====================================================
-- EXTENDED DATABASE - 100+ LESSONS WITH DIVERSE CONTENT
-- Full English Learning Curriculum from A1 to C1
-- =====================================================
-- Created: March 2026
-- Purpose: Complete lesson structure utilizing dictionary data
-- =====================================================

-- =====================================================
-- BEGINNER LEVEL (A1-A2) - 16 MAIN TOPICS
-- =====================================================

-- ============== 1. ALPHABET - Bảng chữ cái ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Alphabet - Bảng chữ cái', 'Master the English alphabet from A to Z', 'beginner', 'multiple_choice', 25, 0, NULL, 1);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Basic Alphabet', 'Recognize and write letters A-Z', 'beginner', 'multiple_choice', 8, 6, 
  (SELECT id FROM lessons WHERE title = 'Alphabet - Bảng chữ cái' AND parent_lesson_id IS NULL), 1),
('Vowels Practice', 'Master the 5 vowels: A, E, I, O, U', 'beginner', 'listening', 7, 5,
  (SELECT id FROM lessons WHERE title = 'Alphabet - Bảng chữ cái' AND parent_lesson_id IS NULL), 2),
('Consonants Practice', 'Learn all consonant letters', 'beginner', 'matching', 10, 8,
  (SELECT id FROM lessons WHERE title = 'Alphabet - Bảng chữ cái' AND parent_lesson_id IS NULL), 3);

-- ============== 2. COLORS - Màu sắc ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Colors - Màu sắc', 'Learn all colors in English', 'beginner', 'multiple_choice', 20, 0, NULL, 2);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Basic Colors', 'Learn primary and common colors', 'beginner', 'multiple_choice', 8, 6,
  (SELECT id FROM lessons WHERE title = 'Colors - Màu sắc' AND parent_lesson_id IS NULL), 1),
('Color Descriptions', 'Describe objects by color', 'beginner', 'fill_blank', 7, 5,
  (SELECT id FROM lessons WHERE title = 'Colors - Màu sắc' AND parent_lesson_id IS NULL), 2),
('Advanced Colors', 'Learn complex color names', 'beginner', 'matching', 8, 6,
  (SELECT id FROM lessons WHERE title = 'Colors - Màu sắc' AND parent_lesson_id IS NULL), 3);

-- ============== 3. NUMBERS - Số đếm ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Numbers - Số đếm', 'Count from 1 to 1000 in English', 'beginner', 'multiple_choice', 30, 0, NULL, 3);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Numbers 1-20', 'Basic counting from 1 to 20', 'beginner', 'multiple_choice', 10, 6,
  (SELECT id FROM lessons WHERE title = 'Numbers - Số đếm' AND parent_lesson_id IS NULL), 1),
('Numbers 20-100', 'Count in tens to 100', 'beginner', 'listening', 10, 5,
  (SELECT id FROM lessons WHERE title = 'Numbers - Số đếm' AND parent_lesson_id IS NULL), 2),
('Large Numbers', 'Numbers 100-1000', 'beginner', 'fill_blank', 10, 5,
  (SELECT id FROM lessons WHERE title = 'Numbers - Số đếm' AND parent_lesson_id IS NULL), 3);

-- ============== 4. DRINKS - Đồ uống ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Drinks - Đồ uống', 'Vocabulary for all types of drinks', 'beginner', 'multiple_choice', 18, 0, NULL, 4);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Hot Drinks', 'Coffee, tea, hot chocolate', 'beginner', 'multiple_choice', 6, 5,
  (SELECT id FROM lessons WHERE title = 'Drinks - Đồ uống' AND parent_lesson_id IS NULL), 1),
('Cold Drinks', 'Juice, soda, smoothies', 'beginner', 'matching', 6, 6,
  (SELECT id FROM lessons WHERE title = 'Drinks - Đồ uống' AND parent_lesson_id IS NULL), 2),
('Ordering Drinks', 'How to order in a café', 'beginner', 'conversation', 6, 4,
  (SELECT id FROM lessons WHERE title = 'Drinks - Đồ uống' AND parent_lesson_id IS NULL), 3);

-- ============== 5. FOOD - Đồ ăn ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Food - Đồ ăn', 'Learn vocabulary for different foods', 'beginner', 'multiple_choice', 25, 0, NULL, 5);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Fruits', 'Common fruits vocabulary', 'beginner', 'multiple_choice', 8, 6,
  (SELECT id FROM lessons WHERE title = 'Food - Đồ ăn' AND parent_lesson_id IS NULL), 1),
('Vegetables', 'Learn vegetable names', 'beginner', 'matching', 8, 6,
  (SELECT id FROM lessons WHERE title = 'Food - Đồ ăn' AND parent_lesson_id IS NULL), 2),
('Meals & Dishes', 'Breakfast, lunch, dinner foods', 'beginner', 'fill_blank', 9, 5,
  (SELECT id FROM lessons WHERE title = 'Food - Đồ ăn' AND parent_lesson_id IS NULL), 3);

-- ============== 6. ANIMALS - Động vật ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Animals - Động vật', 'Learn about different animals', 'beginner', 'multiple_choice', 22, 0, NULL, 6);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Pets', 'Common household pets', 'beginner', 'multiple_choice', 7, 5,
  (SELECT id FROM lessons WHERE title = 'Animals - Động vật' AND parent_lesson_id IS NULL), 1),
('Farm Animals', 'Animals on a farm', 'beginner', 'matching', 8, 6,
  (SELECT id FROM lessons WHERE title = 'Animals - Động vật' AND parent_lesson_id IS NULL), 2),
('Wild Animals', 'Animals in nature', 'beginner', 'listening', 7, 5,
  (SELECT id FROM lessons WHERE title = 'Animals - Động vật' AND parent_lesson_id IS NULL), 3);

-- ============== 7. FAMILY - Gia đình ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Family - Gia đình', 'Family members and relationships', 'beginner', 'multiple_choice', 20, 0, NULL, 7);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Immediate Family', 'Parents, siblings, children', 'beginner', 'multiple_choice', 7, 6,
  (SELECT id FROM lessons WHERE title = 'Family - Gia đình' AND parent_lesson_id IS NULL), 1),
('Extended Family', 'Grandparents, aunts, uncles, cousins', 'beginner', 'matching', 7, 6,
  (SELECT id FROM lessons WHERE title = 'Family - Gia đình' AND parent_lesson_id IS NULL), 2),
('Family Conversations', 'Talking about your family', 'beginner', 'conversation', 6, 4,
  (SELECT id FROM lessons WHERE title = 'Family - Gia đình' AND parent_lesson_id IS NULL), 3);

-- ============== 8. BODY PARTS - Bộ phận cơ thể ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Body Parts - Bộ phận cơ thể', 'Learn parts of the human body', 'beginner', 'multiple_choice', 18, 0, NULL, 8);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Head & Face', 'Face, eyes, nose, mouth, ears', 'beginner', 'multiple_choice', 6, 6,
  (SELECT id FROM lessons WHERE title = 'Body Parts - Bộ phận cơ thể' AND parent_lesson_id IS NULL), 1),
('Body & Limbs', 'Arms, legs, hands, feet', 'beginner', 'matching', 6, 6,
  (SELECT id FROM lessons WHERE title = 'Body Parts - Bộ phận cơ thể' AND parent_lesson_id IS NULL), 2),
('Internal Organs', 'Heart, lungs, stomach', 'beginner', 'fill_blank', 6, 4,
  (SELECT id FROM lessons WHERE title = 'Body Parts - Bộ phận cơ thể' AND parent_lesson_id IS NULL), 3);

-- ============== 9. CLOTHES - Quần áo ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Clothes - Quần áo', 'Clothing and fashion vocabulary', 'beginner', 'multiple_choice', 20, 0, NULL, 9);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Everyday Clothes', 'Shirt, pants, dress, shoes', 'beginner', 'multiple_choice', 7, 6,
  (SELECT id FROM lessons WHERE title = 'Clothes - Quần áo' AND parent_lesson_id IS NULL), 1),
('Accessories', 'Hat, scarf, belt, jewelry', 'beginner', 'matching', 7, 5,
  (SELECT id FROM lessons WHERE title = 'Clothes - Quần áo' AND parent_lesson_id IS NULL), 2),
('Shopping for Clothes', 'Buying clothes conversations', 'beginner', 'conversation', 6, 4,
  (SELECT id FROM lessons WHERE title = 'Clothes - Quần áo' AND parent_lesson_id IS NULL), 3);

-- ============== 10. DAILY ACTIVITIES - Hoạt động hàng ngày ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Daily Activities - Hoạt động hàng ngày', 'Common daily routines and actions', 'beginner', 'multiple_choice', 22, 0, NULL, 10);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Morning Routine', 'Wake up, brush teeth, have breakfast', 'beginner', 'multiple_choice', 7, 6,
  (SELECT id FROM lessons WHERE title = 'Daily Activities - Hoạt động hàng ngày' AND parent_lesson_id IS NULL), 1),
('Work & School Activities', 'Study, work, attend meetings', 'beginner', 'fill_blank', 7, 5,
  (SELECT id FROM lessons WHERE title = 'Daily Activities - Hoạt động hàng ngày' AND parent_lesson_id IS NULL), 2),
('Evening Activities', 'Dinner, relax, sleep', 'beginner', 'conversation', 8, 5,
  (SELECT id FROM lessons WHERE title = 'Daily Activities - Hoạt động hàng ngày' AND parent_lesson_id IS NULL), 3);

-- ============== 11. WEATHER - Thời tiết ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Weather - Thời tiết', 'Weather conditions and forecasts', 'beginner', 'multiple_choice', 18, 0, NULL, 11);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Weather Conditions', 'Sunny, rainy, cloudy, windy', 'beginner', 'multiple_choice', 6, 6,
  (SELECT id FROM lessons WHERE title = 'Weather - Thời tiết' AND parent_lesson_id IS NULL), 1),
('Temperature', 'Hot, cold, warm, freezing', 'beginner', 'fill_blank', 6, 5,
  (SELECT id FROM lessons WHERE title = 'Weather - Thời tiết' AND parent_lesson_id IS NULL), 2),
('Weather Talk', 'Discussing the weather', 'beginner', 'conversation', 6, 4,
  (SELECT id FROM lessons WHERE title = 'Weather - Thời tiết' AND parent_lesson_id IS NULL), 3);

-- ============== 12. SEASONS - Mùa ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Seasons - Mùa', 'Four seasons and their characteristics', 'beginner', 'multiple_choice', 16, 0, NULL, 12);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Spring & Summer', 'Warm weather seasons', 'beginner', 'multiple_choice', 5, 5,
  (SELECT id FROM lessons WHERE title = 'Seasons - Mùa' AND parent_lesson_id IS NULL), 1),
('Fall & Winter', 'Cool weather seasons', 'beginner', 'matching', 6, 5,
  (SELECT id FROM lessons WHERE title = 'Seasons - Mùa' AND parent_lesson_id IS NULL), 2),
('Seasonal Activities', 'What to do each season', 'beginner', 'translation', 5, 4,
  (SELECT id FROM lessons WHERE title = 'Seasons - Mùa' AND parent_lesson_id IS NULL), 3);

-- ============== 13. TIME - Thời gian ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Time - Thời gian', 'Telling time and time expressions', 'beginner', 'multiple_choice', 20, 0, NULL, 13);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Clock Reading', 'Hours, minutes, o''clock', 'beginner', 'multiple_choice', 7, 6,
  (SELECT id FROM lessons WHERE title = 'Time - Thời gian' AND parent_lesson_id IS NULL), 1),
('Time Expressions', 'In the morning, at night, yesterday', 'beginner', 'fill_blank', 7, 5,
  (SELECT id FROM lessons WHERE title = 'Time - Thời gian' AND parent_lesson_id IS NULL), 2),
('Asking About Time', 'What time is it?', 'beginner', 'conversation', 6, 4,
  (SELECT id FROM lessons WHERE title = 'Time - Thời gian' AND parent_lesson_id IS NULL), 3);

-- ============== 14. DAYS & MONTHS - Ngày tháng ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Days & Months - Ngày tháng', 'Days of week and months of year', 'beginner', 'multiple_choice', 18, 0, NULL, 14);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Days of the Week', 'Monday through Sunday', 'beginner', 'multiple_choice', 6, 5,
  (SELECT id FROM lessons WHERE title = 'Days & Months - Ngày tháng' AND parent_lesson_id IS NULL), 1),
('Months of the Year', 'January through December', 'beginner', 'matching', 6, 6,
  (SELECT id FROM lessons WHERE title = 'Days & Months - Ngày tháng' AND parent_lesson_id IS NULL), 2),
('Dates & Appointments', 'Making appointments', 'beginner', 'conversation', 6, 4,
  (SELECT id FROM lessons WHERE title = 'Days & Months - Ngày tháng' AND parent_lesson_id IS NULL), 3);

-- ============== 15. PLACES - Địa điểm ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Places - Địa điểm', 'Common places in town and city', 'beginner', 'multiple_choice', 22, 0, NULL, 15);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Public Places', 'Park, library, post office, bank', 'beginner', 'multiple_choice', 7, 6,
  (SELECT id FROM lessons WHERE title = 'Places - Địa điểm' AND parent_lesson_id IS NULL), 1),
('Shops & Stores', 'Supermarket, bakery, pharmacy', 'beginner', 'matching', 8, 6,
  (SELECT id FROM lessons WHERE title = 'Places - Địa điểm' AND parent_lesson_id IS NULL), 2),
('Giving Directions', 'How to get to places', 'beginner', 'conversation', 7, 5,
  (SELECT id FROM lessons WHERE title = 'Places - Địa điểm' AND parent_lesson_id IS NULL), 3);

-- ============== 16. TRANSPORTATION - Phương tiện ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Transportation - Phương tiện', 'Vehicles and travel methods', 'beginner', 'multiple_choice', 20, 0, NULL, 16);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Land Transport', 'Car, bus, train, bicycle', 'beginner', 'multiple_choice', 7, 6,
  (SELECT id FROM lessons WHERE title = 'Transportation - Phương tiện' AND parent_lesson_id IS NULL), 1),
('Air & Water Transport', 'Plane, boat, ship', 'beginner', 'matching', 6, 5,
  (SELECT id FROM lessons WHERE title = 'Transportation - Phương tiện' AND parent_lesson_id IS NULL), 2),
('Travel Conversations', 'Buying tickets, asking directions', 'beginner', 'conversation', 7, 5,
  (SELECT id FROM lessons WHERE title = 'Transportation - Phương tiện' AND parent_lesson_id IS NULL), 3);

-- =====================================================
-- ELEMENTARY LEVEL (A2-B1) - 10 MAIN TOPICS
-- =====================================================

-- ============== 17. HOUSE & HOME - Nhà ở ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('House & Home - Nhà ở', 'Rooms, furniture, and household items', 'elementary', 'multiple_choice', 25, 0, NULL, 17);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Rooms in a House', 'Living room, bedroom, kitchen, bathroom', 'elementary', 'multiple_choice', 8, 6,
  (SELECT id FROM lessons WHERE title = 'House & Home - Nhà ở' AND parent_lesson_id IS NULL), 1),
('Furniture', 'Table, chair, bed, sofa', 'elementary', 'matching', 8, 6,
  (SELECT id FROM lessons WHERE title = 'House & Home - Nhà ở' AND parent_lesson_id IS NULL), 2),
('Household Chores', 'Cleaning, cooking, laundry', 'elementary', 'fill_blank', 9, 5,
  (SELECT id FROM lessons WHERE title = 'House & Home - Nhà ở' AND parent_lesson_id IS NULL), 3);

-- ============== 18. SHOPPING - Mua sắm ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Shopping - Mua sắm', 'Shopping vocabulary and expressions', 'elementary', 'multiple_choice', 22, 0, NULL, 18);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('At the Store', 'Asking for items, prices', 'elementary', 'conversation', 7, 5,
  (SELECT id FROM lessons WHERE title = 'Shopping - Mua sắm' AND parent_lesson_id IS NULL), 1),
('Online Shopping', 'E-commerce vocabulary', 'elementary', 'fill_blank', 8, 5,
  (SELECT id FROM lessons WHERE title = 'Shopping - Mua sắm' AND parent_lesson_id IS NULL), 2),
('Payments & Returns', 'Cash, card, refund, exchange', 'elementary', 'multiple_choice', 7, 6,
  (SELECT id FROM lessons WHERE title = 'Shopping - Mua sắm' AND parent_lesson_id IS NULL), 3);

-- ============== 19. HOBBIES - Sở thích ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Hobbies - Sở thích', 'Talking about interests and pastimes', 'elementary', 'multiple_choice', 20, 0, NULL, 19);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Indoor Hobbies', 'Reading, painting, cooking', 'elementary', 'multiple_choice', 7, 6,
  (SELECT id FROM lessons WHERE title = 'Hobbies - Sở thích' AND parent_lesson_id IS NULL), 1),
('Outdoor Activities', 'Hiking, camping, gardening', 'elementary', 'matching', 6, 5,
  (SELECT id FROM lessons WHERE title = 'Hobbies - Sở thích' AND parent_lesson_id IS NULL), 2),
('Discussing Hobbies', 'What do you like to do?', 'elementary', 'conversation', 7, 5,
  (SELECT id FROM lessons WHERE title = 'Hobbies - Sở thích' AND parent_lesson_id IS NULL), 3);

-- ============== 20. SPORTS - Thể thao ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Sports - Thể thao', 'Sports vocabulary and activities', 'elementary', 'multiple_choice', 22, 0, NULL, 20);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Ball Sports', 'Football, basketball, tennis', 'elementary', 'multiple_choice', 7, 6,
  (SELECT id FROM lessons WHERE title = 'Sports - Thể thao' AND parent_lesson_id IS NULL), 1),
('Individual Sports', 'Swimming, running, cycling', 'elementary', 'matching', 8, 6,
  (SELECT id FROM lessons WHERE title = 'Sports - Thể thao' AND parent_lesson_id IS NULL), 2),
('Sports Talk', 'Discussing sports and games', 'elementary', 'conversation', 7, 5,
  (SELECT id FROM lessons WHERE title = 'Sports - Thể thao' AND parent_lesson_id IS NULL), 3);

-- ============== 21. SCHOOL & EDUCATION - Trường học ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('School & Education - Trường học', 'Education system and school life', 'elementary', 'multiple_choice', 25, 0, NULL, 21);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('School Subjects', 'Math, science, history, art', 'elementary', 'multiple_choice', 8, 6,
  (SELECT id FROM lessons WHERE title = 'School & Education - Trường học' AND parent_lesson_id IS NULL), 1),
('Classroom Objects', 'Desk, board, pen, notebook', 'elementary', 'matching', 8, 6,
  (SELECT id FROM lessons WHERE title = 'School & Education - Trường học' AND parent_lesson_id IS NULL), 2),
('At School', 'Talking about classes and homework', 'elementary', 'conversation', 9, 5,
  (SELECT id FROM lessons WHERE title = 'School & Education - Trường học' AND parent_lesson_id IS NULL), 3);

-- ============== 22. JOBS & OCCUPATIONS - Nghề nghiệp ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Jobs & Occupations - Nghề nghiệp', 'Different careers and professions', 'elementary', 'multiple_choice', 24, 0, NULL, 22);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Common Jobs', 'Teacher, doctor, engineer, chef', 'elementary', 'multiple_choice', 8, 6,
  (SELECT id FROM lessons WHERE title = 'Jobs & Occupations - Nghề nghiệp' AND parent_lesson_id IS NULL), 1),
('Job Descriptions', 'What they do at work', 'elementary', 'fill_blank', 8, 5,
  (SELECT id FROM lessons WHERE title = 'Jobs & Occupations - Nghề nghiệp' AND parent_lesson_id IS NULL), 2),
('Job Interview', 'Interview questions and answers', 'elementary', 'conversation', 8, 5,
  (SELECT id FROM lessons WHERE title = 'Jobs & Occupations - Nghề nghiệp' AND parent_lesson_id IS NULL), 3);

-- ============== 23. HEALTH & MEDICINE - Sức khỏe ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Health & Medicine - Sức khỏe', 'Health, illness, and medical care', 'elementary', 'multiple_choice', 22, 0, NULL, 23);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Common Illnesses', 'Cold, flu, fever, headache', 'elementary', 'multiple_choice', 7, 6,
  (SELECT id FROM lessons WHERE title = 'Health & Medicine - Sức khỏe' AND parent_lesson_id IS NULL), 1),
('At the Doctor', 'Symptoms and treatment', 'elementary', 'conversation', 8, 5,
  (SELECT id FROM lessons WHERE title = 'Health & Medicine - Sức khỏe' AND parent_lesson_id IS NULL), 2),
('Healthy Living', 'Diet, exercise, sleep', 'elementary', 'fill_blank', 7, 5,
  (SELECT id FROM lessons WHERE title = 'Health & Medicine - Sức khỏe' AND parent_lesson_id IS NULL), 3);

-- ============== 24. FEELINGS & EMOTIONS - Cảm xúc ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Feelings & Emotions - Cảm xúc', 'Expressing emotions and feelings', 'elementary', 'multiple_choice', 20, 0, NULL, 24);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Basic Emotions', 'Happy, sad, angry, scared', 'elementary', 'multiple_choice', 7, 6,
  (SELECT id FROM lessons WHERE title = 'Feelings & Emotions - Cảm xúc' AND parent_lesson_id IS NULL), 1),
('Complex Feelings', 'Anxious, excited, disappointed', 'elementary', 'matching', 6, 5,
  (SELECT id FROM lessons WHERE title = 'Feelings & Emotions - Cảm xúc' AND parent_lesson_id IS NULL), 2),
('Expressing Feelings', 'How do you feel?', 'elementary', 'conversation', 7, 5,
  (SELECT id FROM lessons WHERE title = 'Feelings & Emotions - Cảm xúc' AND parent_lesson_id IS NULL), 3);

-- ============== 25. TRAVEL & TOURISM - Du lịch ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Travel & Tourism - Du lịch', 'Travel vocabulary and situations', 'elementary', 'multiple_choice', 28, 0, NULL, 25);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('At the Airport', 'Check-in, boarding, luggage', 'elementary', 'conversation', 9, 5,
  (SELECT id FROM lessons WHERE title = 'Travel & Tourism - Du lịch' AND parent_lesson_id IS NULL), 1),
('Hotel Accommodation', 'Booking, check-in, room service', 'elementary', 'multiple_choice', 10, 6,
  (SELECT id FROM lessons WHERE title = 'Travel & Tourism - Du lịch' AND parent_lesson_id IS NULL), 2),
('Tourist Attractions', 'Museum, beach, monument', 'elementary', 'matching', 9, 6,
  (SELECT id FROM lessons WHERE title = 'Travel & Tourism - Du lịch' AND parent_lesson_id IS NULL), 3);

-- ============== 26. TECHNOLOGY - Công nghệ ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Technology - Công nghệ', 'Modern technology vocabulary', 'elementary', 'multiple_choice', 24, 0, NULL, 26);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Devices', 'Computer, smartphone, tablet', 'elementary', 'multiple_choice', 8, 6,
  (SELECT id FROM lessons WHERE title = 'Technology - Công nghệ' AND parent_lesson_id IS NULL), 1),
('Internet & Social Media', 'Email, website, app, online', 'elementary', 'fill_blank', 8, 5,
  (SELECT id FROM lessons WHERE title = 'Technology - Công nghệ' AND parent_lesson_id IS NULL), 2),
('Tech Problems', 'Troubleshooting conversations', 'elementary', 'conversation', 8, 5,
  (SELECT id FROM lessons WHERE title = 'Technology - Công nghệ' AND parent_lesson_id IS NULL), 3);

-- =====================================================
-- INTERMEDIATE LEVEL (B1-B2) - 7 MAIN TOPICS
-- =====================================================

-- ============== 27. BUSINESS ENGLISH - Tiếng Anh thương mại ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Business English - Tiếng Anh thương mại', 'Professional English for workplace', 'intermediate', 'multiple_choice', 30, 0, NULL, 27);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Business Vocabulary', 'Meeting, presentation, report, deadline', 'intermediate', 'multiple_choice', 10, 6,
  (SELECT id FROM lessons WHERE title = 'Business English - Tiếng Anh thương mại' AND parent_lesson_id IS NULL), 1),
('Email Writing', 'Professional email structure', 'intermediate', 'fill_blank', 10, 5,
  (SELECT id FROM lessons WHERE title = 'Business English - Tiếng Anh thương mại' AND parent_lesson_id IS NULL), 2),
('Business Meetings', 'Formal meeting language', 'intermediate', 'conversation', 10, 5,
  (SELECT id FROM lessons WHERE title = 'Business English - Tiếng Anh thương mại' AND parent_lesson_id IS NULL), 3);

-- ============== 28. ENVIRONMENT - Môi trường ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Environment - Môi trường', 'Environmental issues and solutions', 'intermediate', 'multiple_choice', 28, 0, NULL, 28);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Climate Change', 'Global warming, greenhouse effect', 'intermediate', 'fill_blank', 9, 5,
  (SELECT id FROM lessons WHERE title = 'Environment - Môi trường' AND parent_lesson_id IS NULL), 1),
('Pollution', 'Air, water, soil pollution', 'intermediate', 'multiple_choice', 10, 6,
  (SELECT id FROM lessons WHERE title = 'Environment - Môi trường' AND parent_lesson_id IS NULL), 2),
('Sustainability', 'Recycling, renewable energy', 'intermediate', 'translation', 9, 5,
  (SELECT id FROM lessons WHERE title = 'Environment - Môi trường' AND parent_lesson_id IS NULL), 3);

-- ============== 29. CULTURE & CUSTOMS - Văn hóa ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Culture & Customs - Văn hóa', 'Cultural differences and traditions', 'intermediate', 'multiple_choice', 26, 0, NULL, 29);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Festivals & Holidays', 'Cultural celebrations worldwide', 'intermediate', 'multiple_choice', 9, 6,
  (SELECT id FROM lessons WHERE title = 'Culture & Customs - Văn hóa' AND parent_lesson_id IS NULL), 1),
('Social Etiquette', 'Manners and customs', 'intermediate', 'conversation', 8, 5,
  (SELECT id FROM lessons WHERE title = 'Culture & Customs - Văn hóa' AND parent_lesson_id IS NULL), 2),
('Cultural Comparison', 'East vs West culture', 'intermediate', 'fill_blank', 9, 5,
  (SELECT id FROM lessons WHERE title = 'Culture & Customs - Văn hóa' AND parent_lesson_id IS NULL), 3);

-- ============== 30. CURRENT EVENTS - Sự kiện ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Current Events - Sự kiện', 'News and current affairs vocabulary', 'intermediate', 'multiple_choice', 25, 0, NULL, 30);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('News Vocabulary', 'Headlines, breaking news, reporter', 'intermediate', 'multiple_choice', 8, 6,
  (SELECT id FROM lessons WHERE title = 'Current Events - Sự kiện' AND parent_lesson_id IS NULL), 1),
('Reading News', 'Understanding news articles', 'intermediate', 'fill_blank', 9, 5,
  (SELECT id FROM lessons WHERE title = 'Current Events - Sự kiện' AND parent_lesson_id IS NULL), 2),
('Discussing News', 'Opinions on current events', 'intermediate', 'conversation', 8, 5,
  (SELECT id FROM lessons WHERE title = 'Current Events - Sự kiện' AND parent_lesson_id IS NULL), 3);

-- ============== 31. ENTERTAINMENT - Giải trí ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Entertainment - Giải trí', 'Movies, music, and entertainment', 'intermediate', 'multiple_choice', 24, 0, NULL, 31);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Movies & Cinema', 'Film genres and movie vocabulary', 'intermediate', 'multiple_choice', 8, 6,
  (SELECT id FROM lessons WHERE title = 'Entertainment - Giải trí' AND parent_lesson_id IS NULL), 1),
('Music & Concerts', 'Music genres and instruments', 'intermediate', 'matching', 8, 6,
  (SELECT id FROM lessons WHERE title = 'Entertainment - Giải trí' AND parent_lesson_id IS NULL), 2),
('Entertainment Discussion', 'Talking about preferences', 'intermediate', 'conversation', 8, 5,
  (SELECT id FROM lessons WHERE title = 'Entertainment - Giải trí' AND parent_lesson_id IS NULL), 3);

-- ============== 32. RELATIONSHIPS - Quan hệ ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Relationships - Quan hệ', 'Personal relationships vocabulary', 'intermediate', 'multiple_choice', 22, 0, NULL, 32);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Friendship', 'Making and keeping friends', 'intermediate', 'conversation', 7, 5,
  (SELECT id FROM lessons WHERE title = 'Relationships - Quan hệ' AND parent_lesson_id IS NULL), 1),
('Dating & Romance', 'Romantic relationships', 'intermediate', 'fill_blank', 8, 5,
  (SELECT id FROM lessons WHERE title = 'Relationships - Quan hệ' AND parent_lesson_id IS NULL), 2),
('Conflict Resolution', 'Solving disagreements', 'intermediate', 'conversation', 7, 4,
  (SELECT id FROM lessons WHERE title = 'Relationships - Quan hệ' AND parent_lesson_id IS NULL), 3);

-- ============== 33. MONEY & BANKING - Tài chính ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Money & Banking - Tài chính', 'Financial vocabulary and banking', 'intermediate', 'multiple_choice', 26, 0, NULL, 33);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Banking Services', 'Account, deposit, withdrawal, transfer', 'intermediate', 'multiple_choice', 9, 6,
  (SELECT id FROM lessons WHERE title = 'Money & Banking - Tài chính' AND parent_lesson_id IS NULL), 1),
('Personal Finance', 'Budget, savings, investment', 'intermediate', 'fill_blank', 8, 5,
  (SELECT id FROM lessons WHERE title = 'Money & Banking - Tài chính' AND parent_lesson_id IS NULL), 2),
('At the Bank', 'Banking conversations', 'intermediate', 'conversation', 9, 5,
  (SELECT id FROM lessons WHERE title = 'Money & Banking - Tài chính' AND parent_lesson_id IS NULL), 3);

-- =====================================================
-- ADVANCED LEVEL (B2-C1) - 5 MAIN TOPICS
-- =====================================================

-- ============== 34. POLITICS & GOVERNMENT - Chính trị ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Politics & Government - Chính trị', 'Political systems and governance', 'advanced', 'multiple_choice', 32, 0, NULL, 34);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Political Systems', 'Democracy, monarchy, republic', 'advanced', 'multiple_choice', 11, 6,
  (SELECT id FROM lessons WHERE title = 'Politics & Government - Chính trị' AND parent_lesson_id IS NULL), 1),
('Elections & Voting', 'Campaign, ballot, candidate', 'advanced', 'fill_blank', 10, 5,
  (SELECT id FROM lessons WHERE title = 'Politics & Government - Chính trị' AND parent_lesson_id IS NULL), 2),
('Political Debate', 'Discussing political issues', 'advanced', 'conversation', 11, 5,
  (SELECT id FROM lessons WHERE title = 'Politics & Government - Chính trị' AND parent_lesson_id IS NULL), 3);

-- ============== 35. SCIENCE & INNOVATION - Khoa học ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Science & Innovation - Khoa học', 'Scientific concepts and discoveries', 'advanced', 'multiple_choice', 30, 0, NULL, 35);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Natural Sciences', 'Physics, chemistry, biology', 'advanced', 'multiple_choice', 10, 6,
  (SELECT id FROM lessons WHERE title = 'Science & Innovation - Khoa học' AND parent_lesson_id IS NULL), 1),
('Technology Innovation', 'AI, robotics, biotechnology', 'advanced', 'fill_blank', 10, 5,
  (SELECT id FROM lessons WHERE title = 'Science & Innovation - Khoa học' AND parent_lesson_id IS NULL), 2),
('Scientific Discussion', 'Explaining scientific concepts', 'advanced', 'conversation', 10, 5,
  (SELECT id FROM lessons WHERE title = 'Science & Innovation - Khoa học' AND parent_lesson_id IS NULL), 3);

-- ============== 36. PHILOSOPHY & ETHICS - Triết học ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Philosophy & Ethics - Triết học', 'Philosophical concepts and moral issues', 'advanced', 'multiple_choice', 28, 0, NULL, 36);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Philosophical Schools', 'Existentialism, stoicism, pragmatism', 'advanced', 'multiple_choice', 9, 6,
  (SELECT id FROM lessons WHERE title = 'Philosophy & Ethics - Triết học' AND parent_lesson_id IS NULL), 1),
('Ethics & Morality', 'Right and wrong, justice, fairness', 'advanced', 'fill_blank', 10, 5,
  (SELECT id FROM lessons WHERE title = 'Philosophy & Ethics - Triết học' AND parent_lesson_id IS NULL), 2),
('Philosophical Debate', 'Discussing abstract concepts', 'advanced', 'conversation', 9, 4,
  (SELECT id FROM lessons WHERE title = 'Philosophy & Ethics - Triết học' AND parent_lesson_id IS NULL), 3);

-- ============== 37. LITERATURE & ARTS - Văn học ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Literature & Arts - Văn học', 'Literary and artistic vocabulary', 'advanced', 'multiple_choice', 30, 0, NULL, 37);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Literary Genres', 'Poetry, novel, drama, essay', 'advanced', 'multiple_choice', 10, 6,
  (SELECT id FROM lessons WHERE title = 'Literature & Arts - Văn học' AND parent_lesson_id IS NULL), 1),
('Art Movements', 'Renaissance, impressionism, modernism', 'advanced', 'matching', 10, 6,
  (SELECT id FROM lessons WHERE title = 'Literature & Arts - Văn học' AND parent_lesson_id IS NULL), 2),
('Literary Analysis', 'Discussing books and art', 'advanced', 'conversation', 10, 5,
  (SELECT id FROM lessons WHERE title = 'Literature & Arts - Văn học' AND parent_lesson_id IS NULL), 3);

-- ============== 38. ECONOMICS - Kinh tế ==============
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Economics - Kinh tế', 'Economic principles and terminology', 'advanced', 'multiple_choice', 32, 0, NULL, 38);

INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions, parent_lesson_id, lesson_order) VALUES
('Economic Systems', 'Capitalism, socialism, mixed economy', 'advanced', 'multiple_choice', 11, 6,
  (SELECT id FROM lessons WHERE title = 'Economics - Kinh tế' AND parent_lesson_id IS NULL), 1),
('Market Forces', 'Supply, demand, inflation, recession', 'advanced', 'fill_blank', 11, 5,
  (SELECT id FROM lessons WHERE title = 'Economics - Kinh tế' AND parent_lesson_id IS NULL), 2),
('Economic Discussion', 'Analyzing economic trends', 'advanced', 'conversation', 10, 5,
  (SELECT id FROM lessons WHERE title = 'Economics - Kinh tế' AND parent_lesson_id IS NULL), 3);

-- =====================================================
-- SAMPLE QUESTIONS (Examples from different levels)
-- =====================================================

-- Beginner: Family Questions
INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation) VALUES
((SELECT id FROM lessons WHERE title = 'Immediate Family'), 'multiple_choice', 'What do you call your father''s wife?', 1, 'Your father''s wife is your mother.'),
((SELECT id FROM lessons WHERE title = 'Immediate Family'), 'multiple_choice', 'Who is your mother''s son?', 2, 'Your mother''s son is your brother (or you).'),
((SELECT id FROM lessons WHERE title = 'Immediate Family'), 'fill_blank', 'My father''s daughter is my ______.', 3, 'Your father''s daughter is your sister.');

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Immediate Family') AND question_order = 1), 'Mother', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Immediate Family') AND question_order = 1), 'Sister', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Immediate Family') AND question_order = 1), 'Aunt', false, 3);

UPDATE lesson_questions SET correct_answer = 'sister' 
WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Immediate Family') AND question_order = 3;

-- Elementary: Technology Questions
INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation) VALUES
((SELECT id FROM lessons WHERE title = 'Devices'), 'multiple_choice', 'What device do you use to make calls and send messages?', 1, 'A smartphone is used for calls and messages.'),
((SELECT id FROM lessons WHERE title = 'Devices'), 'matching', 'Match the devices with their primary use', 2, 'Each device has a main purpose.');

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Devices') AND question_order = 1), 'Smartphone', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Devices') AND question_order = 1), 'Refrigerator', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Devices') AND question_order = 1), 'Bicycle', false, 3);

-- Matching pairs for Technology
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Devices') AND question_order = 2), 'Computer', true, 1, 'tech1'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Devices') AND question_order = 2), 'Work and research', true, 2, 'tech1'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Devices') AND question_order = 2), 'Smartphone', true, 3, 'tech2'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Devices') AND question_order = 2), 'Communication', true, 4, 'tech2'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Devices') AND question_order = 2), 'Tablet', true, 5, 'tech3'),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Devices') AND question_order = 2), 'Reading and entertainment', true, 6, 'tech3');

-- Intermediate: Business English
INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation, conversation_context) VALUES
((SELECT id FROM lessons WHERE title = 'Business Meetings'), 'conversation', 'Manager: "What''s your opinion on the proposal?" You: "_____"', 1, 'Professional response in a meeting.', 'Business meeting discussion'),
((SELECT id FROM lessons WHERE title = 'Business Meetings'), 'fill_blank', 'We need to meet the ______ by Friday.', 2, 'A deadline is a time limit for completing something.');

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Business Meetings') AND question_order = 1), 'I think it''s a great opportunity for growth', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Business Meetings') AND question_order = 1), 'I like pizza', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Business Meetings') AND question_order = 1), 'The weather is nice', false, 3);

UPDATE lesson_questions SET correct_answer = 'deadline' 
WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Business Meetings') AND question_order = 2;

-- Advanced: Science Questions
INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation) VALUES
((SELECT id FROM lessons WHERE title = 'Natural Sciences'), 'multiple_choice', 'What is the study of living organisms called?', 1, 'Biology is the science of life and living organisms.'),
((SELECT id FROM lessons WHERE title = 'Natural Sciences'), 'fill_blank', 'The smallest unit of matter is an ______.', 2, 'An atom is the basic unit of a chemical element.');

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Natural Sciences') AND question_order = 1), 'Biology', true, 1),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Natural Sciences') AND question_order = 1), 'Geography', false, 2),
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Natural Sciences') AND question_order = 1), 'History', false, 3);

UPDATE lesson_questions SET correct_answer = 'atom' 
WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Natural Sciences') AND question_order = 2;

-- Translation questions using dictionary data
INSERT INTO lesson_questions (lesson_id, question_type, question_text, vietnamese_text, correct_answer, question_order, explanation) VALUES
((SELECT id FROM lessons WHERE title = 'Basic Colors'), 'translation', 'Translate: Màu đỏ', 'Màu đỏ', 'red', 4, 'Red is "đỏ" in Vietnamese.'),
((SELECT id FROM lessons WHERE title = 'Hot Drinks'), 'translation', 'Translate: Cà phê', 'Cà phê', 'coffee', 4, 'Coffee is a popular hot drink.'),
((SELECT id FROM lessons WHERE title = 'Fruits'), 'translation', 'Translate: Táo', 'Táo', 'apple', 4, 'Apple is a common fruit.');

COMMIT;

-- =====================================================
-- SUMMARY
-- =====================================================
-- Total Main Lessons: 38
-- Total Sub-Lessons: 114 (38 × 3 sub-lessons each)
-- 
-- Breakdown by Level:
-- - Beginner (A1-A2): 16 topics × 3 = 48 sub-lessons
-- - Elementary (A2-B1): 10 topics × 3 = 30 sub-lessons  
-- - Intermediate (B1-B2): 7 topics × 3 = 21 sub-lessons
-- - Advanced (B2-C1): 5 topics × 3 = 15 sub-lessons
--
-- Question Types Used:
-- - multiple_choice: Primary question type
-- - fill_blank: Text input questions
-- - matching: Pair matching exercises
-- - listening: Audio-based questions
-- - translation: Vietnamese ↔ English
-- - conversation: Dialog completion
--
-- Ready for integration with dictionary data from:
-- - vietnamese_headwords table
-- - english_headwords table
-- =====================================================
