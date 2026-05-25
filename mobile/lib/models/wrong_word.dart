class WrongWord {
  final int    id;
  final String userId;
  final int    wordId;
  final int    wrongCount;
  final String lastWrongAt;
  final bool   mastered;

  // Joined from words table
  final String word;
  final String definition;
  final String partOfSpeech;
  final String cefrLevel;
  final String exampleSentence;
  final String phonetic;

  const WrongWord({
    required this.id,
    required this.userId,
    required this.wordId,
    required this.wrongCount,
    required this.lastWrongAt,
    required this.mastered,
    required this.word,
    required this.definition,
    required this.partOfSpeech,
    required this.cefrLevel,
    required this.exampleSentence,
    required this.phonetic,
  });

  factory WrongWord.fromJson(Map<String, dynamic> json) => WrongWord(
        id:              json['id']              as int,
        userId:          json['user_id']         as String,
        wordId:          json['word_id']         as int,
        wrongCount:      json['wrong_count']     as int,
        lastWrongAt:     json['last_wrong_at']   as String,
        mastered:        (json['mastered'] as int) == 1,
        word:            json['word']            as String? ?? '',
        definition:      json['definition']      as String? ?? '',
        partOfSpeech:    json['part_of_speech']  as String? ?? '',
        cefrLevel:       json['cefr_level']      as String? ?? '',
        exampleSentence: json['example_sentence'] as String? ?? '',
        phonetic:        json['phonetic']        as String? ?? '',
      );

  WrongWord copyWith({bool? mastered}) => WrongWord(
        id:              id,
        userId:          userId,
        wordId:          wordId,
        wrongCount:      wrongCount,
        lastWrongAt:     lastWrongAt,
        mastered:        mastered ?? this.mastered,
        word:            word,
        definition:      definition,
        partOfSpeech:    partOfSpeech,
        cefrLevel:       cefrLevel,
        exampleSentence: exampleSentence,
        phonetic:        phonetic,
      );
}

class WrongWordStats {
  final int active;
  final int mastered;
  final int totalMisses;

  const WrongWordStats({
    required this.active,
    required this.mastered,
    required this.totalMisses,
  });

  factory WrongWordStats.fromJson(Map<String, dynamic> json) => WrongWordStats(
        active:      json['active']       as int? ?? 0,
        mastered:    json['mastered']     as int? ?? 0,
        totalMisses: json['total_misses'] as int? ?? 0,
      );

  int get total => active + mastered;
}
