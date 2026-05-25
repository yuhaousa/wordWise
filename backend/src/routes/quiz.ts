import { Hono } from 'hono';
import { Env, ApiResponse, QuizQuestion, QuizResult } from '../types/index';

const quiz = new Hono<{ Bindings: Env }>();

// GET /api/quiz/questions — fetch a quiz session (random questions)
quiz.get('/questions', async (c) => {
  const { level, type, count = '10' } = c.req.query();

  let query = 'SELECT * FROM quiz_questions WHERE 1=1';
  const params: unknown[] = [];

  if (level) {
    query += ' AND cefr_level = ?';
    params.push(level.toUpperCase());
  }
  if (type) {
    query += ' AND type = ?';
    params.push(type);
  }

  query += ' ORDER BY RANDOM() LIMIT ?';
  params.push(parseInt(count));

  const rows = await c.env.DB.prepare(query).bind(...params).all<QuizQuestion>();
  return c.json({ success: true, data: rows.results } as ApiResponse<QuizQuestion[]>);
});

// GET /api/quiz/questions/:id
quiz.get('/questions/:id', async (c) => {
  const id = parseInt(c.req.param('id'));
  if (isNaN(id)) return c.json({ success: false, error: 'Invalid ID' }, 400);

  const q = await c.env.DB.prepare('SELECT * FROM quiz_questions WHERE id = ?')
    .bind(id)
    .first<QuizQuestion>();
  if (!q) return c.json({ success: false, error: 'Question not found' }, 404);

  return c.json({ success: true, data: q } as ApiResponse<QuizQuestion>);
});

// POST /api/quiz/submit — submit a single answer
quiz.post('/submit', async (c) => {
  const userId = c.req.header('X-User-Id') ?? 'anonymous';
  const body = await c.req.json<{ question_id: number; answer: string }>();
  const { question_id, answer } = body;

  if (!question_id || answer === undefined) {
    return c.json({ success: false, error: 'question_id and answer are required' }, 400);
  }

  const question = await c.env.DB.prepare('SELECT * FROM quiz_questions WHERE id = ?')
    .bind(question_id)
    .first<QuizQuestion>();

  if (!question) return c.json({ success: false, error: 'Question not found' }, 404);

  const isCorrect = answer.trim().toLowerCase() === question.correct_answer.trim().toLowerCase();

  // Record the result
  await c.env.DB.prepare(
    'INSERT INTO quiz_results (user_id, quiz_question_id, is_correct) VALUES (?, ?, ?)'
  )
    .bind(userId, question_id, isCorrect ? 1 : 0)
    .run();

  return c.json({
    success: true,
    data: {
      is_correct: isCorrect,
      correct_answer: question.correct_answer,
    },
  });
});

// GET /api/quiz/stats/:userId — user quiz statistics
quiz.get('/stats/:userId', async (c) => {
  const userId = c.req.param('userId');

  const stats = await c.env.DB.prepare(
    `SELECT
       COUNT(*)                                          AS total_answered,
       SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) AS total_correct,
       ROUND(
         100.0 * SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) / MAX(COUNT(*), 1), 1
       )                                                AS accuracy_pct
     FROM quiz_results
     WHERE user_id = ?`
  )
    .bind(userId)
    .first();

  return c.json({ success: true, data: stats });
});

export default quiz;
