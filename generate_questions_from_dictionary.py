"""
Generate SQL Questions from Dictionary Data
Purpose: Automatically create diverse questions using existing dictionary vocabulary
"""

import json
import random
import csv
from typing import List, Dict, Any

# =====================================================
# QUESTION TEMPLATES
# =====================================================

class QuestionGenerator:
    def __init__(self):
        self.vietnamese_words = []
        self.english_words = []
        
    def load_dictionary_data(self, vi_file='vietnamese_headwords_clean.csv', en_file='english_headwords_clean.csv'):
        """Load vocabulary from CSV files"""
        try:
            # Load Vietnamese words
            with open(vi_file, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    self.vietnamese_words.append({
                        'term': row.get('term', ''),
                        'meaning': row.get('meaning', ''),
                        'word_class': row.get('word_class', 'noun'),
                        'is_common': row.get('is_common', 'false').lower() == 'true'
                    })
            
            # Load English words
            with open(en_file, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    self.english_words.append({
                        'term': row.get('term', ''),
                        'pronunciation': row.get('pronunciation', ''),
                        'meaning': row.get('meaning', ''),
                        'word_class': row.get('word_class', 'noun'),
                        'is_common': row.get('is_common', 'false').lower() == 'true'
                    })
                    
            print(f"Loaded {len(self.vietnamese_words)} Vietnamese words")
            print(f"Loaded {len(self.english_words)} English words")
            
        except FileNotFoundError as e:
            print(f"Warning: Could not load dictionary files: {e}")
            print("Using sample vocabulary instead...")
            self._load_sample_data()
    
    def _load_sample_data(self):
        """Load sample vocabulary if CSV files not found"""
        self.vietnamese_words = [
            {'term': 'xin chào', 'meaning': 'hello', 'word_class': 'phrase', 'is_common': True},
            {'term': 'cảm ơn', 'meaning': 'thank you', 'word_class': 'phrase', 'is_common': True},
            {'term': 'tạm biệt', 'meaning': 'goodbye', 'word_class': 'phrase', 'is_common': True},
            {'term': 'yêu', 'meaning': 'love', 'word_class': 'verb', 'is_common': True},
            {'term': 'ăn', 'meaning': 'eat', 'word_class': 'verb', 'is_common': True},
            {'term': 'uống', 'meaning': 'drink', 'word_class': 'verb', 'is_common': True},
            {'term': 'nước', 'meaning': 'water', 'word_class': 'noun', 'is_common': True},
            {'term': 'nhà', 'meaning': 'house', 'word_class': 'noun', 'is_common': True},
        ]
        
        self.english_words = [
            {'term': 'hello', 'pronunciation': 'hə-ˈlō', 'meaning': 'xin chào', 'word_class': 'interjection', 'is_common': True},
            {'term': 'goodbye', 'pronunciation': 'gu̇d-ˈbī', 'meaning': 'tạm biệt', 'word_class': 'interjection', 'is_common': True},
            {'term': 'love', 'pronunciation': 'ləv', 'meaning': 'yêu', 'word_class': 'verb', 'is_common': True},
            {'term': 'eat', 'pronunciation': 'ēt', 'meaning': 'ăn', 'word_class': 'verb', 'is_common': True},
            {'term': 'drink', 'pronunciation': 'driŋk', 'meaning': 'uống', 'word_class': 'verb', 'is_common': True},
        ]
    
    def generate_translation_questions(self, lesson_title: str, count: int = 5, vi_to_en: bool = True) -> List[Dict]:
        """Generate translation questions from dictionary"""
        questions = []
        
        # Select common words
        source_words = [w for w in self.vietnamese_words if w['is_common']] if vi_to_en else [w for w in self.english_words if w['is_common']]
        
        if len(source_words) < count:
            source_words = self.vietnamese_words if vi_to_en else self.english_words
        
        selected = random.sample(source_words, min(count, len(source_words)))
        
        for idx, word in enumerate(selected, 1):
            if vi_to_en:
                question = {
                    'lesson_title': lesson_title,
                    'question_type': 'translation',
                    'question_text': f'Translate to English: {word["term"]}',
                    'vietnamese_text': word['term'],
                    'correct_answer': word['meaning'],
                    'question_order': idx,
                    'explanation': f'{word["term"]} means {word["meaning"]} in English.',
                    'points': 15
                }
            else:
                question = {
                    'lesson_title': lesson_title,
                    'question_type': 'translation',
                    'question_text': f'Translate to Vietnamese: {word["term"]}',
                    'vietnamese_text': word['meaning'],
                    'correct_answer': word['meaning'],
                    'question_order': idx,
                    'explanation': f'{word["term"]} is {word["meaning"]} in Vietnamese.',
                    'points': 15
                }
            questions.append(question)
        
        return questions
    
    def generate_matching_questions(self, lesson_title: str, pairs_count: int = 4) -> Dict:
        """Generate matching question with word pairs"""
        # Get common words
        vi_words = [w for w in self.vietnamese_words if w['is_common']][:pairs_count]
        
        if len(vi_words) < pairs_count:
            vi_words = self.vietnamese_words[:pairs_count]
        
        question = {
            'lesson_title': lesson_title,
            'question_type': 'matching',
            'question_text': 'Match Vietnamese words with their English translations',
            'question_order': 1,
            'explanation': 'Connect each Vietnamese word to its correct English meaning.',
            'points': 20,
            'pairs': []
        }
        
        for idx, word in enumerate(vi_words, 1):
            pair_id = f'pair{idx}'
            question['pairs'].append({
                'pair_id': pair_id,
                'items': [
                    {'text': word['term'], 'order': idx * 2 - 1},
                    {'text': word['meaning'], 'order': idx * 2}
                ]
            })
        
        return question
    
    def generate_fill_blank_questions(self, lesson_title: str, count: int = 3) -> List[Dict]:
        """Generate fill in the blank questions"""
        questions = []
        
        # Common words good for fill-blank
        words = [w for w in self.english_words if w['is_common'] and len(w['term'].split()) == 1][:count]
        
        if len(words) < count:
            words = [w for w in self.english_words if len(w['term'].split()) == 1][:count]
        
        templates = [
            "The word for '{meaning}' in English is ______.",
            "In English, we say ______ when we mean '{meaning}'.",
            "'{meaning}' is called ______ in English."
        ]
        
        for idx, word in enumerate(words, 1):
            template = random.choice(templates)
            question = {
                'lesson_title': lesson_title,
                'question_type': 'fill_blank',
                'question_text': template.format(meaning=word['meaning']),
                'correct_answer': word['term'],
                'question_order': idx,
                'explanation': f"The correct answer is '{word['term']}'.",
                'points': 10
            }
            questions.append(question)
        
        return questions
    
    def generate_multiple_choice(self, lesson_title: str, count: int = 5) -> List[Dict]:
        """Generate multiple choice questions"""
        questions = []
        
        words = [w for w in self.english_words if w['is_common']][:count]
        all_words = self.english_words.copy()
        
        for idx, word in enumerate(words, 1):
            # Get incorrect options
            wrong_options = random.sample([w for w in all_words if w['term'] != word['term']], 2)
            
            options = [
                {'text': word['meaning'], 'is_correct': True, 'order': 1},
                {'text': wrong_options[0]['meaning'], 'is_correct': False, 'order': 2},
                {'text': wrong_options[1]['meaning'], 'is_correct': False, 'order': 3}
            ]
            random.shuffle(options)
            
            question = {
                'lesson_title': lesson_title,
                'question_type': 'multiple_choice',
                'question_text': f'What does "{word["term"]}" mean?',
                'question_order': idx,
                'explanation': f'"{word["term"]}" means {word["meaning"]}.',
                'points': 10,
                'options': options
            }
            questions.append(question)
        
        return questions
    
    def export_to_sql(self, questions: List[Dict], output_file: str = 'GENERATED_QUESTIONS.sql'):
        """Export questions to SQL format"""
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write("-- =====================================================\n")
            f.write("-- AUTO-GENERATED QUESTIONS FROM DICTIONARY DATA\n")
            f.write("-- =====================================================\n\n")
            
            for q in questions:
                # Escape single quotes
                def escape_sql(text):
                    return text.replace("'", "''") if text else ''
                
                if q['question_type'] == 'translation':
                    f.write(f"-- Translation Question\n")
                    f.write(f"INSERT INTO lesson_questions (lesson_id, question_type, question_text, vietnamese_text, correct_answer, question_order, explanation, points) VALUES\n")
                    f.write(f"((SELECT id FROM lessons WHERE title = '{escape_sql(q['lesson_title'])}'), ")
                    f.write(f"'{q['question_type']}', '{escape_sql(q['question_text'])}', ")
                    f.write(f"'{escape_sql(q.get('vietnamese_text', ''))}', '{escape_sql(q['correct_answer'])}', ")
                    f.write(f"{q['question_order']}, '{escape_sql(q['explanation'])}', {q.get('points', 10)});\n\n")
                
                elif q['question_type'] == 'matching':
                    f.write(f"-- Matching Question\n")
                    f.write(f"INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation, points) VALUES\n")
                    f.write(f"((SELECT id FROM lessons WHERE title = '{escape_sql(q['lesson_title'])}'), ")
                    f.write(f"'{q['question_type']}', '{escape_sql(q['question_text'])}', ")
                    f.write(f"{q['question_order']}, '{escape_sql(q['explanation'])}', {q.get('points', 20)});\n\n")
                    
                    # Add matching pairs
                    for pair in q['pairs']:
                        for item in pair['items']:
                            f.write(f"INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES\n")
                            f.write(f"((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = '{escape_sql(q['lesson_title'])}') ")
                            f.write(f"AND question_order = {q['question_order']}), '{escape_sql(item['text'])}', true, {item['order']}, '{pair['pair_id']}');\n")
                        f.write("\n")
                
                elif q['question_type'] == 'fill_blank':
                    f.write(f"-- Fill Blank Question\n")
                    f.write(f"INSERT INTO lesson_questions (lesson_id, question_type, question_text, correct_answer, question_order, explanation, points) VALUES\n")
                    f.write(f"((SELECT id FROM lessons WHERE title = '{escape_sql(q['lesson_title'])}'), ")
                    f.write(f"'{q['question_type']}', '{escape_sql(q['question_text'])}', ")
                    f.write(f"'{escape_sql(q['correct_answer'])}', {q['question_order']}, '{escape_sql(q['explanation'])}', {q.get('points', 10)});\n\n")
                
                elif q['question_type'] == 'multiple_choice':
                    f.write(f"-- Multiple Choice Question\n")
                    f.write(f"INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation, points) VALUES\n")
                    f.write(f"((SELECT id FROM lessons WHERE title = '{escape_sql(q['lesson_title'])}'), ")
                    f.write(f"'{q['question_type']}', '{escape_sql(q['question_text'])}', ")
                    f.write(f"{q['question_order']}, '{escape_sql(q['explanation'])}', {q.get('points', 10)});\n\n")
                    
                    # Add options
                    for opt in q['options']:
                        f.write(f"INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES\n")
                        f.write(f"((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = '{escape_sql(q['lesson_title'])}') ")
                        f.write(f"AND question_order = {q['question_order']}), '{escape_sql(opt['text'])}', {str(opt['is_correct']).lower()}, {opt['order']});\n")
                    f.write("\n")
            
            f.write("COMMIT;\n")
        
        print(f"Generated {len(questions)} questions in {output_file}")


# =====================================================
# USAGE EXAMPLES
# =====================================================

def main():
    """Generate questions for various lesson topics"""
    generator = QuestionGenerator()
    generator.load_dictionary_data()
    
    all_questions = []
    
    # Generate for beginner lessons
    print("\n=== Generating Translation Questions ===")
    all_questions.extend(generator.generate_translation_questions('Basic Colors', count=5, vi_to_en=True))
    all_questions.extend(generator.generate_translation_questions('Hot Drinks', count=4, vi_to_en=True))
    all_questions.extend(generator.generate_translation_questions('Fruits', count=5, vi_to_en=True))
    
    print("\n=== Generating Matching Questions ===")
    all_questions.append(generator.generate_matching_questions('Basic Colors', pairs_count=4))
    all_questions.append(generator.generate_matching_questions('Family Members', pairs_count=5))
    all_questions.append(generator.generate_matching_questions('Body Parts', pairs_count=4))
    
    print("\n=== Generating Fill Blank Questions ===")
    all_questions.extend(generator.generate_fill_blank_questions('Basic Colors', count=3))
    all_questions.extend(generator.generate_fill_blank_questions('Numbers', count=4))
    
    print("\n=== Generating Multiple Choice Questions ===")
    all_questions.extend(generator.generate_multiple_choice('Vocabulary Practice', count=10))
    
    # Export to SQL
    print("\n=== Exporting to SQL ===")
    generator.export_to_sql(all_questions, 'DATABASE_DICTIONARY_QUESTIONS.sql')
    
    print(f"\n✅ Successfully generated {len(all_questions)} questions!")
    print("📁 Output file: DATABASE_DICTIONARY_QUESTIONS.sql")
    print("\n💡 To use: Run this SQL file after creating lessons in your database")


if __name__ == '__main__':
    main()


# =====================================================
# ADDITIONAL UTILITY FUNCTIONS
# =====================================================

def generate_conversation_questions(topic: str, scenarios: List[Dict]) -> List[Dict]:
    """Generate conversation questions for specific scenarios"""
    questions = []
    
    for idx, scenario in enumerate(scenarios, 1):
        question = {
            'lesson_title': topic,
            'question_type': 'conversation',
            'question_text': scenario['prompt'],
            'conversation_context': scenario['context'],
            'question_order': idx,
            'explanation': scenario['explanation'],
            'points': 15,
            'options': [
                {'text': scenario['correct'], 'is_correct': True, 'order': 1},
                {'text': scenario['wrong1'], 'is_correct': False, 'order': 2},
                {'text': scenario['wrong2'], 'is_correct': False, 'order': 3}
            ]
        }
        questions.append(question)
    
    return questions


# =====================================================
# SAMPLE USAGE FOR SPECIFIC TOPICS
# =====================================================

"""
Example: Generate questions for a specific lesson

generator = QuestionGenerator()
generator.load_dictionary_data()

# For Travel & Tourism lesson
travel_questions = []
travel_questions.extend(generator.generate_translation_questions('At the Airport', 5, vi_to_en=True))
travel_questions.append(generator.generate_matching_questions('At the Airport', 4))
travel_questions.extend(generator.generate_multiple_choice('At the Airport', 3))

generator.export_to_sql(travel_questions, 'travel_questions.sql')
"""
