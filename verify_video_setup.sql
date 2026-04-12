-- DIAGNOSIS: Check video_url implementation status
-- Run this script in Supabase SQL Editor to verify everything is set up

-- ===== CHECK 1: Column exists in database =====
SELECT 
  'COLUMN_EXISTS' as check_name,
  (EXISTS(
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'lessons' AND column_name = 'video_url'
  ))::text as status
UNION ALL

-- ===== CHECK 2: Count lessons with video URLs =====
SELECT 
  'LESSONS_WITH_VIDEO' as check_name,
  (SELECT COUNT(*) FROM lessons WHERE video_url IS NOT NULL)::text as status
UNION ALL

-- ===== CHECK 3: Total lessons in database =====
SELECT 
  'TOTAL_LESSONS' as check_name,
  (SELECT COUNT(*) FROM lessons)::text as status
UNION ALL

-- ===== CHECK 4: Sample video URLs =====
SELECT 
  'SAMPLE_DATA' as check_name,
  COALESCE((SELECT STRING_AGG(title || ': ' || video_url, ' | ') 
   FROM (SELECT title, video_url FROM lessons WHERE video_url IS NOT NULL LIMIT 3)), 'No videos yet')::text as status;

-- ===== DETAILED: Show lessons with videos =====
-- Uncomment to see full list of lessons with video URLs
-- SELECT id, title, video_url, created_at FROM lessons WHERE video_url IS NOT NULL ORDER BY created_at DESC;

-- ===== DETAILED: Show lessons WITHOUT videos =====
-- Uncomment to see which lessons still need videos
-- SELECT id, title, video_url FROM lessons WHERE video_url IS NULL ORDER BY created_at LIMIT 10;
