import { Hono } from 'hono';
import { Env, ApiResponse } from '../types/index';

export interface WrongWordRow {
  id: number;
  user_id: string;
  word_id: number;
  wrong_count: number;
  last_wrong_at: string;
  mastered: number;
  // joined from words table
  word?: string;
  definition?: string;
  part_of_speech?: string;
  cefr_level?: string;
  example_sentence?: string;
  phonetic?: string;
}

const wrongWords = new Hono<{ Bindings: Env }>();

// ── GET /api/wrong-words/:userId ────────────────────────────
// Returns the full wrong-words library for a user (un-mastered by default).
// Query params:
//   include_mastered=true  — also return words the user has marked learned
//   level=B1               — filter by CEFR level
//   limit=50, offset=0     — pagination
wrongWords.get('/:userId', async (c) => {
  const userId = c.req.param('userId');
  const {
    include_mastered = 'false',
    level,
    limit = '50',
    offset = '0',
  } = c.req.query();

  let query = `
    SELECT ww.id, ww.user_id, ww.word_id, ww.wrong_count, ww.last_wrong_at, ww.mastered,
           w.word, w.definition, w.part_of_speech, w.cefr_level, w.example_sentence, w.phonetic
    FROM wrong_words ww
    JOIN words w ON w.id = ww.word_id
    WHERE ww.user_id = ?
  `;
  const params: unknown[] = [userId];

  if (include_mastered !== 'true') {
    query += ' AND ww.mastered = 0';
  }
  if (level) {
    query += ' AND w.cefr_level = ?';
    params.push(level);
  }

  query += ' ORDER BY ww.wrong_count DESC, ww.last_wrong_at DESC LIMIT ? OFFSET ?';
  params.push(parseInt(limit), parseInt(offset));

  const rows = await c.env.DB.prepare(query).bind(...params).all<WrongWordRow>();

  // Total count for pagination
  let countQuery = `
    SELECT COUNT(*) as total FROM wrong_words ww
    JOIN words w ON w.id = ww.word_id
    WHERE ww.user_id = ?
  `;
  const countParams: unknown[] = [userId];
  if (include_mastered !== 'true') countQuery += ' AND ww.mastered = 0';
  if (level) { countQuery += ' AND w.cefr_level = ?'; countParams.push(level); }

  const countRow = await c.env.DB.prepare(countQuery).bind(...countParams).first<{ total: number }>();

  return c.json({
    success: true,
    data: rows.results,
    meta: { total: countRow?.total ?? 0, limit: parseInt(limit), offset: parseInt(offset) },
  });
});

// ── POST /api/wrong-words ───────────────────────────────────
// Record (or increment) a wrong word.
// Body: { word_id: number }
// Uses X-User-Id header for user identification.
wrongWords.post('/', async (c) => {
  const userId = c.req.header('X-User-Id') ?? 'anonymous';
  const body = await c.req.json<{ word_id: number }>();

  if (!body.word_id) {
    return c.json({ success: false, error: 'word_id is required' }, 400);
  }

  // Verify the word exists
  const word = await c.env.DB.prepare('SELECT id FROM words WHERE id = ?')
    .bind(body.word_id).first();
  if (!word) {
    return c.json({ success: false, error: 'Word not found' }, 404);
  }

  // Upsert: insert new entry or increment wrong_count; reset mastered to 0 (got it wrong again)
  await c.env.DB.prepare(`
    INSERT INTO wrong_words (user_id, word_id, wrong_count, last_wrong_at, mastered)
    VALUES (?, ?, 1, datetime('now'), 0)
    ON CONFLICT(user_id, word_id) DO UPDATE SET
      wrong_count   = wrong_count + 1,
      last_wrong_at = datetime('now'),
      mastered      = 0
  `).bind(userId, body.word_id).run();

  const row = await c.env.DB.prepare(`
    SELECT ww.*, w.word, w.definition, w.cefr_level
    FROM wrong_words ww JOIN words w ON w.id = ww.word_id
    WHERE ww.user_id = ? AND ww.word_id = ?
  `).bind(userId, body.word_id).first<WrongWordRow>();

  return c.json({ success: true, data: row }, 201);
});

// ── PATCH /api/wrong-words/:userId/:wordId/mastered ─────────
// Mark a word as learned (mastered=1) or un-master it (mastered=0).
// Body: { mastered: boolean }
wrongWords.patch('/:userId/:wordId/mastered', async (c) => {
  const userId  = c.req.param('userId');
  const wordId  = parseInt(c.req.param('wordId'));
  const body    = await c.req.json<{ mastered: boolean }>();

  const result = await c.env.DB.prepare(`
    UPDATE wrong_words SET mastered = ?
    WHERE user_id = ? AND word_id = ?
  `).bind(body.mastered ? 1 : 0, userId, wordId).run();

  if (result.meta.changes === 0) {
    return c.json({ success: false, error: 'Entry not found' }, 404);
  }

  return c.json({ success: true, data: { mastered: body.mastered } });
});

// ── DELETE /api/wrong-words/:userId/:wordId ─────────────────
// Remove a word from the library entirely.
wrongWords.delete('/:userId/:wordId', async (c) => {
  const userId = c.req.param('userId');
  const wordId = parseInt(c.req.param('wordId'));

  await c.env.DB.prepare(
    'DELETE FROM wrong_words WHERE user_id = ? AND word_id = ?'
  ).bind(userId, wordId).run();

  return c.json({ success: true, data: null });
});

// ── GET /api/wrong-words/:userId/practice ──────────────────
// Returns up to `count` un-mastered wrong words formatted as flashcard data.
// Used by the WrongWordsScreen practice mode.
wrongWords.get('/:userId/practice', async (c) => {
  const userId = c.req.param('userId');
  const { count = '10', level } = c.req.query();

  let query = `
    SELECT w.id, w.word, w.definition, w.part_of_speech, w.cefr_level,
           w.example_sentence, w.phonetic, ww.wrong_count
    FROM wrong_words ww
    JOIN words w ON w.id = ww.word_id
    WHERE ww.user_id = ? AND ww.mastered = 0
  `;
  const params: unknown[] = [userId];

  if (level) { query += ' AND w.cefr_level = ?'; params.push(level); }

  // Prioritise most-missed words first
  query += ' ORDER BY ww.wrong_count DESC, RANDOM() LIMIT ?';
  params.push(parseInt(count));

  const rows = await c.env.DB.prepare(query).bind(...params).all();
  return c.json({ success: true, data: rows.results } as ApiResponse<unknown[]>);
});

// ── GET /api/wrong-words/:userId/stats ─────────────────────
// Summary counts for the progress dashboard.
wrongWords.get('/:userId/stats', async (c) => {
  const userId = c.req.param('userId');

  const stats = await c.env.DB.prepare(`
    SELECT
      COUNT(*) FILTER (WHERE mastered = 0) AS active,
      COUNT(*) FILTER (WHERE mastered = 1) AS mastered,
      COALESCE(SUM(wrong_count), 0)         AS total_misses
    FROM wrong_words
    WHERE user_id = ?
  `).bind(userId).first<{ active: number; mastered: number; total_misses: number }>();

  return c.json({ success: true, data: stats });
});

export default wrongWords;
