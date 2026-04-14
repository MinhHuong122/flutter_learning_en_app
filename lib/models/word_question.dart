class WordQuestion {
  final int id;
  final int levelNumber;
  final String word;
  final String? question; // Vietnamese question/clue
  final String hint;
  final int startRow;
  final int startCol;
  final String direction; // 'across' or 'down'
  final int number;
  final String? image; // Optional image URL for visual clue

  WordQuestion({
    required this.id,
    required this.levelNumber,
    required this.word,
    this.question,
    required this.hint,
    required this.startRow,
    required this.startCol,
    required this.direction,
    required this.number,
    this.image,
  });

  factory WordQuestion.fromJson(Map<String, dynamic> json) {
    return WordQuestion(
      id: json['id'] as int,
      // Handle both camelCase and snake_case for Supabase compatibility
      levelNumber: (json['levelNumber'] ?? json['level_number']) as int,
      word: json['word'] as String,
      question: json['question'] as String?,
      hint: json['hint'] as String,
      // Handle both camelCase and snake_case
      startRow: (json['startRow'] ?? json['start_row']) as int,
      startCol: (json['startCol'] ?? json['start_col']) as int,
      direction: json['direction'] as String,
      // Handle both camelCase and snake_case
      number: (json['number'] ?? json['question_number']) as int,
      // Handle both image and image_url from Supabase
      image: (json['image'] ?? json['image_url']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'levelNumber': levelNumber,
      'word': word,
      'question': question,
      'hint': hint,
      'startRow': startRow,
      'startCol': startCol,
      'direction': direction,
      'number': number,
      'image': image,
    };
  }
}
