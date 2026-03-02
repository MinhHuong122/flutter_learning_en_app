# Complete Database Setup Guide - 100+ Lessons

## 📚 Tổng Quan / Overview

Hệ thống học tiếng Anh hoàn chỉnh với **114 bài học** phân theo 4 cấp độ từ Beginner đến Advanced, tận dụng dữ liệu từ dictionary có sẵn.

## 📊 Cấu Trúc Dữ Liệu / Data Structure

### Tổng Số Bài Học / Total Lessons

| Cấp Độ | Main Topics | Sub-Lessons | Tổng Questions |
|---------|-------------|-------------|----------------|
| **Beginner (A1-A2)** | 16 | 48 | ~288 |
| **Elementary (A2-B1)** | 10 | 30 | ~180 |
| **Intermediate (B1-B2)** | 7 | 21 | ~126 |
| **Advanced (B2-C1)** | 5 | 15 | ~90 |
| **TỔNG CỘNG** | **38** | **114** | **~684** |

---

## 🗂️ Các File Quan Trọng / Important Files

### 1. Schema & Structure
- **DATABASE_SCHEMA.sql** - Cấu trúc database cơ bản
- **dictionary_schema.sql** - Schema cho dictionary (Vietnamese & English)

### 2. Sample Data
- **DATABASE_SAMPLE_DATA.sql** - Dữ liệu mẫu ban đầu (6 topics cơ bản)
- **DATABASE_SAMPLE_DATA_EXTENDED.sql** - Dữ liệu mở rộng (114 bài học)
- **DATABASE_QUESTIONS_FULL.sql** - Câu hỏi chi tiết cho các bài

### 3. Migration
- **DATABASE_MIGRATION_QUIZ_TYPES.sql** - Migration cho DB hiện có

### 4. Auto-Generation
- **generate_questions_from_dictionary.py** - Script tự động tạo câu hỏi từ dictionary

---

## 🚀 Hướng Dẫn Setup / Setup Instructions

### Phương Án 1: Setup Database Mới (New Database)

```sql
-- Step 1: Create database structure
\i DATABASE_SCHEMA.sql

-- Step 2: Create dictionary tables
\i dictionary_schema.sql

-- Step 3: Import lesson data
\i DATABASE_SAMPLE_DATA_EXTENDED.sql

-- Step 4: Import detailed questions
\i DATABASE_QUESTIONS_FULL.sql

-- Step 5: (Optional) Generate more questions from dictionary
-- Run Python script first: python generate_questions_from_dictionary.py
\i DATABASE_DICTIONARY_QUESTIONS.sql
```

### Phương Án 2: Update Database Hiện Có (Existing Database)

```sql
-- Step 1: Run migration
\i DATABASE_MIGRATION_QUIZ_TYPES.sql

-- Step 2: Add new lessons
\i DATABASE_SAMPLE_DATA_EXTENDED.sql

-- Step 3: Add questions
\i DATABASE_QUESTIONS_FULL.sql
```

---

## 📖 Chi Tiết Các Chủ Đề / Topic Details

### 🟢 BEGINNER LEVEL (A1-A2) - 16 Topics

#### 1. **Alphabet - Bảng chữ cái**
- Basic Alphabet (6 questions)
- Vowels Practice (5 questions)
- Consonants Practice (8 questions)

#### 2. **Colors - Màu sắc**
- Basic Colors (6 questions)
- Color Descriptions (5 questions)
- Advanced Colors (6 questions)

#### 3. **Numbers - Số đếm**
- Numbers 1-20 (6 questions)
- Numbers 20-100 (5 questions)
- Large Numbers (5 questions)

#### 4. **Drinks - Đồ uống**
- Hot Drinks (5 questions)
- Cold Drinks (6 questions)
- Ordering Drinks (4 questions)

#### 5. **Food - Đồ ăn**
- Fruits (6 questions)
- Vegetables (6 questions)
- Meals & Dishes (5 questions)

#### 6. **Animals - Động vật**
- Pets (5 questions)
- Farm Animals (6 questions)
- Wild Animals (5 questions)

#### 7. **Family - Gia đình**
- Immediate Family (6 questions)
- Extended Family (6 questions)
- Family Conversations (4 questions)

#### 8. **Body Parts - Bộ phận cơ thể**
- Head & Face (6 questions)
- Body & Limbs (6 questions)
- Internal Organs (4 questions)

#### 9. **Clothes - Quần áo**
- Everyday Clothes (6 questions)
- Accessories (5 questions)
- Shopping for Clothes (4 questions)

#### 10. **Daily Activities - Hoạt động hàng ngày**
- Morning Routine (6 questions)
- Work & School Activities (5 questions)
- Evening Activities (5 questions)

#### 11. **Weather - Thời tiết**
- Weather Conditions (6 questions)
- Temperature (5 questions)
- Weather Talk (4 questions)

#### 12. **Seasons - Mùa**
- Spring & Summer (5 questions)
- Fall & Winter (5 questions)
- Seasonal Activities (4 questions)

#### 13. **Time - Thời gian**
- Clock Reading (6 questions)
- Time Expressions (5 questions)
- Asking About Time (4 questions)

#### 14. **Days & Months - Ngày tháng**
- Days of the Week (5 questions)
- Months of the Year (6 questions)
- Dates & Appointments (4 questions)

#### 15. **Places - Địa điểm**
- Public Places (6 questions)
- Shops & Stores (6 questions)
- Giving Directions (5 questions)

#### 16. **Transportation - Phương tiện**
- Land Transport (6 questions)
- Air & Water Transport (5 questions)
- Travel Conversations (5 questions)

---

### 🟡 ELEMENTARY LEVEL (A2-B1) - 10 Topics

#### 17. **House & Home - Nhà ở**
- Rooms in a House
- Furniture
- Household Chores

#### 18. **Shopping - Mua sắm**
- At the Store
- Online Shopping
- Payments & Returns

#### 19. **Hobbies - Sở thích**
- Indoor Hobbies
- Outdoor Activities
- Discussing Hobbies

#### 20. **Sports - Thể thao**
- Ball Sports
- Individual Sports
- Sports Talk

#### 21. **School & Education - Trường học**
- School Subjects
- Classroom Objects
- At School

#### 22. **Jobs & Occupations - Nghề nghiệp**
- Common Jobs
- Job Descriptions
- Job Interview

#### 23. **Health & Medicine - Sức khỏe**
- Common Illnesses
- At the Doctor
- Healthy Living

#### 24. **Feelings & Emotions - Cảm xúc**
- Basic Emotions
- Complex Feelings
- Expressing Feelings

#### 25. **Travel & Tourism - Du lịch**
- At the Airport
- Hotel Accommodation
- Tourist Attractions

#### 26. **Technology - Công nghệ**
- Devices
- Internet & Social Media
- Tech Problems

---

### 🟠 INTERMEDIATE LEVEL (B1-B2) - 7 Topics

#### 27. **Business English - Tiếng Anh thương mại**
- Business Vocabulary
- Email Writing
- Business Meetings

#### 28. **Environment - Môi trường**
- Climate Change
- Pollution
- Sustainability

#### 29. **Culture & Customs - Văn hóa**
- Festivals & Holidays
- Social Etiquette
- Cultural Comparison

#### 30. **Current Events - Sự kiện**
- News Vocabulary
- Reading News
- Discussing News

#### 31. **Entertainment - Giải trí**
- Movies & Cinema
- Music & Concerts
- Entertainment Discussion

#### 32. **Relationships - Quan hệ**
- Friendship
- Dating & Romance
- Conflict Resolution

#### 33. **Money & Banking - Tài chính**
- Banking Services
- Personal Finance
- At the Bank

---

### 🔴 ADVANCED LEVEL (B2-C1) - 5 Topics

#### 34. **Politics & Government - Chính trị**
- Political Systems
- Elections & Voting
- Political Debate

#### 35. **Science & Innovation - Khoa học**
- Natural Sciences
- Technology Innovation
- Scientific Discussion

#### 36. **Philosophy & Ethics - Triết học**
- Philosophical Schools
- Ethics & Morality
- Philosophical Debate

#### 37. **Literature & Arts - Văn học**
- Literary Genres
- Art Movements
- Literary Analysis

#### 38. **Economics - Kinh tế**
- Economic Systems
- Market Forces
- Economic Discussion

---

## 🎯 Các Loại Câu Hỏi / Question Types

### 1. Multiple Choice (Chọn đáp án)
```sql
question_type = 'multiple_choice'
-- Has 3-4 options via lesson_options table
```

### 2. Fill in the Blank (Điền vào chỗ trống)
```sql
question_type = 'fill_blank'
correct_answer = 'answer text'
```

### 3. Matching (Nối cặp)
```sql
question_type = 'matching'
-- Options have match_pair_id grouping pairs
```

### 4. Listening (Nghe)
```sql
question_type = 'listening'
audio_url = 'path/to/audio.mp3'
```

### 5. Translation (Dịch)
```sql
question_type = 'translation'
vietnamese_text = 'Vietnamese source'
correct_answer = 'English translation'
```

### 6. Conversation (Hội thoại)
```sql
question_type = 'conversation'
conversation_context = 'At a restaurant'
-- Has multiple choice options for responses
```

---

## 🔧 Tạo Câu Hỏi Tự Động / Auto-Generate Questions

### Sử dụng Python Script

```bash
# Install if needed
pip install csv

# Run generator
python generate_questions_from_dictionary.py

# Import generated SQL
psql -U your_user -d your_db -f DATABASE_DICTIONARY_QUESTIONS.sql
```

### Customize Generation

```python
from generate_questions_from_dictionary import QuestionGenerator

generator = QuestionGenerator()
generator.load_dictionary_data()

# Generate for specific lesson
questions = generator.generate_translation_questions('Fruits', count=10)
questions.extend(generator.generate_matching_questions('Fruits', pairs_count=5))

generator.export_to_sql(questions, 'custom_questions.sql')
```

---

## 📊 Thống Kê / Statistics

### Question Distribution

| Question Type | Estimated Count | Percentage |
|---------------|-----------------|------------|
| Multiple Choice | ~250 | 36% |
| Fill Blank | ~180 | 26% |
| Matching | ~114 | 17% |
| Translation | ~80 | 12% |
| Conversation | ~40 | 6% |
| Listening | ~20 | 3% |
| **TOTAL** | **~684** | **100%** |

### Difficulty Distribution

| Level | Sub-Lessons | Avg Questions/Lesson | Total Questions |
|-------|-------------|----------------------|-----------------|
| Beginner | 48 | 6 | ~288 |
| Elementary | 30 | 6 | ~180 |
| Intermediate | 21 | 6 | ~126 |
| Advanced | 15 | 6 | ~90 |

---

## 🎨 Tính Năng Đặc Biệt / Special Features

### ✅ Đã Implement
- [x] 6 loại câu hỏi đa dạng
- [x] 114 bài học theo cấp độ
- [x] Tích hợp dictionary data
- [x] Auto-generation script
- [x] Bilingual support (EN-VI)
- [x] Progress tracking
- [x] Points system
- [x] Explanation cho mỗi câu

### 🔄 Có Thể Mở Rộng
- [ ] Audio files cho listening
- [ ] Images cho visual questions
- [ ] Video lessons
- [ ] Spaced repetition
- [ ] Adaptive difficulty
- [ ] Pronunciation scoring
- [ ] Speaking practice với voice recognition

---

## 🔍 Query Examples

### Get All Beginner Lessons
```sql
SELECT l.title, COUNT(sq.id) as sub_lesson_count
FROM lessons l
LEFT JOIN lessons sq ON sq.parent_lesson_id = l.id
WHERE l.level = 'beginner' AND l.parent_lesson_id IS NULL
GROUP BY l.id, l.title
ORDER BY l.lesson_order;
```

### Get Questions for a Specific Lesson
```sql
SELECT 
  lq.question_text,
  lq.question_type,
  lq.correct_answer,
  lq.explanation
FROM lesson_questions lq
JOIN lessons l ON lq.lesson_id = l.id
WHERE l.title = 'Basic Colors'
ORDER BY lq.question_order;
```

### Get Question with Options
```sql
SELECT 
  lq.question_text,
  lo.option_text,
  lo.is_correct
FROM lesson_questions lq
JOIN lesson_options lo ON lo.question_id = lq.id
WHERE lq.id = 'question-uuid'
ORDER BY lo.option_order;
```

### Track User Progress
```sql
SELECT 
  l.title,
  ulp.progress_percentage,
  ulp.correct_answers,
  ulp.total_attempts
FROM user_lesson_progress ulp
JOIN lessons l ON ulp.lesson_id = l.id
WHERE ulp.user_id = 'user-uuid'
ORDER BY ulp.last_attempted DESC;
```

---

## 🚨 Lưu Ý Quan Trọng / Important Notes

1. **Character Encoding**: Đảm bảo database dùng UTF-8 để hỗ trợ tiếng Việt
2. **Foreign Keys**: Các bảng có quan hệ CASCADE DELETE để tránh orphan records
3. **Indexes**: Đã tạo index cho performance, nhưng có thể thêm tùy theo usage patterns
4. **RLS Policies**: Row Level Security đã enable cho user data privacy
5. **Audio URLs**: Cần thêm actual audio files và update audio_url fields
6. **Images**: Tương tự audio, cần upload images và update image_url fields

---

## 🔗 Integration với Flutter App

### Fetch Lessons
```dart
final lessons = await supabase
  .from('lessons')
  .select('*, parent_lesson:parent_lesson_id(*)')
  .eq('level', 'beginner')
  .order('lesson_order');
```

### Fetch Questions
```dart
final questions = await supabase
  .from('lesson_questions')
  .select('*, options:lesson_options(*)')
  .eq('lesson_id', lessonId)
  .order('question_order');
```

### Save Progress
```dart
await supabase.from('user_lesson_progress').upsert({
  'user_id': userId,
  'lesson_id': lessonId,
  'completed': true,
  'progress_percentage': 100,
  'correct_answers': correctCount,
  'total_attempts': totalAttempts,
  'last_attempted': DateTime.now().toIso8601String()
});
```

---

## 📞 Support & Contribution

Để thêm nhiều lessons hơn:
1. Follow cấu trúc trong `DATABASE_SAMPLE_DATA_EXTENDED.sql`
2. Sử dụng `generate_questions_from_dictionary.py` để tạo questions
3. Test trong local database trước
4. Upload lên production sau khi verify

---

## 📝 Version History

- **v1.0** - Basic 6 topics with simple questions
- **v2.0** - Extended to 114 lessons with 6 question types
- **v2.1** - Added dictionary integration and auto-generation script
- **v2.2** - Current version with full documentation

---

**🎉 Chúc bạn build app học tiếng Anh thành công!**
