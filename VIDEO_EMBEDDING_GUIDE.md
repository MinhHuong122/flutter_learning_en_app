# Video Embedding Implementation Guide

## Overview
This implementation adds YouTube video embedding to the course banner in `lesson_detail_screen.dart`. The banner now displays YouTube videos instead of a static play icon.

## Changes Made

### 1. Database Schema Update
**File**: `migrations/add_video_url_to_lessons.sql`
- Added `video_url` column to `lessons` table
- Type: `character varying(500)`
- Nullable: Yes (for backwards compatibility)
- Indexed for faster filtering

### 2. Lesson Model Update
**File**: `lib/models/lesson_model.dart`
- Added `videoUrl` field to the `Lesson` class
- Updated `fromJson()` to parse `video_url` from database
- Updated `toJson()` to serialize `video_url` for API requests

### 3. Screen Implementation
**File**: `lib/screens/lesson_detail_screen.dart`
- Added import: `import 'package:webview_flutter/webview_flutter.dart';`
- Replaced static banner with `_buildCourseVideoBanner()` method
- Implements smart YouTube URL parsing to handle multiple URL formats:
  - Full embed URLs: `https://www.youtube.com/embed/{VIDEO_ID}`
  - Standard URLs: `https://www.youtube.com/watch?v={VIDEO_ID}`
  - Short URLs: `https://youtu.be/{VIDEO_ID}`
  - Raw video IDs: `{VIDEO_ID}`

### 4. Dependencies
✅ `webview_flutter: ^4.10.0` - Already in `pubspec.yaml`

## How to Update Lessons with Videos

### Option 1: Direct SQL UPDATE (Recommended)
```sql
-- Update a single lesson
UPDATE public.lessons 
SET video_url = 'https://www.youtube.com/embed/njDKi7dDOq4'
WHERE title LIKE '%Alphabet%' OR title LIKE '%chữ cái%';

-- Or by lesson ID
UPDATE public.lessons 
SET video_url = '{video_url}'
WHERE id = '{lesson_id}';
```

### Option 2: Bulk Update by Title Matching
See `migrations/insert_video_urls.sql` for pre-built UPDATE statements for all 38 lessons.

### Option 3: Manual Entry
Update lessons one by one in Supabase dashboard:
1. Go to `lessons` table
2. Click on a lesson row
3. Edit the `video_url` field
4. Paste: `https://www.youtube.com/embed/{VIDEO_ID}`

## Video URL Formats Supported

The `_buildCourseVideoBanner()` method intelligently parses these formats:

| Format | Example | Handled |
|--------|---------|---------|
| Embed URL | `https://www.youtube.com/embed/njDKi7dDOq4` | ✅ |
| Watch URL | `https://www.youtube.com/watch?v=njDKi7dDOq4` | ✅ |
| Short URL | `https://youtu.be/njDKi7dDOq4` | ✅ |
| Video ID | `njDKi7dDOq4` | ✅ |

## Video List for All 38 Lessons

Copy-paste these into your lessons:

```
1. Alphabet (chữ cái) - njDKi7dDOq4
2. Colors (màu sắc) - 01AWUd1ySZs
3. Numbers (số đếm) - nByW9tG8Imk
4. Drinks (đồ uống) - 6ACss216VPc
5. Food (đồ ăn) - IGLDaQgDDOc
6. Animals (động vật) - cAFkgw3kJPM
7. Family (gia đình) - 6GgbvIm7LLs
8. Body Parts (bộ phận cơ thể) - bE45QomyqkQ
9. Clothing (quần áo) - tSbhtGjIn_o
10. Daily Activities (hoạt động hàng ngày) - DVZL-8wYODk
11. Weather (thời tiết) - e7tHYk_sVRg
12. Seasons (mùa) - eZNWula_mMo
13. Time (thời gian) - jrVTKgzbf8M
14. Dates (ngày tháng) - XjA1Y9Zw_QE
15. Places (địa điểm) - O4GGNGcbqtQ
16. Transportation (phương tiện) - R-JQTFze4t4
17. Housing (nhà ở) - w-PcKEymewc
18. Shopping (mua sắm) - -WI1pMZ_-bk
19. Interests (sở thích) - aNhzl1RqoCM
20. Sports (thể thao) - 69Ci9RcGUXg
21. School (trường học) - D-xV1q8khDE
22. Career (nghề nghiệp) - n6DOdAr_4aA
23. Health (sức khỏe) - wh1Y2VyEDOY
24. Emotions (cảm xúc) - uK8257gZV60
25. Travel (du lịch) - iZ140pU6w8M
26. Technology (công nghệ) - bJsz3t78y2A
27. Business (thương mại) - Rf114Q_Zbv4
28. Environment (môi trường) - CT3q5qHn8Ro
29. Culture (văn hoá) - GEK78wvy4bM
30. Events (sự kiện) - hEpAa1wbGyQ
31. Entertainment (giải trí) - 1kA79NaJrUk
32. Relationships (quan hệ) - Tn0_E8ZGEaU
33. Banking (ngân hàng) - RL17LduwiWA
34. Politics (chính trị) - 0WKLsz-G-rs
35. Science (khoa học) - C-hjktX2ofU
36. Philosophy (triết học) - UDD8i6WTgsA
37. Literature (văn học) - A8JKnVtysxg
38. Economics (kinh tế) - EKQ2xVvRz0c
```

## Implementation Details

### _buildCourseVideoBanner() Method
```dart
Widget _buildCourseVideoBanner() {
  // 1. Gets video_url from lesson.videoUrl field
  // 2. Falls back to placeholder if no URL provided
  // 3. Extracts video ID from various URL formats
  // 4. Builds responsive HTML iframe
  // 5. Renders using WebViewWidget with full HTML support
}
```

### Fallback Behavior
- **If video_url is null/empty**: Shows original play icon placeholder
- **If video fails to load**: WebView displays error but doesn't crash app
- **If wrong video ID format**: URL parsing handles common formats automatically

## Testing Steps

1. **Check database schema**:
   ```sql
   SELECT column_name, data_type FROM information_schema.columns 
   WHERE table_name = 'lessons' AND column_name = 'video_url';
   ```

2. **Run migration**:
   ```bash
   # Execute add_video_url_to_lessons.sql in Supabase
   ```

3. **Update lesson with video URL**:
   ```sql
   UPDATE lessons SET video_url = 'https://www.youtube.com/embed/njDKi7dDOq4' 
   WHERE title LIKE '%Alphabet%';
   ```

4. **Test in Flutter**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

5. **Navigate to course detail**: Tap any lesson → Banner should show YouTube video

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Video doesn't show | Check video_url is not null, valid YouTube ID |
| Blank white rectangle | Video ID may be wrong, check YouTube video still exists |
| App crashes | Ensure webview_flutter is in pubspec.yaml, run `flutter pub get` |
| Placeholder shows instead | Lesson record has null video_url, update database |

## Best Practices

1. **Always use embed format**: `https://www.youtube.com/embed/{ID}` is most reliable
2. **Test video exists**: Click link before adding to database
3. **Keep URLs clean**: Avoid extra parameters if possible
4. **Update bulk**: Use SQL migration for multiple lessons at once
5. **Monitor field**: video_url is optional, apps won't break if missing

## Future Enhancements

- [ ] Add autoplay toggle (currently disabled for UX)
- [ ] Cache videos locally for offline viewing
- [ ] Add video timestamps (start/end)
- [ ] Support multiple videos per lesson
- [ ] Add video quality selection
- [ ] Track video watch completion
- [ ] Add video transcripts/captions
