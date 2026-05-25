class Word {
  final int id;
  final String word;
  final String definition;
  final String chineseMeaning;
  final String synonyms;
  final String antonyms;
  final String partOfSpeech;
  final String cefrLevel;
  final String exampleSentence;
  final String phonetic;
  final String category;

  const Word({
    required this.id,
    required this.word,
    required this.definition,
    required this.chineseMeaning,
    required this.synonyms,
    required this.antonyms,
    required this.partOfSpeech,
    required this.cefrLevel,
    required this.exampleSentence,
    required this.phonetic,
    required this.category,
  });

  factory Word.fromJson(Map<String, dynamic> json) => Word(
        id:              json['id'] as int,
        word:            json['word'] as String,
        definition:      json['definition'] as String,
        chineseMeaning:  json['chinese_meaning'] as String? ?? '',
        synonyms:        json['synonyms'] as String? ?? '',
        antonyms:        json['antonyms'] as String? ?? '',
        partOfSpeech:    json['part_of_speech'] as String,
        cefrLevel:       json['cefr_level'] as String,
        exampleSentence: json['example_sentence'] as String? ?? '',
        phonetic:        json['phonetic'] as String? ?? '',
        category:        json['category'] as String? ?? 'general',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'definition': definition,
        'chinese_meaning': chineseMeaning,
        'synonyms': synonyms,
        'antonyms': antonyms,
        'part_of_speech': partOfSpeech,
        'cefr_level': cefrLevel,
        'example_sentence': exampleSentence,
        'phonetic': phonetic,
        'category': category,
      };

  @override
  String toString() => 'Word($word [$cefrLevel])';
}
