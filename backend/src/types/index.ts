// ────────────────────────────────────────────────────────────
// Cloudflare environment bindings
// ────────────────────────────────────────────────────────────
export interface Env {
  DB: D1Database;
  ENVIRONMENT: string;
}

// ────────────────────────────────────────────────────────────
// Domain models (mirror D1 tables)
// ────────────────────────────────────────────────────────────

export type CEFRLevel = 'A1' | 'A2' | 'B1' | 'B2' | 'C1' | 'C2';
export type PartOfSpeech = 'noun' | 'verb' | 'adjective' | 'adverb' | 'preposition' | 'conjunction' | 'pronoun' | 'other';

export interface Word {
  id: number;
  word: string;
  definition: string;
  part_of_speech: PartOfSpeech;
  cefr_level: CEFRLevel;
  chinese_meaning: string;
  synonyms: string;
  antonyms: string;
  example_sentence: string;
  phonetic: string;
  category: string;
  created_at: string;
}

export interface Sentence {
  id: number;
  sentence: string;
  translation: string;
  cefr_level: CEFRLevel;
  category: string;
  word_ids: string;        // JSON array string, e.g. "[1,3,7]"
  grammar_focus: string;
  created_at: string;
}

export interface QuizQuestion {
  id: number;
  type: QuizType;
  question: string;
  correct_answer: string;
  options: string;         // JSON array string of 4 options
  word_id: number | null;
  sentence_id: number | null;
  cefr_level: CEFRLevel;
  created_at: string;
}

export type QuizType = 'word_definition' | 'fill_blank' | 'sentence_reorder' | 'choose_word' | 'spelling';

export interface UserProgress {
  id: number;
  user_id: string;
  item_type: 'word' | 'sentence';
  item_id: number;
  status: 'new' | 'learning' | 'reviewing' | 'mastered';
  correct_count: number;
  wrong_count: number;
  next_review_at: string;
  last_reviewed_at: string;
  created_at: string;
}

export interface QuizResult {
  id: number;
  user_id: string;
  quiz_question_id: number;
  is_correct: boolean;
  answered_at: string;
}

// ────────────────────────────────────────────────────────────
// API response shapes
// ────────────────────────────────────────────────────────────

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  meta?: {
    total?: number;
    page?: number;
    limit?: number;
  };
}

export interface PaginationParams {
  page: number;
  limit: number;
}
