-- Migration: Add video_url column to lessons table
-- Purpose: Store YouTube video URLs for course banners

ALTER TABLE public.lessons
ADD COLUMN video_url character varying(500) NULL;

-- Add comment for documentation
COMMENT ON COLUMN public.lessons.video_url IS 'YouTube video URL for the lesson banner';

-- Create index for faster filtering
CREATE INDEX idx_lessons_video_url ON public.lessons(video_url) WHERE video_url IS NOT NULL;
