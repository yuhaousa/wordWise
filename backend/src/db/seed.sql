-- ============================================================
-- Seed Data — English Learning App
-- Run: npm run db:seed  (remote) | npm run db:seed:local (local dev)
-- ============================================================

-- ── Words (A1 / A2 level) ─────────────────────────────────
INSERT OR IGNORE INTO words (
  word, definition, part_of_speech, cefr_level,
  chinese_meaning, synonyms, antonyms,
  example_sentence, phonetic, category
) VALUES
  ('happy',      'feeling or showing pleasure or contentment',                            'adjective', 'A1', '高兴的；快乐的',              'glad, joyful, cheerful',            'sad, unhappy, miserable',        'She is happy to see her friends.',            '/ˈhæpi/',       'emotions'),
  ('sad',        'feeling sorrow or unhappiness',                                         'adjective', 'A1', '难过的；悲伤的',              'unhappy, sorrowful, upset',          'happy, cheerful, joyful',         'He felt sad when he lost his toy.',           '/sæd/',         'emotions'),
  ('run',        'to move quickly on foot',                                               'verb',      'A1', '跑；奔跑',                    'jog, sprint, race',                  'walk, stop, stand',              'They run every morning in the park.',         '/rʌn/',         'actions'),
  ('eat',        'to put food into the mouth and swallow it',                             'verb',      'A1', '吃',                          'have, consume, dine',                'fast, starve, avoid',            'We eat breakfast at seven o''clock.',         '/iːt/',         'actions'),
  ('book',       'a written or printed work consisting of pages bound together',          'noun',      'A1', '书；书籍',                    'volume, publication, text',          'none',                            'I read a book before bed.',                    '/bʊk/',         'objects'),
  ('school',     'an institution where children are educated',                            'noun',      'A1', '学校',                        'academy, institute, campus',         'none',                            'She goes to school every weekday.',            '/skuːl/',       'places'),
  ('friend',     'a person with whom one has a bond of mutual affection',                 'noun',      'A1', '朋友',                        'companion, buddy, pal',              'enemy, rival, foe',              'My best friend lives next door.',              '/frend/',       'people'),
  ('beautiful',  'pleasing the senses or mind aesthetically',                             'adjective', 'A2', '美丽的；漂亮的',              'pretty, lovely, attractive',         'ugly, plain, unattractive',       'The sunset was absolutely beautiful.',         '/ˈbjuːtɪfʊl/', 'descriptions'),
  ('important',  'of great significance or value',                                        'adjective', 'A2', '重要的',                      'significant, vital, crucial',        'minor, trivial, unimportant',     'It is important to study every day.',          '/ɪmˈpɔːtənt/', 'descriptions'),
  ('travel',     'to make a journey, typically of some length',                           'verb',      'A2', '旅行；出行',                  'journey, tour, trip',                'stay, remain, settle',           'I love to travel to new countries.',           '/ˈtrævəl/',    'actions'),
  ('exciting',   'causing great enthusiasm and eagerness',                                'adjective', 'B1', '令人兴奋的',                  'thrilling, stimulating, inspiring',  'boring, dull, tedious',          'The adventure was really exciting.',           '/ɪkˈsaɪtɪŋ/',  'emotions'),
  ('achieve',    'successfully bring about or reach a desired goal by effort',            'verb',      'B1', '实现；达成',                  'accomplish, attain, realize',        'fail, lose, miss',               'You can achieve anything with hard work.',     '/əˈtʃiːv/',    'actions'),
  ('challenge',  'a situation that tests someone''s abilities',                           'noun',      'B1', '挑战；难题',                  'test, trial, difficulty',            'advantage, ease, comfort',       'Learning English is a great challenge.',       '/ˈtʃælɪndʒ/', 'general'),
  ('opportunity','a set of circumstances that makes it possible to do something',         'noun',      'B2', '机会；机遇',                  'chance, occasion, opening',          'obstacle, barrier, setback',     'Study abroad is a great opportunity.',         '/ˌɒpəˈtjuːnɪti/', 'general'),
  ('perspective','a particular way of considering something',                             'noun',      'B2', '观点；视角',                  'viewpoint, outlook, angle',          'bias, narrowness, blindness',    'Travel broadens your perspective.',            '/pəˈspektɪv/', 'general');

-- Backfill lexical metadata for existing rows when INSERT OR IGNORE does not run.
UPDATE words
SET
  chinese_meaning = CASE word
    WHEN 'happy' THEN '高兴的；快乐的'
    WHEN 'sad' THEN '难过的；悲伤的'
    WHEN 'run' THEN '跑；奔跑'
    WHEN 'eat' THEN '吃'
    WHEN 'book' THEN '书；书籍'
    WHEN 'school' THEN '学校'
    WHEN 'friend' THEN '朋友'
    WHEN 'beautiful' THEN '美丽的；漂亮的'
    WHEN 'important' THEN '重要的'
    WHEN 'travel' THEN '旅行；出行'
    WHEN 'exciting' THEN '令人兴奋的'
    WHEN 'achieve' THEN '实现；达成'
    WHEN 'challenge' THEN '挑战；难题'
    WHEN 'opportunity' THEN '机会；机遇'
    WHEN 'perspective' THEN '观点；视角'
    ELSE chinese_meaning
  END,
  synonyms = CASE word
    WHEN 'happy' THEN 'glad, joyful, cheerful'
    WHEN 'sad' THEN 'unhappy, sorrowful, upset'
    WHEN 'run' THEN 'jog, sprint, race'
    WHEN 'eat' THEN 'have, consume, dine'
    WHEN 'book' THEN 'volume, publication, text'
    WHEN 'school' THEN 'academy, institute, campus'
    WHEN 'friend' THEN 'companion, buddy, pal'
    WHEN 'beautiful' THEN 'pretty, lovely, attractive'
    WHEN 'important' THEN 'significant, vital, crucial'
    WHEN 'travel' THEN 'journey, tour, trip'
    WHEN 'exciting' THEN 'thrilling, stimulating, inspiring'
    WHEN 'achieve' THEN 'accomplish, attain, realize'
    WHEN 'challenge' THEN 'test, trial, difficulty'
    WHEN 'opportunity' THEN 'chance, occasion, opening'
    WHEN 'perspective' THEN 'viewpoint, outlook, angle'
    ELSE synonyms
  END,
  antonyms = CASE word
    WHEN 'happy' THEN 'sad, unhappy, miserable'
    WHEN 'sad' THEN 'happy, cheerful, joyful'
    WHEN 'run' THEN 'walk, stop, stand'
    WHEN 'eat' THEN 'fast, starve, avoid'
    WHEN 'book' THEN 'none'
    WHEN 'school' THEN 'none'
    WHEN 'friend' THEN 'enemy, rival, foe'
    WHEN 'beautiful' THEN 'ugly, plain, unattractive'
    WHEN 'important' THEN 'minor, trivial, unimportant'
    WHEN 'travel' THEN 'stay, remain, settle'
    WHEN 'exciting' THEN 'boring, dull, tedious'
    WHEN 'achieve' THEN 'fail, lose, miss'
    WHEN 'challenge' THEN 'advantage, ease, comfort'
    WHEN 'opportunity' THEN 'obstacle, barrier, setback'
    WHEN 'perspective' THEN 'bias, narrowness, blindness'
    ELSE antonyms
  END
WHERE word IN (
  'happy','sad','run','eat','book','school','friend','beautiful','important',
  'travel','exciting','achieve','challenge','opportunity','perspective'
);

-- ── Sentences ─────────────────────────────────────────────
INSERT OR IGNORE INTO sentences (sentence, translation, cefr_level, category, word_ids, grammar_focus) VALUES
  ('I am happy today.',                          'Tôi hạnh phúc hôm nay.',       'A1', 'daily life',  '[1]',     'to be + adjective'),
  ('She eats an apple every morning.',           'Cô ấy ăn táo mỗi sáng.',       'A1', 'habits',      '[4]',     'simple present'),
  ('My friends and I run in the park.',          'Tôi và bạn bè chạy trong công viên.', 'A1', 'activities', '[3,7]', 'simple present plural'),
  ('The book on the table is very interesting.', 'Cuốn sách trên bàn rất thú vị.','A2', 'daily life',  '[5]',     'adjective + noun'),
  ('Traveling to new places is exciting.',       'Du lịch đến những nơi mới thật thú vị.', 'B1', 'travel', '[10,11]', 'gerund as subject'),
  ('It is important to seize every opportunity.','Điều quan trọng là nắm bắt mọi cơ hội.', 'B2', 'motivation', '[9,14]', 'it is + adjective + infinitive');

-- ── Quiz Questions ─────────────────────────────────────────
INSERT OR IGNORE INTO quiz_questions (type, question, correct_answer, options, word_id, sentence_id, cefr_level) VALUES
  ('word_definition',
   'What does "happy" mean?',
   'feeling or showing pleasure or contentment',
   '["feeling or showing pleasure or contentment","feeling sorrow","moving quickly","an institution for learning"]',
   1, NULL, 'A1'),

  ('choose_word',
   'Choose the correct word: She ___ an apple every morning.',
   'eats',
   '["eats","eat","eating","eaten"]',
   4, 2, 'A1'),

  ('fill_blank',
   'Complete the sentence: It is ___ to study every day.',
   'important',
   '["important","beautiful","exciting","sad"]',
   9, NULL, 'A2'),

  ('sentence_reorder',
   'Reorder the words to make a correct sentence: [places / exciting / to / Traveling / is / new]',
   'Traveling to new places is exciting.',
   '["Traveling to new places is exciting.","Exciting traveling to new is places.","New places traveling to is exciting.","Is traveling exciting to new places."]',
   NULL, 5, 'B1'),

  ('spelling',
   'Spell the word that means "a situation that tests your abilities".',
   'challenge',
   '["challenge","challange","chalenge","chalenege"]',
   13, NULL, 'B1'),

  ('word_definition',
   'What does "opportunity" mean?',
   'a set of circumstances that makes it possible to do something',
   '["a set of circumstances that makes it possible to do something","feeling great enthusiasm","moving quickly on foot","a written work of pages"]',
   14, NULL, 'B2');
