# ⚡ QUICK START: Fix Video Not Showing

## 🎯 Do This NOW (5 minutes)

### Step 1: Open Supabase Dashboard
1. Go to: https://supabase.com
2. Click your project
3. Go to **SQL Editor**

### Step 2: Run Verification Query
Copy & paste this:
```sql
SELECT 
  'video_url column exists' as check,
  EXISTS(SELECT 1 FROM information_schema.columns 
    WHERE table_name='lessons' AND column_name='video_url') as result;
```

**If result = FALSE** → Run this first:
```sql
ALTER TABLE public.lessons ADD COLUMN video_url character varying(500) NULL;
CREATE INDEX idx_lessons_video_url ON public.lessons(video_url) WHERE video_url IS NOT NULL;
```

### Step 3: Insert All Video URLs
Copy & paste ALL 38 UPDATE statements from your user request. They start with:
```sql
UPDATE public.lessons 
SET video_url = 'https://www.youtube.com/embed/njDKi7dDOq4' 
WHERE id = '2c850dc5-d7e0-4325-bb1b-1197f2795654';
```

⏱️ Wait for all to complete (usually 10-20 seconds)

### Step 4: Verify Videos Are in Database
```sql
SELECT COUNT(*) as "Videos Added" 
FROM lessons 
WHERE video_url IS NOT NULL;
```
Should show **> 0**

### Step 5: Rebuild Flutter App
```bash
cd d:\DHV\Year4\Semester2\DoAn\app_learn_english
flutter clean
flutter pub get
flutter run
```

### Step 6: Test
1. App launches
2. Press on any lesson (e.g., "Alphabet")
3. In banner area, **you should see YouTube video player** 
4. Check console for: `✅ VIDEO BANNER: WebView loaded successfully`

---

## 🚨 If Still Not Working
1. Open [VIDEO_NOT_SHOWING_HELP.md](VIDEO_NOT_SHOWING_HELP.md)
2. Run [verify_video_setup.sql](verify_video_setup.sql) 
3. Check console with: `flutter run -v 2>&1 | grep video`

---

## ✅ Success Indicators
- [ ] Supabase SQL Editor shows column exists
- [ ] COUNT query shows videos added
- [ ] App rebuilds without errors
- [ ] Console shows `✅ VIDEO BANNER` messages
- [ ] Course detail screen shows YouTube player in banner

---

## 📋 Your 38 Video IDs (For Reference)

| # | Lesson | Video ID |
|-|-|-|
| 1 | Alphabet | njDKi7dDOq4 |
| 2 | Colors | 01AWUd1ySZs |
| 3 | Numbers | nByW9tG8Imk |
| 4 | Drinks | 6ACss216VPc |
| 5 | Food | IGLDaQgDDOc |
| 6 | Animals | cAFkgw3kJPM |
| 7 | Family | 6GgbvIm7LLs |
| 8 | Body Parts | bE45QomyqkQ |
| 9 | Clothes | tSbhtGjIn_o |
| 10 | Daily Activities | DVZL-8wYODk |
| 11 | Weather | e7tHYk_sVRg |
| 12 | Seasons | eZNWula_mMo |
| 13 | Time | jrVTKgzbf8M |
| 14 | Days & Months | XjA1Y9Zw_QE |
| 15 | Places | O4GGNGcbqtQ |
| 16 | Transportation | R-JQTFze4t4 |
| 17 | House & Home | w-PcKEymewc |
| 18 | Shopping | -WI1pMZ_-bk |
| 19 | Hobbies | aNhzl1RqoCM |
| 20 | Sports | 69Ci9RcGUXg |
| 21 | School & Education | D-xV1q8khDE |
| 22 | Jobs & Occupations | n6DOdAr_4aA |
| 23 | Health & Medicine | wh1Y2VyEDOY |
| 24 | Feelings & Emotions | uK8257gZV60 |
| 25 | Travel & Tourism | iZ140pU6w8M |
| 26 | Technology | bJsz3t78y2A |
| 27 | Business English | Rf114Q_Zbv4 |
| 28 | Environment | CT3q5qHn8Ro |
| 29 | Culture & Customs | GEK78wvy4bM |
| 30 | Current Events | hEpAa1wbGyQ |
| 31 | Entertainment | A8JKnVtysxg |
| 32 | Relationships | Tn0_E8ZGEaU |
| 33 | Money & Banking | RL17LduwiWA |
| 34 | Politics & Government | 0WKLsz-G-rs |
| 35 | Science & Innovation | C-hjktX2ofU |
| 36 | Philosophy & Ethics | UDD8i6WTgsA |
| 37 | Literature & Arts | A8JKnVtysxg |
| 38 | Economics | EKQ2xVvRz0c |

---

**Stuck?** See full guide: [VIDEO_NOT_SHOWING_HELP.md](VIDEO_NOT_SHOWING_HELP.md)
