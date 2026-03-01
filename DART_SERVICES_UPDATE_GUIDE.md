# 🔄 Dart Services - Updated for New Database Schema

## Overview

Your database schema has changed from:
- **Old**: Single `headwords` table + `senses` + `examples` (normalized 3NF)
- **New**: Separate `vietnamese_headwords` & `english_headwords` tables (simplified 2NF)

All Dart services have been updated to work with the new schema.

---

## 📁 Updated Files

### 1. **supabase_dictionary_service_updated.dart**
**Location:** `lib/services/supabase_dictionary_service_updated.dart`

**Changes:**
- ✅ New `DictionaryEntry` model (replaces old multi-table class)
- ✅ Separate search methods: `searchVietnamese()`, `searchEnglish()`, `searchAll()`
- ✅ Language-specific entry fetching: `getVietnameseEntry()`, `getEnglishEntry()`
- ✅ Direct RPC function calls: `search_all()`, `get_common_vietnamese()`, `get_common_english()`
- ✅ Simplified methods (no senses/examples navigation)

**Key Methods:**
```dart
// Search by language
searchVietnamese(String query, {int limit = 50})
searchEnglish(String query, {int limit = 50})
searchAll(String query, {int limit = 50})

// Get specific entry
getVietnameseEntry(int id)
getEnglishEntry(int id)
getEntryByTerm(String term, String language)

// Get common words
getCommonVietnamese({int limit = 100})
getCommonEnglish({int limit = 100})

// Favorites
saveWord(String term, String language)
unsaveWord(String term, String language)
isWordSaved(String term, String language)
getUserSavedWords()
```

---

### 2. **dictionary_import_service_updated.dart**
**Location:** `lib/services/dictionary_import_service_updated.dart`

**Changes:**
- ✅ CSV import for both tables: `importFromCSV()`
- ✅ Batch processing with configurable size (default 100 entries)
- ✅ Single entry import: `importEntry()`
- ✅ Statistics and verification: `getImportStats()`, `verifyDataIntegrity()`
- ✅ Simplified (no complex JSON structures)

**Key Methods:**
```dart
// Import from CSV
importFromCSV({
  required List<Map<String, dynamic>> vietnameseData,
  required List<Map<String, dynamic>> englishData,
})

// Import single entry
importEntry({
  required String term,
  required String language, // 'vi' or 'en'
  String? pronunciation,
  required String wordClass,
  required String meaning,
  bool isCommon = false,
  int frequency = 0,
})

// Verify
verifyDataIntegrity()
checkDuplicates()
getImportStats()
```

---

## 🔄 How to Update Your Project

### Step 1: Backup Old Services
```bash
cd lib/services
mv supabase_dictionary_service.dart supabase_dictionary_service.dart.bak
mv dictionary_import_service.dart dictionary_import_service.dart.bak
```

### Step 2: Rename Updated Files
```bash
mv supabase_dictionary_service_updated.dart supabase_dictionary_service.dart
mv dictionary_import_service_updated.dart dictionary_import_service.dart
```

### Step 3: Update Imports in Your Code

**Before:**
```dart
import 'models/dictionary_model.dart'; // Old WordEntry, etc.
```

**After:**
```dart
// No need for old models, DictionaryEntry is in supabase_dictionary_service.dart
import 'services/supabase_dictionary_service.dart';
```

### Step 4: Update Widget Code

**Old Pattern (searching by language):**
```dart
// OLD - doesn't work anymore
final results = await _dictionaryService.search(query);
```

**New Pattern (separate language search):**
```dart
// NEW - recommended
final viResults = await _dictionaryService.searchVietnamese(query);
final enResults = await _dictionaryService.searchEnglish(query);
// OR combined
final allResults = await _dictionaryService.searchAll(query);
```

**Old Pattern (displaying entry details):**
```dart
// OLD - had nested senses/examples
final entry = await _dictionaryService.getWordEntry(id);
for (final sense in entry.senses) {
  print(sense.definition);
}
```

**New Pattern (simpler display):**
```dart
// NEW - simpler structure
final entry = await _dictionaryService.getVietnameseEntry(id);
print(entry.meaning); // Single meaning field
```

---

## 🔍 Model Comparison

### Old Model Structure
```dart
class WordEntry {
  Headword headword;
  List<Sense> senses;      // ← Multiple senses per entry
  Map<int, List<Example>> examplesBySense; // ← Nested examples
}
```

### New Model Structure
```dart
class DictionaryEntry {
  int id;
  String term;
  String language;
  String pronunciation;
  String wordClass;
  String meaning;           // ← Single meaning field
  bool isCommon;
  int frequency;
  DateTime createdAt;
}
```

---

## 💾 Database Schema Reference

### Vietnamese Headwords Table
```sql
CREATE TABLE vietnamese_headwords (
  id BIGSERIAL PRIMARY KEY,
  term TEXT NOT NULL UNIQUE,
  word_class TEXT DEFAULT 'noun',
  meaning TEXT NOT NULL,
  is_common BOOLEAN DEFAULT false,
  frequency INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);
```

### English Headwords Table
```sql
CREATE TABLE english_headwords (
  id BIGSERIAL PRIMARY KEY,
  term TEXT NOT NULL UNIQUE,
  pronunciation TEXT DEFAULT '',    -- ← Language-specific!
  word_class TEXT DEFAULT 'noun',
  meaning TEXT NOT NULL,
  is_common BOOLEAN DEFAULT false,
  frequency INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);
```

---

## 🧪 Testing the New Services

### Test Vietnamese Search
```dart
void testVietnameseSearch() async {
  final service = SupabaseDictionaryService();
  
  final results = await service.searchVietnamese('ác');
  
  for (final entry in results) {
    print('${entry.term}: ${entry.meaning}');
  }
}
```

### Test English Search
```dart
void testEnglishSearch() async {
  final service = SupabaseDictionaryService();
  
  final results = await service.searchEnglish('abandon');
  
  for (final entry in results) {
    print('${entry.term} (${entry.pronunciation}): ${entry.meaning}');
  }
}
```

### Test Combined Search
```dart
void testCombinedSearch() async {
  final service = SupabaseDictionaryService();
  
  final results = await service.searchAll('love');
  
  for (final entry in results) {
    print('[${entry.language.toUpperCase()}] ${entry.term}: ${entry.meaning}');
  }
}
```

### Test Common Words
```dart
void testCommonWords() async {
  final service = SupabaseDictionaryService();
  
  final viCommon = await service.getCommonVietnamese(limit: 10);
  final enCommon = await service.getCommonEnglish(limit: 10);
  
  print('Vietnamese: ${viCommon.map((e) => e.term).join(", ")}');
  print('English: ${enCommon.map((e) => e.term).join(", ")}');
}
```

---

## ⚠️ Breaking Changes

| Feature | Old | New | Alternative |
|---------|-----|-----|-------------|
| Search all | `search(query)` | `searchAll(query)` | `searchVietnamese(query)` + `searchEnglish(query)` |
| Language param | `search(query, lang: 'vi')` | `searchVietnamese(query)` | - |
| Get entry | `getWordEntry(id)` | `getVietnameseEntry(id)` or `getEnglishEntry(id)` | `getEntryByTerm(term, lang)` |
| Senses | `entry.senses` | ❌ Not available | Single `entry.meaning` |
| Examples | `entry.examplesBySense` | ❌ Not available | - |
| Pronunciation | `entry.headword.pronunciation` | `entry.pronunciation` (EN only) | - |

---

## 📊 Side-by-Side Usage Examples

### Example 1: Search and Display

**OLD:**
```dart
final entry = await service.getWordEntry(123);
final meaning = entry.senses.isNotEmpty 
    ? entry.senses[0].definition 
    : 'No definition';
print('${entry.headword.term}: $meaning');
```

**NEW:**
```dart
final entry = await service.getVietnameseEntry(123);
print('${entry.term}: ${entry.meaning}');
```

### Example 2: Search by Language

**OLD:**
```dart
final viResults = await service.search('ác', language: 'vi');
final enResults = await service.search('love', language: 'en');
```

**NEW:**
```dart
final viResults = await service.searchVietnamese('ác');
final enResults = await service.searchEnglish('love');
```

### Example 3: Save Word

**OLD:**
```dart
await service.saveWord(entry.headword.term, entry.headword.lang);
```

**NEW:**
```dart
await service.saveWord(entry.term, entry.language);
```

---

## ✅ Checklist for Migration

- [ ] Backup old service files
- [ ] Replace old files with updated versions
- [ ] Update import statements in widgets
- [ ] Update search calls (old `search()` → new `searchVietnamese()`/`searchEnglish()`)
- [ ] Update result display (remove senses/examples handling)
- [ ] Update favorites/saved words calls
- [ ] Test Vietnamese search
- [ ] Test English search
- [ ] Test combined search
- [ ] Test common words
- [ ] Run app and verify no errors

---

## 📞 Common Issues & Solutions

### Issue: "senses" field not found
**Solution:** Use single `meaning` field instead
```dart
// ❌ Wrong
print(entry.senses[0].definition);

// ✅ Right
print(entry.meaning);
```

### Issue: "language" field not working in search
**Solution:** Use language-specific search methods
```dart
// ❌ Wrong
const allResults = await service.search(query, language: 'vi');

// ✅ Right
final viResults = await service.searchVietnamese(query);
```

### Issue: Pronunciation missing for Vietnamese
**Solution:** Pronunciation only exists for English
```dart
// ✅ Only for English entries
if (entry.language == 'en') {
  print(entry.pronunciation);
}
```

---

## 🚀 Next Steps

1. ✅ Update all Dart service files (3/3 done)
2. ⏳ Import clean CSV data to Supabase
3. ⏳ Update widgets to use new services
4. ⏳ Test in app
5. ⏳ Deploy

---

**Need help?** Check the updated service files for detailed comments and error messages!
