# Quick Start: Add Lessons to Your App

## Fastest Way to Get Started

### 1. Copy SQL Schema
- Open `DATABASE_SCHEMA.sql` file in this project
- Go to Supabase → SQL Editor
- Paste all the code and click **Run**
- This creates all tables with proper indexes and security policies

### 2. Add Sample Lessons (Optional)
- Open `DATABASE_SAMPLE_DATA.sql` file in this project
- Go to Supabase → SQL Editor
- Paste all the code and click **Run**
- Now you'll have sample lessons to test with!

### 3. Run Your App
```bash
flutter pub get
flutter run
```

### 4. Now Check It Out!
- Go to Home Screen → Look for "Lessons" section
- Click on a lesson card to start learning!
- Click "See All" to browse all lessons by level and type

---

## Add Your Own Lessons (Simple Method)

### Step 1: Add a Lesson
Go to Supabase → SQL Editor and run:
```sql
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions) 
VALUES (
  'Animals Vocabulary',           -- Your lesson title
  'Learn names of common animals', -- Description
  'beginner',                     -- Level: beginner, intermediate, advanced
  'multiple_choice',              -- Type: multiple_choice, listening, matching, etc.
  10,                             -- Duration in minutes
  5                               -- Number of questions
);
```

### Step 2: Get Your Lesson ID
```sql
SELECT id FROM lessons WHERE title = 'Animals Vocabulary' LIMIT 1;
```
Copy the ID (it looks like: `12345678-1234-1234-1234-123456789012`)

### Step 3: Add Questions
```sql
INSERT INTO lesson_questions (lesson_id, question_text, question_order, explanation) 
VALUES (
  'YOUR_LESSON_ID',                   -- Paste your ID here
  'What animal says meow?',            -- The question
  1,                                  -- Question order (1, 2, 3...)
  'A cat makes the sound meow'        -- Explanation
);
```

Repeat for each question (change question_order to 2, 3, 4, etc.)

### Step 4: Get Question ID
```sql
SELECT id FROM lesson_questions WHERE lesson_id = 'YOUR_LESSON_ID' ORDER BY question_order;
```

### Step 5: Add Answer Options
```sql
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) 
VALUES 
  ('QUESTION_1_ID', 'Cat', true, 1),         -- true = correct answer
  ('QUESTION_1_ID', 'Dog', false, 2),
  ('QUESTION_1_ID', 'Bird', false, 3);
```

Done! Your lesson is ready to use! 🎉

---

## Example: Complete Lesson in SQL

```sql
-- Create lesson
INSERT INTO lessons (title, description, level, lesson_type, duration_minutes, total_questions) 
VALUES ('Greetings', 'Learn basic English greetings', 'beginner', 'multiple_choice', 8, 3);

-- Get the lesson ID (you'll see it in the result below)
-- Copy this ID for the next queries

-- Add questions
INSERT INTO lesson_questions (lesson_id, question_text, question_order, explanation) 
VALUES 
  ('LESSON_ID', 'How do you greet someone in the morning?', 1, 'Good morning is the most common greeting.'),
  ('LESSON_ID', 'What do you say when leaving?', 2, 'Goodbye is used when leaving.'),
  ('LESSON_ID', 'How do you ask how someone is?', 3, 'How are you? is a polite greeting question.');

-- Get question IDs
-- Copy each ID for the next queries

-- Add options for Question 1
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) 
VALUES 
  ('Q1_ID', 'Good morning', true, 1),
  ('Q1_ID', 'Good night', false, 2),
  ('Q1_ID', 'Good afternoon', false, 3);

-- Add options for Question 2
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) 
VALUES 
  ('Q2_ID', 'Goodbye', true, 1),
  ('Q2_ID', 'Hello', false, 2),
  ('Q2_ID', 'Thanks', false, 3);

-- Add options for Question 3
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) 
VALUES 
  ('Q3_ID', 'How are you?', true, 1),
  ('Q3_ID', 'Where are you?', false, 2),
  ('Q3_ID', 'What are you?', false, 3);
```

---

## Lesson Types Explained

### 1. **Multiple Choice** (most popular)
Users choose from 3-4 options:
```
Question: What does "hello" mean?
A) Greeting  ← Correct
B) Goodbye
C) Thanks
```

### 2. **Listening**
Users listen and answer about what they heard:
```
[Audio plays character introduction]
Question: What is the person's name?
Options: John, Jane, Jeff, etc.
```

### 3. **Matching**
Users match pairs of words/phrases:
```
Left side          Right side
Cat        ←→   A household pet
Dog        ←→   A greeting
Hello      ←→   A large animal
```

### 4. **Fill Blank**
Users fill in missing words:
```
"_____ you?" (Answer: How are)
"Good _____" (Answer: morning)
```

### 5. **Conversation**
Users complete a dialogue:
```
A: Hello! How are you?
B: _____ (Complete the response)
```

### 6. **Repeat**
Users practice pronunciation:
```
Listen to: "Beautiful"
User reads it aloud (TTS evaluates similarity)
```

---

## Best Practices for Creating Lessons

1. **Keep Questions Simple**: One concept per question
2. **Balanced Difficulty**: Mix easy, medium, hard questions
3. **Clear Explanations**: Always explain why the answer is correct
4. **Realistic Examples**: Use actual English you'd use in real life
5. **Varied Options**: Wrong answers should be plausible but clearly wrong

Example bad question:
```
What is the capital of France?
A) Paris
B) Banana  ← Too obvious wrong answer
C) Car
```

Example better question:
```
What is the capital of France?
A) Paris   ← Correct
B) Lyon    ← Close but wrong
C) Marseille ← Close but wrong
```

---

## Viewing Your Data

### Check Lessons
```sql
SELECT * FROM lessons;
```

### Check Questions for a Lesson
```sql
SELECT * FROM lesson_questions 
WHERE lesson_id = 'YOUR_LESSON_ID'
ORDER BY question_order;
```

### Check User Progress
```sql
SELECT * FROM user_lesson_progress 
WHERE user_id = 'YOUR_USER_ID';
```

### Check Answers History
```sql
SELECT * FROM user_answers 
WHERE user_id = 'YOUR_USER_ID'
ORDER BY created_at DESC;
```

---

## Troubleshooting

### "Error: Insert failed" 
- Make sure lesson_id/question_id is correctly formatted UUID
- Check spelling of table names
- Verify all required fields are provided

### "No lessons showing in app"
- Run the schema SQL first
- Check if lessons were actually inserted: `SELECT * FROM lessons;`
- Verify Supabase connection is working

### "Can't edit lesson after creating"
- Lessons are immutable for data integrity
- Delete and recreate if needed
- Use: `DELETE FROM lessons WHERE id = 'LESSON_ID';` (cascades to questions/options)

---

## Need Help?

1. Check `LESSONS_SETUP_GUIDE.md` for detailed information
2. Review the example SQL files in the project
3. Check Supabase documentation: https://supabase.com/docs

Now go create awesome English lessons! 🚀
