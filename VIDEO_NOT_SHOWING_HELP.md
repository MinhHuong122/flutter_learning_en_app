# 🔧 Video Not Showing - Troubleshooting Guide

## Step-by-Step Diagnosis

### Step 1: Check Database Column Exists
Run this in Supabase SQL Editor:

```sql
-- Check if video_url column exists
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'lessons' AND column_name = 'video_url'
ORDER BY ordinal_position;
```

**Expected Result:**
```
column_name | data_type | is_nullable
video_url   | varchar   | YES
```

**If NOT found:** Run the migration:
```sql
ALTER TABLE public.lessons
ADD COLUMN video_url character varying(500) NULL;

CREATE INDEX idx_lessons_video_url ON public.lessons(video_url) WHERE video_url IS NOT NULL;
```

---

### Step 2: Verify Video URLs Are in Database
```sql
-- Check how many lessons have video_url set
SELECT id, title, video_url 
FROM public.lessons 
WHERE video_url IS NOT NULL 
LIMIT 5;
```

**Expected Result:** Should see video URLs like `https://www.youtube.com/embed/njDKi7dDOq4`

**If EMPTY:** Use the INSERT statements provided by the user to update lessons.

---

### Step 3: Check Lesson Model is Updated
Open [lib/models/lesson_model.dart](../lib/models/lesson_model.dart) and verify:

```dart
class Lesson {
  // ... other fields ...
  final String? videoUrl;  // ✅ This field MUST exist
  
  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      // ... other fields ...
      videoUrl: json['video_url'] as String?,  // ✅ This MUST be included
      // ...
    );
  }
}
```

**If Missing:** Add the field.

---

### Step 4: Enable Debug Logging
When you run the app, check the Flutter console for these debug messages:

```
🎬 VIDEO BANNER DEBUG: videoUrl = https://www.youtube.com/embed/njDKi7dDOq4
🎬 VIDEO BANNER DEBUG: lesson.id = 2c850dc5-d7e0-4325-bb1b-1197f2795654
🎬 VIDEO BANNER DEBUG: lesson.title = Alphabet
🎬 VIDEO BANNER: Extracted videoId = njDKi7dDOq4
✅ VIDEO BANNER: WebView loaded successfully
```

**If You See:**
- `⚠️ VIDEO BANNER: No video URL found` → Database doesn't have video_url set
- `❌ VIDEO BANNER: WebView error` → Check browser network for YouTube errors

---

### Step 5: Rebuild the App
```bash
cd "d:\DHV\Year4\Semester2\DoAn\app_learn_english"

# Clear cache and rebuild
flutter clean
flutter pub get
flutter run
```

---

## Common Issues & Solutions

### Issue 1: "No video URL found, showing placeholder"
**Cause:** `lesson.videoUrl` is null or empty

**Solution:**
1. Check database: `SELECT id, title, video_url FROM lessons WHERE id = '{lesson_id}'`
2. If NULL, run the user's UPDATE statements
3. Hot reload might not reflect DB changes - rebuild with `flutter run`

### Issue 2: WebView shows blank white rectangle
**Cause:** Video ID might be invalid or YouTube video is removed

**Solution:**
1. Check WebView console for errors
2. Verify the YouTube video still exists by visiting: `https://www.youtube.com/watch?v={VIDEO_ID}`
3. If broken, replace with different video ID

### Issue 3: "Build the Android App..."
**Cause:** Android WebView permissions missing

**Solution:**
Add to [android/app/src/main/AndroidManifest.xml](../android/app/src/main/AndroidManifest.xml):
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### Issue 4: iOS blank screen
**Cause:** iOS requires additional configuration

**Solution:**
In [ios/Runner/Info.plist](../ios/Runner/Info.plist), add:
```xml
<key>NSBonjourServices</key>
<array>
  <string>_http._tcp</string>
</array>
<key>NSLocalNetworkUsageDescription</key>
<string>App needs local network access</string>
<key>NSBonjourServiceTypes</key>
<array>
  <string>_http._tcp</string>
  <string>_services._dns-sd._udp</string>
</array>
```

---

## Full Debug Checklist

- [ ] Database column `video_url` exists (checked in Step 1)
- [ ] At least one lesson has `video_url` set (checked in Step 2)
- [ ] Lesson model has `videoUrl` field (checked in Step 3)
- [ ] Console shows "✅ VIDEO BANNER: WebView loaded successfully" (Step 4)
- [ ] App rebuilt after database changes (Step 5, especially important!)
- [ ] YouTube video IDs are valid and videos still exist
- [ ] WebViewWidget import is present: `import 'package:webview_flutter/webview_flutter.dart';`
- [ ] webview_flutter is in pubspec.yaml: `webview_flutter: ^4.10.0`

---

## Quick Fix: Force Reload Database

If you just updated the database and don't see changes:

```bash
# This is NOT a code change, it's a database sync issue
# The app caches lessons, so you need to either:

# Option A: Force app restart
flutter run --no-fast-start

# Option B: Clear app data
# - iOS: Delete app and reinstall
# - Android: Settings > Apps > [Your App] > Storage > Clear Data
```

---

## Video ID Resources

If a YouTube video returns 404 or is blocked, replace with one of these alternatives:

- **English Alphabet**: `njDKi7dDOq4`
- **YouTube Educational**: `dQw4w9WgXcQ` (famous, always works)
- **Tutorial Example**: `jNQXAC9IVRw` (first YouTube video, always available)

---

## Contact Support

If still not working after all steps:

1. Share console output (run with `-v` flag):
   ```bash
   flutter run -v 2>&1 | grep -i "video\|webview"
   ```

2. Check lesson record directly:
   ```sql
   SELECT id, title, video_url, created_at 
   FROM public.lessons 
   WHERE title ILIKE '%alphabet%' 
   LIMIT 1;
   ```

3. Verify network access: Can you visit YouTube in the Flutter WebView?
   ```dart
   // Test in main.dart
   WebViewWidget(controller: 
     WebViewController()..loadRequest(Uri.parse('https://www.youtube.com'))
   )
   ```
