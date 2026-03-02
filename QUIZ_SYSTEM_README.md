# Hệ Thống Quiz Đa Dạng - Multi-Type Quiz System

## Tổng Quan / Overview

Hệ thống quiz mới cho phép tạo nhiều loại câu hỏi khác nhau để tăng tính tương tác và hiệu quả học tập.

The new quiz system supports multiple question types for enhanced learning experience.

---

## Các Loại Câu Hỏi / Question Types

### 1. Multiple Choice (Chọn đáp án)
- Câu hỏi truyền thống với nhiều lựa chọn
- Hỗ trợ hình ảnh cho từng đáp án
- Hiển thị giải thích sau khi trả lời

**Database:**
```sql
question_type = 'multiple_choice'
```

### 2. Fill in the Blank (Điền vào chỗ trống)
- Người học nhập câu trả lời tự do
- So sánh không phân biệt hoa thường
- Hiển thị đáp án đúng nếu sai

**Database:**
```sql
question_type = 'fill_blank'
correct_answer = 'đáp án đúng'
```

### 3. Matching (Nối cặp)
- Ghép các từ/cụm từ tương ứng
- Hỗ trợ song ngữ Anh-Việt
- Kiểm tra tất cả các cặp

**Database:**
```sql
question_type = 'matching'
-- Options có match_pair_id giống nhau tạo thành 1 cặp
match_pair_id = 'pair1', 'pair1' (2 options cùng pair)
```

### 4. Listening (Nghe)
- Phát audio câu hỏi
- Chọn đáp án sau khi nghe
- Có thể nghe lại nhiều lần

**Database:**
```sql
question_type = 'listening'
audio_url = 'link_to_audio_file'
```

### 5. Translation (Dịch)
- Dịch từ tiếng Việt sang tiếng Anh hoặc ngược lại
- Nhập câu trả lời tự do
- Hiển thị văn bản gốc và dịch

**Database:**
```sql
question_type = 'translation'
vietnamese_text = 'văn bản tiếng Việt'
correct_answer = 'English translation'
```

### 6. Conversation (Hội thoại)
- Câu hỏi trong ngữ cảnh hội thoại
- Hiển thị context của cuộc trò chuyện
- Chọn câu trả lời phù hợp

**Database:**
```sql
question_type = 'conversation'
conversation_context = 'At a restaurant'
-- Thêm options như multiple choice
```

---

## Cấu Trúc Database / Database Structure

### Bảng `lesson_questions`

| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Primary key |
| lesson_id | UUID | ID bài học |
| question_type | VARCHAR(50) | Loại câu hỏi |
| question_text | TEXT | Nội dung câu hỏi |
| audio_url | VARCHAR(255) | Link audio (optional) |
| image_url | VARCHAR(255) | Link hình ảnh (optional) |
| correct_answer | TEXT | Đáp án đúng (fill_blank, translation) |
| vietnamese_text | TEXT | Văn bản tiếng Việt (translation) |
| conversation_context | TEXT | Ngữ cảnh hội thoại |
| points | INT | Điểm thưởng (default: 10) |
| question_order | INT | Thứ tự câu hỏi |
| explanation | TEXT | Giải thích đáp án |

### Bảng `lesson_options`

| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Primary key |
| question_id | UUID | ID câu hỏi |
| option_text | TEXT | Nội dung lựa chọn |
| option_image_url | VARCHAR(255) | Hình ảnh đáp án (optional) |
| is_correct | BOOLEAN | Đáp án đúng? |
| option_order | INT | Thứ tự hiển thị |
| match_pair_id | VARCHAR(50) | ID cặp nối (matching) |

---

## Ví Dụ / Examples

### Multiple Choice
```sql
INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation)
VALUES ('lesson-id', 'multiple_choice', 'What color is the sky?', 1, 'The sky is blue');

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order)
VALUES 
  ('question-id', 'Blue', true, 1),
  ('question-id', 'Green', false, 2),
  ('question-id', 'Red', false, 3);
```

### Fill Blank
```sql
INSERT INTO lesson_questions (lesson_id, question_type, question_text, correct_answer, question_order)
VALUES ('lesson-id', 'fill_blank', 'The grass is ______.', 'green', 2);
```

### Matching
```sql
INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order)
VALUES ('lesson-id', 'matching', 'Match English-Vietnamese colors', 3);

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id)
VALUES 
  ('question-id', 'Red', true, 1, 'pair1'),
  ('question-id', 'Màu đỏ', true, 2, 'pair1'),
  ('question-id', 'Blue', true, 3, 'pair2'),
  ('question-id', 'Màu xanh', true, 4, 'pair2');
```

### Translation
```sql
INSERT INTO lesson_questions (lesson_id, question_type, question_text, vietnamese_text, correct_answer, question_order)
VALUES ('lesson-id', 'translation', 'Translate to English:', 'Xin chào', 'Hello', 4);
```

### Conversation
```sql
INSERT INTO lesson_questions (lesson_id, question_type, question_text, conversation_context, question_order)
VALUES ('lesson-id', 'conversation', 'A: "How are you?" B: "_____"', 'Greeting someone', 5);

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order)
VALUES 
  ('question-id', 'I am fine, thank you', true, 1),
  ('question-id', 'Yes, please', false, 2);
```

---

## Cách Sử Dụng / How to Use

### 1. Migration Database
Nếu đã có database, chạy migration:
```sql
-- Run the migration script
\i DATABASE_MIGRATION_QUIZ_TYPES.sql
```

### 2. Tạo Database Mới
Nếu tạo mới:
```sql
-- Run schema first
\i DATABASE_SCHEMA.sql

-- Then run sample data
\i DATABASE_SAMPLE_DATA.sql
```

### 3. Trong App

#### Điều hướng đến Quiz Screen:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => QuizScreen(
      lesson: lesson,
      onComplete: (completed) {
        // Handle completion
      },
    ),
  ),
);
```

#### Quiz tự động hiển thị đúng loại câu hỏi dựa vào `question_type`

---

## Tính Năng / Features

✅ 6 loại câu hỏi đa dạng
✅ Hỗ trợ hình ảnh & audio
✅ Giải thích chi tiết sau mỗi câu
✅ Theo dõi điểm số realtime
✅ Màn hình kết quả đẹp mắt
✅ Hỗ trợ song ngữ Anh-Việt
✅ Progress tracking
✅ Retry functionality
✅ Tích hợp với lesson progression system

---

## UI/UX

- **Question Type Badge**: Hiển thị loại câu hỏi với màu riêng
- **Audio Button**: Nút phát audio cho listening questions
- **Progress Bar**: Thanh tiến trình ở đầu màn hình
- **Score Display**: Hiển thị điểm realtime
- **Explanation Card**: Giải thích xuất hiện sau khi trả lời
- **Result Screen**: Màn hình kết quả với thống kê chi tiết

---

## Màu Sắc Theo Loại / Colors by Type

| Type | Color | Hex |
|------|-------|-----|
| Multiple Choice | Indigo | #818CF8 |
| Fill Blank | Amber | #F59E0B |
| Matching | Green | #34D399 |
| Listening | Teal | #14B8A6 |
| Translation | Pink | #F472B6 |
| Conversation | Blue | #60A5FA |

---

## Notes

- Tất cả câu hỏi đều có giải thích để tăng hiệu quả học tập
- Fill blank và translation không phân biệt hoa/thường
- Matching yêu cầu ghép đủ tất cả các cặp
- Có thể thêm points tùy chỉnh cho mỗi câu hỏi
- Hỗ trợ retry để học lại

---

## Cập Nhật Tiếp Theo / Future Updates

- [ ] Speaking questions với speech recognition
- [ ] Timed quizzes
- [ ] Hints system
- [ ] Adaptive difficulty
- [ ] Multiplayer quizzes
- [ ] Leaderboard integration

---

Hệ thống này giúp tạo trải nghiệm học tập đa dạng và hấp dẫn hơn cho người dùng! 🚀
