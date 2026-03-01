# 🚀 Quick Start - Next Steps

## ✅ What's Been Done

### 1. Database Schema ✓
- Created 2 separate language tables (Vietnamese & English)
- Added indexes and stored procedures
- Generated clean CSV files without duplicates

### 2. Dart Services Updated ✓
- **supabase_dictionary_service_updated.dart** - Cloud search & fetch
- **dictionary_import_service_updated.dart** - Data import
- **dictionary_model_new.dart** - Simplified models
- **DART_SERVICES_UPDATE_GUIDE.md** - Detailed migration docs

### 3. CSV Data Ready ✓
- `vietnamese_headwords_clean.csv` (11,604 entries, 0 duplicates)
- `english_headwords_clean.csv` (82,991  entries, 0 duplicates)

---

## ⏳ What's Left To Do

### Phase 1: Database Setup (5 minutes)
1. Copy `dictionary_schema.sql` content
2. Open Supabase SQL Editor
3. Paste and run SQL
4. Run: `cleanup_old_data.sql`

### Phase 2: Data Import (10 minutes)
1. Import `vietnamese_headwords_clean.csv` to Supabase
2. Import `english_headwords_clean.csv` to Supabase
3. Verify with provided queries

### Phase 3: Code Integration (30-60 minutes)
1. Replace old service files with updated versions
2. Update all widgets to use new API
3. Test in app

---

## 📋 Detailed Next Steps

### Step 1: Setup SQL Schema in Supabase

```bash
1. Open: https://app.supabase.com
2. Go to: Your Project → SQL Editor → New Query
3. Copy all content from: dictionary_schema.sql
4. Paste into editor
5. Click: Run
6. Verify: Tables created successfully
```

**Expected Output:**
```
✅ 2 tables created (vietnamese_headwords, english_headwords)
✅ 10 indexes created
✅ 5 functions created
✅ 1 view created
```

---

### Step 2: Clean Old Data (if imported before)

```bash
1. Go to: Supabase → SQL Editor → New Query
2. Copy content from: cleanup_old_data.sql
3. Paste and run
4. Verify: Both tables are empty
```

---

### Step 3: Import Clean CSV Files

#### Vietnamese Data:
```
1. Supabase → Tables → vietnamese_headwords
2. Click: Insert
3. Select: Import from CSV
4. Choose file: vietnamese_headwords_clean.csv
5. Column mapping:
   term → term
   word_class → word_class
   meaning → meaning
   is_common → is_common
   frequency → frequency
6. Click: Import
```

Expected: ✅ 11,604 rows imported

#### English Data:
```
1. Supabase → Tables → english_headwords
2. Click: Insert
3. Select: Import from CSV
4. Choose file: english_headwords_clean.csv
5. Column mapping:
   term → term
   pronunciation → pronunciation
   word_class → word_class
   meaning → meaning
   is_common → is_common
   frequency → frequency
6. Click: Import
```

Expected: ✅ 82,991 rows imported

---

### Step 4: Verify Import Success

**In Supabase SQL Editor:**

```sql
-- Check counts
SELECT 'vietnamese_headwords' as table_name, COUNT(*) as count FROM vietnamese_headwords
UNION ALL
SELECT 'english_headwords', COUNT(*) FROM english_headwords;

-- Test search functions
SELECT * FROM search_vietnamese('ác') LIMIT 5;
SELECT * FROM search_english('abandon') LIMIT 5;
SELECT * FROM search_all('love') LIMIT 5;

-- Check for duplicates (should return no rows)
SELECT term, COUNT(*) FROM vietnamese_headwords GROUP BY term HAVING COUNT(*) > 1;
SELECT term, COUNT(*) FROM english_headwords GROUP BY term HAVING COUNT(*) > 1;
```

**Expected Results:**
```
vietnamese_headwords: 11,604
english_headwords: 82,991
Duplicates: None
```

---

### Step 5: Update Flutter Code

#### 5a. Backup Old Files
```bash
cd lib/services
cp supabase_dictionary_service.dart supabase_dictionary_service.dart.bak
cp dictionary_import_service.dart dictionary_import_service.dart.bak
cd ../models
cp dictionary_model.dart dictionary_model.dart.bak
```

#### 5b. Replace Service Files
```bash
cd lib/services
mv supabase_dictionary_service_updated.dart supabase_dictionary_service.dart
mv dictionary_import_service_updated.dart dictionary_import_service.dart
cd ../models
mv dictionary_model_new.dart dictionary_model.dart
```

#### 5c. Update All Dart Files Using Search & Replace

**Search:**
```
.search(
```

**Replace with:**
```
.searchAll(
```

---

**Search:**
```
searchVietnamese|searchEnglish|searchAll|getVietnameseEntry|getEnglishEntry|getEntryByTerm
```

Check each result and update accordingly.

---

### Step 6: Fix Widget Code

#### Example Search Widget Update

**OLD CODE:**
```dart
final results = await _dictionaryService.search(query);
for (final entry in results) {
  print('${entry.headword.term}'); // BREAKS - no headword object
  if (entry.senses.isNotEmpty) { // BREAKS - no senses array
    print(entry.senses[0].definition);
  }
}
```

**NEW CODE:**
```dart
final results = await _dictionaryService.searchAll(query);
for (final entry in results) {
  print('${entry.term}');
  print(entry.meaning);
}
```

---

#### Example Favorites Widget Update

**OLD CODE:**
```dart
await _dictionaryService.saveWord(
  entry.headword.id,
  entry.headword.term,
  entry.headword.lang,
);
```

**NEW CODE:**
```dart
await _dictionaryService.saveWord(entry.term, entry.language);
```

---

### Step 7: Test the App

```dart
// Test Vietnamese search
final viResults = await _dictionaryService.searchVietnamese('ác');
assert(viResults.isNotEmpty, 'Vietnamese search failed');

// Test English search
final enResults = await _dictionaryService.searchEnglish('apple');
assert(enResults.isNotEmpty, 'English search failed');

// Test combined search
final allResults = await _dictionaryService.searchAll('love');
assert(allResults.isNotEmpty, 'Combined search failed');

// Test statistics
final stats = await _dictionaryService.getDictionaryStats();
assert(stats['total']! > 0, 'Stats failed');

print('✅ All tests passed!');
```

---

## 📊 Progress Tracking

- [x] Database schema created
- [x] CSV files cleaned (no duplicates)
- [x] Dart services updated
- [ ] SQL schema deployed to Supabase
- [ ] CSV data imported
- [ ] Widget code updated
- [ ] App tested

---

## 🆘 Troubleshooting

### Import fails with "Column not found"
**Solution:** Verify CSV column headers match exactly:
- Vietnamese: `term`, `word_class`, `meaning`, `is_common`, `frequency`
- English: `term`, `pronunciation`, `word_class`, `meaning`, `is_common`, `frequency`

### Dart compilation errors
**Solution:** Run `flutter pub get` to update dependencies

### Search returns 0 results
**Solution:** Verify data was imported by checking Supabase table row count

### RPC functions don't exist
**Solution:** Run `dictionary_schema.sql` in Supabase to create functions

---

## 📞 Need Help?

1. Check **DART_SERVICES_UPDATE_GUIDE.md** for API reference
2. Check **DART_UPDATE_SUMMARY.md** for code examples
3. Review **IMPORT_CLEAN_DATA.md** for import steps
4. Check console output for detailed error messages

---

## ⏱️ Estimated Timeline

| Phase | Time | Status |
|-------|------|--------|
| Database Setup | 5 min | Ready |
| Data Import | 10 min | Waiting |
| Code Integration | 30-60 min | Waiting |
| Testing | 10-15 min | Waiting |
| **Total** | **60-90 min** | **On Track** |

---

**Ready to proceed?** 🎯

1. Run SQL schema in Supabase
2. Import both CSV files
3. Update Dart services
4. Run tests

Let's go! 🚀
