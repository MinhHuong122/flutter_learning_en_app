-- Lessons table - stores lesson metadata (Course/Topic level)
CREATE TABLE lessons (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  created_at TIMESTAMP DEFAULT NOW(),
  title VARCHAR(255) NOT NULL,
  description TEXT,
  level VARCHAR(50), -- 'beginner', 'intermediate', 'advanced'
  lesson_type VARCHAR(50) NOT NULL, -- 'multiple_choice', 'listening', 'matching', 'fill_blank', 'conversation', 'repeat'
  thumbnail_url VARCHAR(255),
  duration_minutes INT,
  total_questions INT,
  parent_lesson_id UUID REFERENCES lessons(id) ON DELETE CASCADE, -- For sub-lessons/modules
  lesson_order INT DEFAULT 0 -- Order within parent
);

-- Lesson questions/exercises table
CREATE TABLE lesson_questions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  created_at TIMESTAMP DEFAULT NOW(),
  lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  question_type VARCHAR(50) NOT NULL DEFAULT 'multiple_choice', -- 'multiple_choice', 'fill_blank', 'matching', 'listening', 'translation', 'speaking', 'conversation'
  question_text TEXT NOT NULL,
  audio_url VARCHAR(255), -- URL to audio for listening/speaking exercises
  image_url VARCHAR(255), -- URL to image for visual questions
  question_order INT NOT NULL,
  explanation TEXT,
  correct_answer TEXT, -- For fill_blank, translation, speaking questions
  vietnamese_text TEXT, -- For translation exercises
  conversation_context TEXT, -- For conversation exercises (dialog context)
  points INT DEFAULT 10, -- Points awarded for correct answer
  UNIQUE(lesson_id, question_order)
);

-- Lesson options/answers for multiple choice and matching questions
CREATE TABLE lesson_options (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  created_at TIMESTAMP DEFAULT NOW(),
  question_id UUID NOT NULL REFERENCES lesson_questions(id) ON DELETE CASCADE,
  option_text TEXT NOT NULL,
  option_image_url VARCHAR(255), -- For image-based options
  is_correct BOOLEAN DEFAULT FALSE,
  option_order INT NOT NULL,
  explanation TEXT,
  match_pair_id VARCHAR(50) -- For matching exercises, identifies pairs
);

-- User progress tracking
CREATE TABLE user_lesson_progress (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  created_at TIMESTAMP DEFAULT NOW(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  completed BOOLEAN DEFAULT FALSE,
  progress_percentage INT DEFAULT 0,
  correct_answers INT DEFAULT 0,
  total_attempts INT DEFAULT 0,
  last_attempted TIMESTAMP,
  UNIQUE(user_id, lesson_id)
);

-- User answers to track learning history
CREATE TABLE user_answers (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  created_at TIMESTAMP DEFAULT NOW(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  question_id UUID NOT NULL REFERENCES lesson_questions(id) ON DELETE CASCADE,
  selected_option_id UUID REFERENCES lesson_options(id),
  is_correct BOOLEAN,
  answer_text TEXT -- For text-based answers
);

-- Enable RLS (Row Level Security)
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_lesson_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_answers ENABLE ROW LEVEL SECURITY;

-- RLS Policies for lessons (readable by anyone)
CREATE POLICY "Lessons are viewable by all" ON lessons FOR SELECT USING (true);

-- RLS Policies for lesson_questions (readable by anyone)
CREATE POLICY "Questions are viewable by all" ON lesson_questions FOR SELECT USING (true);

-- RLS Policies for lesson_options (readable by anyone)
CREATE POLICY "Options are viewable by all" ON lesson_options FOR SELECT USING (true);

-- RLS Policies for user_lesson_progress (users can only see their own)
CREATE POLICY "Users can view own progress" ON user_lesson_progress FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own progress" ON user_lesson_progress FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own progress" ON user_lesson_progress FOR UPDATE USING (auth.uid() = user_id);

-- RLS Policies for user_answers (users can only see their own)
CREATE POLICY "Users can view own answers" ON user_answers FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own answers" ON user_answers FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Create indexes for performance
CREATE INDEX idx_lesson_questions_lesson_id ON lesson_questions(lesson_id);
CREATE INDEX idx_lesson_options_question_id ON lesson_options(question_id);
CREATE INDEX idx_user_progress_user_id ON user_lesson_progress(user_id);
CREATE INDEX idx_user_progress_lesson_id ON user_lesson_progress(lesson_id);
CREATE INDEX idx_user_answers_user_id ON user_answers(user_id);
CREATE INDEX idx_user_answers_question_id ON user_answers(question_id);
