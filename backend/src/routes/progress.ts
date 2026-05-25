import { Hono } from 'hono';
import { Env, ApiResponse, UserProgress } from '../types/index';

const progress = new Hono<{ Bindings: Env }>();

// Spaced repetition: next interval in minutes based on correct streak
function nextReviewInterval(correctCount: number, wrongCount: number): number {
  const streak = correctCount - wrongCount;
  if (streak <= 0)  return 10;        // 10 min — almost immediately
  if (streak === 1) return 60;        // 1 hour
  if (streak === 2) return 60 * 8;    // 8 hours
  if (streak === 3) return 60 * 24;   // 1 day
  if (streak === 4) return 60 * 72;   // 3 days
  if (streak === 5) return 60 * 168;  // 1 week
  return 60 * 720;                    // 1 month — mastered
}

function statusFromStreak(correctCount: number, wrongCount: number): UserProgress['status'] {
  const streak = correctCount - wrongCount;
  if (streak <= 0)  return 'new';
  if (streak <= 2)  return 'learning';
  if (streak <= 5)  return 'reviewing';
  return 'mastered';
}

// GET /api/progress/:userId — get all progress items for a user
progress.get('/:userId', async (c) => {
  const userId = c.req.param('userId');
  const { item_type, status } = c.req.query();

  let query = 'SELECT * FROM user_progress WHERE user_id = ?';
  const params: unknown[] = [userId];

  if (item_type) { query += ' AND item_type = ?'; params.push(item_type); }
  if (status)    { query += ' AND status = ?';    params.push(status); }

  query += ' ORDER BY next_review_at ASC';

  const rows = await c.env.DB.prepare(query).bind(...params).all<UserProgress>();
  return c.json({ success: true, data: rows.results } as ApiResponse<UserProgress[]>);
});

// GET /api/progress/:userId/due — items due for review right now
progress.get('/:userId/due', async (c) => {
  const userId = c.req.param('userId');
  const { item_type, limit = '20' } = c.req.query();

  let query = `SELECT * FROM user_progress
               WHERE user_id = ? AND next_review_at <= datetime('now') AND status != 'mastered'`;
  const params: unknown[] = [userId];

  if (item_type) { query += ' AND item_type = ?'; params.push(item_type); }
  query += ' ORDER BY next_review_at ASC LIMIT ?';
  params.push(parseInt(limit));

  const rows = await c.env.DB.prepare(query).bind(...params).all<UserProgress>();
  return c.json({ success: true, data: rows.results } as ApiResponse<UserProgress[]>);
});

// POST /api/progress/update — update progress after a review
progress.post('/update', async (c) => {
  const userId = c.req.header('X-User-Id') ?? 'anonymous';
  const body = await c.req.json<{
    item_type: 'word' | 'sentence';
    item_id: number;
    is_correct: boolean;
  }>();

  const { item_type, item_id, is_correct } = body;
  if (!item_type || !item_id) {
    return c.json({ success: false, error: 'item_type and item_id are required' }, 400);
  }

  // Upsert progress
  const existing = await c.env.DB.prepare(
    'SELECT * FROM user_progress WHERE user_id = ? AND item_type = ? AND item_id = ?'
  ).bind(userId, item_type, item_id).first<UserProgress>();

  const correct = (existing?.correct_count ?? 0) + (is_correct ? 1 : 0);
  const wrong   = (existing?.wrong_count   ?? 0) + (is_correct ? 0 : 1);
  const intervalMin = nextReviewInterval(correct, wrong);
  const newStatus   = statusFromStreak(correct, wrong);
  const nextReview  = new Date(Date.now() + intervalMin * 60 * 1000).toISOString();

  await c.env.DB.prepare(
    `INSERT INTO user_progress (user_id, item_type, item_id, status, correct_count, wrong_count, next_review_at, last_reviewed_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'))
     ON CONFLICT(user_id, item_type, item_id) DO UPDATE SET
       status           = excluded.status,
       correct_count    = excluded.correct_count,
       wrong_count      = excluded.wrong_count,
       next_review_at   = excluded.next_review_at,
       last_reviewed_at = datetime('now')`
  )
    .bind(userId, item_type, item_id, newStatus, correct, wrong, nextReview)
    .run();

  return c.json({
    success: true,
    data: { status: newStatus, next_review_at: nextReview, interval_minutes: intervalMin },
  });
});

// GET /api/progress/:userId/summary — dashboard stats
progress.get('/:userId/summary', async (c) => {
  const userId = c.req.param('userId');

  const [wordStats, sentenceStats, dueCount] = await Promise.all([
    c.env.DB.prepare(
      `SELECT status, COUNT(*) as count FROM user_progress
       WHERE user_id = ? AND item_type = 'word' GROUP BY status`
    ).bind(userId).all(),
    c.env.DB.prepare(
      `SELECT status, COUNT(*) as count FROM user_progress
       WHERE user_id = ? AND item_type = 'sentence' GROUP BY status`
    ).bind(userId).all(),
    c.env.DB.prepare(
      `SELECT COUNT(*) as due FROM user_progress
       WHERE user_id = ? AND next_review_at <= datetime('now') AND status != 'mastered'`
    ).bind(userId).first<{ due: number }>(),
  ]);

  return c.json({
    success: true,
    data: {
      words: wordStats.results,
      sentences: sentenceStats.results,
      due_for_review: dueCount?.due ?? 0,
    },
  });
});

export default progress;
