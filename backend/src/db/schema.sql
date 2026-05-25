-- ============================================================
-- English Learning App — D1 Schema
-- Run: npm run db:migrate  (remote) | npm run db:migrate:local (local dev)
-- ============================================================

-- ── Words ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS words (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  word            TEXT    NOT NULL UNIQUE,
  definition      TEXT    NOT NULL,
  part_of_speech  TEXT    NOT NULL CHECK(part_of_speech IN ('noun','verb','adjective','adverb','preposition','conjunction','pronoun','other')),
  cefr_level      TEXT    NOT NULL CHECK(cefr_level IN ('A1','A2','B1','B2','C1','C2')),
  chinese_meaning TEXT    NOT NULL DEFAULT '',
  synonyms        TEXT    NOT NULL DEFAULT '',
  antonyms        TEXT    NOT NULL DEFAULT '',
  example_sentence TEXT   NOT NULL DEFAULT '',
  phonetic        TEXT    NOT NULL DEFAULT '',
  category        TEXT    NOT NULL DEFAULT 'general',
  created_at      TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_words_level    ON words(cefr_level);
CREATE INDEX IF NOT EXISTS idx_words_category ON words(category);

-- ── Sentences ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sentences (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  sentence       TEXT    NOT NULL,
  translation    TEXT    NOT NULL DEFAULT '',
  cefr_level     TEXT    NOT NULL CHECK(cefr_level IN ('A1','A2','B1','B2','C1','C2')),
  category       TEXT    NOT NULL DEFAULT 'general',
  word_ids       TEXT    NOT NULL DEFAULT '[]',   -- JSON array of word IDs
  grammar_focus  TEXT    NOT NULL DEFAULT '',
  created_at     TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_sentences_level    ON sentences(cefr_level);
CREATE INDEX IF NOT EXISTS idx_sentences_category ON sentences(category);

-- ── Quiz Questions ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS quiz_questions (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  type            TEXT    NOT NULL CHECK(type IN ('word_definition','fill_blank','sentence_reorder','choose_word','spelling')),
  question        TEXT    NOT NULL,
  correct_answer  TEXT    NOT NULL,
  options         TEXT    NOT NULL DEFAULT '[]',  -- JSON array of 4 choices
  word_id         INTEGER REFERENCES words(id) ON DELETE SET NULL,
  sentence_id     INTEGER REFERENCES sentences(id) ON DELETE SET NULL,
  cefr_level      TEXT    NOT NULL CHECK(cefr_level IN ('A1','A2','B1','B2','C1','C2')),
  created_at      TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_quiz_level ON quiz_questions(cefr_level);
CREATE INDEX IF NOT EXISTS idx_quiz_type  ON quiz_questions(type);

-- ── User Progress ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_progress (
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id          TEXT    NOT NULL,
  item_type        TEXT    NOT NULL CHECK(item_type IN ('word','sentence')),
  item_id          INTEGER NOT NULL,
  status           TEXT    NOT NULL DEFAULT 'new' CHECK(status IN ('new','learning','reviewing','mastered')),
  correct_count    INTEGER NOT NULL DEFAULT 0,
  wrong_count      INTEGER NOT NULL DEFAULT 0,
  next_review_at   TEXT    NOT NULL DEFAULT (datetime('now')),
  last_reviewed_at TEXT    NOT NULL DEFAULT (datetime('now')),
  created_at       TEXT    NOT NULL DEFAULT (datetime('now')),
  UNIQUE(user_id, item_type, item_id)
);

CREATE INDEX IF NOT EXISTS idx_progress_user   ON user_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_progress_review ON user_progress(user_id, next_review_at);

-- ── Quiz Results ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS quiz_results (
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id          TEXT    NOT NULL,
  quiz_question_id INTEGER NOT NULL REFERENCES quiz_questions(id) ON DELETE CASCADE,
  is_correct       INTEGER NOT NULL DEFAULT 0,   -- boolean (0/1)
  answered_at      TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_results_user ON quiz_results(user_id);

-- ── Wrong Words Library ────────────────────────────────────
-- Tracks every word the student got wrong (quiz or flashcard).
-- wrong_count increments on each miss; mastered=1 lets the user
-- mark it as learned so it no longer appears in the library list.
CREATE TABLE IF NOT EXISTS wrong_words (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id       TEXT    NOT NULL,
  word_id       INTEGER NOT NULL REFERENCES words(id) ON DELETE CASCADE,
  wrong_count   INTEGER NOT NULL DEFAULT 1,
  last_wrong_at TEXT    NOT NULL DEFAULT (datetime('now')),
  mastered      INTEGER NOT NULL DEFAULT 0,   -- 0 = still in library, 1 = learned
  UNIQUE(user_id, word_id)
);

CREATE INDEX IF NOT EXISTS idx_wrong_user    ON wrong_words(user_id);
CREATE INDEX IF NOT EXISTS idx_wrong_mastered ON wrong_words(user_id, mastered);
