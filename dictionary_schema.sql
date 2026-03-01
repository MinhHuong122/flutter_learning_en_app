-- ============================================================================
-- DICTIONARY DATABASE SCHEMA - SEPARATE TABLES FOR VIETNAMESE & ENGLISH
-- ============================================================================
-- Created: 2024-02-27
-- Purpose: Create optimized schema for bilingual dictionary
-- ============================================================================

-- ============================================================================
-- TABLE 1: VIETNAMESE HEADWORDS
-- ============================================================================
CREATE TABLE IF NOT EXISTS vietnamese_headwords (
  id BIGSERIAL PRIMARY KEY,
  term TEXT NOT NULL UNIQUE,
  word_class TEXT DEFAULT 'noun',
  meaning TEXT NOT NULL,
  is_common BOOLEAN DEFAULT false,
  frequency INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

-- Create indexes for Vietnamese table
CREATE INDEX IF NOT EXISTS idx_vi_term ON vietnamese_headwords(term);
CREATE INDEX IF NOT EXISTS idx_vi_common ON vietnamese_headwords(is_common);
CREATE INDEX IF NOT EXISTS idx_vi_word_class ON vietnamese_headwords(word_class);
CREATE INDEX IF NOT EXISTS idx_vi_frequency ON vietnamese_headwords(frequency DESC);

-- Full-text search index for Vietnamese
CREATE INDEX IF NOT EXISTS idx_vi_term_fts ON vietnamese_headwords 
USING gin(to_tsvector('english', term));

-- ============================================================================
-- TABLE 2: ENGLISH HEADWORDS
-- ============================================================================
CREATE TABLE IF NOT EXISTS english_headwords (
  id BIGSERIAL PRIMARY KEY,
  term TEXT NOT NULL UNIQUE,
  pronunciation TEXT DEFAULT '',
  word_class TEXT DEFAULT 'noun',
  meaning TEXT NOT NULL,
  is_common BOOLEAN DEFAULT false,
  frequency INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

-- Create indexes for English table
CREATE INDEX IF NOT EXISTS idx_en_term ON english_headwords(term);
CREATE INDEX IF NOT EXISTS idx_en_pronunciation ON english_headwords(pronunciation);
CREATE INDEX IF NOT EXISTS idx_en_common ON english_headwords(is_common);
CREATE INDEX IF NOT EXISTS idx_en_word_class ON english_headwords(word_class);
CREATE INDEX IF NOT EXISTS idx_en_frequency ON english_headwords(frequency DESC);

-- Full-text search index for English
CREATE INDEX IF NOT EXISTS idx_en_term_fts ON english_headwords 
USING gin(to_tsvector('english', term));

-- ============================================================================
-- VIEW: Combined view for unified queries (optional)
-- ============================================================================
CREATE OR REPLACE VIEW all_headwords AS
  SELECT 
    ROW_NUMBER() OVER (ORDER BY vh.id) as id,
    vh.term,
    'vi' as language,
    '' as pronunciation,
    vh.word_class,
    vh.meaning,
    vh.is_common,
    vh.frequency,
    vh.created_at
  FROM vietnamese_headwords vh
  
  UNION ALL
  
  SELECT 
    ROW_NUMBER() OVER (ORDER BY eh.id) as id,
    eh.term,
    'en' as language,
    eh.pronunciation,
    eh.word_class,
    eh.meaning,
    eh.is_common,
    eh.frequency,
    eh.created_at
  FROM english_headwords eh
  ORDER BY language, term;

-- ============================================================================
-- FUNCTION: Search Vietnamese headwords
-- ============================================================================
CREATE OR REPLACE FUNCTION search_vietnamese(p_term TEXT, p_limit INT DEFAULT 50)
RETURNS TABLE (
  id BIGINT,
  term TEXT,
  word_class TEXT,
  meaning TEXT,
  is_common BOOLEAN,
  frequency INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT vh.id, vh.term, vh.word_class, vh.meaning, vh.is_common, vh.frequency
  FROM vietnamese_headwords vh
  WHERE vh.term ILIKE '%' || p_term || '%' 
     OR vh.meaning ILIKE '%' || p_term || '%'
  ORDER BY vh.is_common DESC, vh.frequency DESC, vh.term
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCTION: Search English headwords
-- ============================================================================
CREATE OR REPLACE FUNCTION search_english(p_term TEXT, p_limit INT DEFAULT 50)
RETURNS TABLE (
  id BIGINT,
  term TEXT,
  pronunciation TEXT,
  word_class TEXT,
  meaning TEXT,
  is_common BOOLEAN,
  frequency INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT eh.id, eh.term, eh.pronunciation, eh.word_class, eh.meaning, eh.is_common, eh.frequency
  FROM english_headwords eh
  WHERE eh.term ILIKE '%' || p_term || '%' 
     OR eh.meaning ILIKE '%' || p_term || '%'
     OR eh.pronunciation ILIKE '%' || p_term || '%'
  ORDER BY eh.is_common DESC, eh.frequency DESC, eh.term
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCTION: Search both Vietnamese and English
-- ============================================================================
CREATE OR REPLACE FUNCTION search_all(p_term TEXT, p_limit INT DEFAULT 50)
RETURNS TABLE (
  id BIGINT,
  term TEXT,
  language TEXT,
  pronunciation TEXT,
  word_class TEXT,
  meaning TEXT,
  is_common BOOLEAN,
  frequency INTEGER
) AS $$
BEGIN
  RETURN QUERY
  (
    SELECT 
      vh.id, 
      vh.term, 
      'vi'::TEXT, 
      ''::TEXT, 
      vh.word_class, 
      vh.meaning, 
      vh.is_common, 
      vh.frequency
    FROM vietnamese_headwords vh
    WHERE vh.term ILIKE '%' || p_term || '%' 
       OR vh.meaning ILIKE '%' || p_term || '%'
  )
  UNION ALL
  (
    SELECT 
      eh.id, 
      eh.term, 
      'en'::TEXT, 
      eh.pronunciation, 
      eh.word_class, 
      eh.meaning, 
      eh.is_common, 
      eh.frequency
    FROM english_headwords eh
    WHERE eh.term ILIKE '%' || p_term || '%' 
       OR eh.meaning ILIKE '%' || p_term || '%'
  )
  ORDER BY is_common DESC, frequency DESC, term
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCTION: Get common words for each language
-- ============================================================================
CREATE OR REPLACE FUNCTION get_common_vietnamese(p_limit INT DEFAULT 100)
RETURNS TABLE (
  id BIGINT,
  term TEXT,
  word_class TEXT,
  meaning TEXT,
  frequency INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT vh.id, vh.term, vh.word_class, vh.meaning, vh.frequency
  FROM vietnamese_headwords vh
  WHERE vh.is_common = true
  ORDER BY vh.frequency DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_common_english(p_limit INT DEFAULT 100)
RETURNS TABLE (
  id BIGINT,
  term TEXT,
  pronunciation TEXT,
  word_class TEXT,
  meaning TEXT,
  frequency INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT eh.id, eh.term, eh.pronunciation, eh.word_class, eh.meaning, eh.frequency
  FROM english_headwords eh
  WHERE eh.is_common = true
  ORDER BY eh.frequency DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================
/*
Run these queries after importing data to verify setup:

-- Count entries in each table
SELECT 'Vietnamese' as language, COUNT(*) as count FROM vietnamese_headwords
UNION ALL
SELECT 'English', COUNT(*) FROM english_headwords;

-- Check common words count
SELECT 'Vietnamese' as language, COUNT(*) as common FROM vietnamese_headwords WHERE is_common = true
UNION ALL
SELECT 'English', COUNT(*) FROM english_headwords WHERE is_common = true;

-- Check data quality
SELECT 
  COUNT(*) as total,
  COUNT(CASE WHEN term IS NULL THEN 1 END) as null_terms,
  COUNT(CASE WHEN meaning IS NULL THEN 1 END) as null_meanings
FROM vietnamese_headwords;

SELECT 
  COUNT(*) as total,
  COUNT(CASE WHEN term IS NULL THEN 1 END) as null_terms,
  COUNT(CASE WHEN meaning IS NULL THEN 1 END) as null_meanings
FROM english_headwords;

-- Test search functions
SELECT * FROM search_vietnamese('ác') LIMIT 10;
SELECT * FROM search_english('abandon') LIMIT 10;
SELECT * FROM search_all('love') LIMIT 10;

-- Get common words
SELECT * FROM get_common_vietnamese(20);
SELECT * FROM get_common_english(20);

-- Check indexes
SELECT * FROM pg_stat_user_indexes 
WHERE relname IN ('vietnamese_headwords', 'english_headwords')
ORDER BY relname;

*/

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================
