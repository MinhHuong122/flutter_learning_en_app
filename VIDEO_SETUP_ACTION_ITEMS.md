# 📺 Video Embedding - Immediate Action Items

## Problem
Videos are not showing in the course banner, only placeholder icon appears.

## Root Causes (Most to Least Likely)
1. ❌ **Database column `video_url` doesn't exist or migration not applied**
2. ❌ **Video URLs not yet inserted into database** 
3. ❌ **App not rebuilt after database changes**
4. ❌ **WebView not loading properly**

## ✅ Verification Checklist (Do These First)

### 1. Check Database Column & Data (Most Important!)
```sql
-- In Supabase SQL Editor, run this:
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'lessons' AND column_name = 'video_url';
```
- **If empty result** → Column doesn't exist yet
- **If column exists** → Run step 2

### 2. Check if Videos Are in Database
```sql
-- Show lessons with videos
SELECT id, title, video_url FROM lessons 
WHERE video_url IS NOT NULL LIMIT 5;
```
- **If empty result** → Videos not inserted yet
- **If data shows** → Go to step 3

### 3. Insert the Videos (Run Your SQL Statements)
Copy-paste ALL your UPDATE statements from the user request and execute in Supabase:
```sql
UPDATE public.lessons SET video_url = 'https://www.youtube.com/embed/njDKi7dDOq4' WHERE id = '2c850dc5-d7e0-4325-bb1b-1197f2795654';
UPDATE public.lessons SET video_url = 'https://www.youtube.com/embed/01AWUd1ySZs' WHERE id = '859a1e12-e633-40e5-b4e2-b7e9dfd2a7d7';
-- ... (all remaining lessons)
```

### 4. Rebuild the App
```bash
cd d:\DHV\Year4\Semester2\DoAn\app_learn_english
flutter clean
flutter pub get
flutter run
```
**IMPORTANT:** `flutter clean` is essential after database schema changes!

### 5. Check Debug Console
When app loads, look for these messages in the Flutter console:
```
✅ VIDEO BANNER: Extracted videoId = njDKi7dDOq4
✅ VIDEO BANNER: WebView loaded successfully
```

## Files Updated
- ✅ [lesson_detail_screen.dart](lib/screens/lesson_detail_screen.dart) - Added debug logging
- ✅ [addition_video_url_to_lessons.sql](migrations/add_video_url_to_lessons.sql) - Migration file
- ✅ [VIDEO_NOT_SHOWING_HELP.md](VIDEO_NOT_SHOWING_HELP.md) - Full troubleshooting guide

## Timeline
1. **Verify database** - 2 minutes
2. **Run SQL updates** - 1 minute
3. **Rebuild app** - 5-10 minutes
4. **Test in app** - 2 minutes

**Total: ~15-20 minutes**

## Expected Result
When you open any lesson in the app:
- Course banner should show **embedded YouTube player** instead of play icon
- Video player should show YouTube controls (play, pause, fullscreen, etc.)
- Video should be interactive and functional

## If Still Not Working
1. See [VIDEO_NOT_SHOWING_HELP.md](VIDEO_NOT_SHOWING_HELP.md) for detailed troubleshooting
2. Run [verify_video_setup.sql](verify_video_setup.sql) to diagnose database issues
3. Check console with: `flutter run -v 2>&1 | grep -i video`
