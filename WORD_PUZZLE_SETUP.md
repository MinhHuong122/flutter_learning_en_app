# Hướng dẫn Setup Supabase Word Puzzle Database

## 📋 Tóm tắt thay đổi

### ✅ Đã tạo:
1. **Supabase Table**: `word_puzzle_questions` với 10 levels (50+ câu hỏi)
2. **Input-based Interface**: Thay đổi từ **kéo thả** → **gõ từ**
3. **Vietnamese Clues**: Mỗi câu hỏi có gợi ý tiếng Việt
4. **Real-time Validation**: Tự động kiểm tra đáp án khi gõ

---

## 🚀 Hướng dẫn Setup

### Step 1: Copy SQL Script
Tệp SQL đã tạo: `CREATE_WORD_PUZZLE_TABLE.sql`

### Step 2: Mở Supabase Dashboard
1. Vào https://app.supabase.com
2. Chọn project: "ypckcxhrbyfpsutzhdho" 
3. Tìm **SQL Editor**

### Step 3: Chạy SQL Script
1. Mở `CREATE_WORD_PUZZLE_TABLE.sql` từ workspace
2. Copy toàn bộ SQL code
3. Paste vào Supabase SQL Editor
4. Click "RUN"

### Step 4: Verify Data
1. Vào **Table Editor** trong Supabase dashboard
2. Kiểm tra table `word_puzzle_questions`
3. Xác nhận có ~50 rows (10 levels × 5 questions mỗi level)

---

## 📱 Tính năng mới

### Giao diện:
```
Level 1
┌─────────────────────────────┐
│ 1. Across                   │  ✓ (Check icon)
│ Thịt từ lợn                 │
│ [Input field: PORK]         │
└─────────────────────────────┘

┌─────────────────────────────┐
│ 2. Across                   │  ✗ (Wrong)
│ Thịt từ bò                  │
│ [Input field: ]             │
└─────────────────────────────┘
```

### Tính năng:
- ✅ Real-time validation (tự động check khi gõ)
- ✅ Show check/cross icon cho đúng/sai
- ✅ Disable input khi gõ đúng
- ✅ Vietnamese clues (Tiếng Việt)
- ✅ Check Answers button
- ✅ Next Level button (full screen)

---

## 🔄 Data Flow

```
ExerciseScreen
    ↓
WordQuestionsService.getQuestionsForLevel(levelNumber)
    ↓
Supabase: SELECT * FROM word_puzzle_questions WHERE level_number = 1
    ↓
WordQuestion.fromJson() - handle snake_case (Supabase)
    ↓
WordPuzzleGame → Show text input fields
    ↓
User types answer
    ↓
Real-time validation
    ↓
Check Answers button for final check
```

---

## 💾 Database Schema

```sql
CREATE TABLE word_puzzle_questions (
  id BIGINT (Primary Key)
  level_number INT (1-10)
  word VARCHAR (English word)
  question VARCHAR (Vietnamese clue)
  hint VARCHAR (English hint)
  start_row INT
  start_col INT
  direction VARCHAR ('across' or 'down')
  question_number INT (1, 2, 3...)
  image_url VARCHAR (optional)
  created_at TIMESTAMP
  updated_at TIMESTAMP
)
```

---

## 🔧 Nếu gặp lỗi

### Error: "Table not found"
→ Chạy CREATE_WORD_PUZZLE_TABLE.sql lại

### Error: "No data for level 1"
→ Kiểm tra:
  - Supabase connection (check .env SUPABASE_URL + SUPABASE_ANON_KEY)
  - Data đã được insert
  - level_number column có dữ liệu

### Input field không responsive
→ Hot reload app (R key trong terminal)

---

## 📝 Thêm câu hỏi mới

Có 2 cách:

### Cách 1: SQL Insert (nhanh)
```sql
INSERT INTO word_puzzle_questions 
(level_number, word, question, hint, start_row, start_col, direction, question_number)
VALUES 
(1, 'FISH', 'Con cá', 'Fish - aquatic animal', 5, 2, 'across', 7);
```

### Cách 2: Supabase Dashboard UI
1. Table Editor → word_puzzle_questions
2. Click "+ Insert row"
3. Điền dữ liệu

---

## ✨ Tiếp theo

- [ ] Thêm images cho lớp high level (lesson_number > 5)
- [ ] Thêm timer (challenge mode)
- [ ] Lưu progress (favorite levels, best times)
- [ ] Admin interface (admin_panel_screen.dart) để add/edit questions

---

**Status**: ✅ Ready to use  
**UV Coverage**: Levels 1-10, 50 questions  
**Last Updated**: 2026-04-14
