import { Hono } from 'hono';
import { Env, ApiResponse, Sentence } from '../types/index';

const sentences = new Hono<{ Bindings: Env }>();

// GET /api/sentences
sentences.get('/', async (c) => {
  const { level, category, page = '1', limit = '20' } = c.req.query();
  const offset = (parseInt(page) - 1) * parseInt(limit);

  let query = 'SELECT * FROM sentences WHERE 1=1';
  const params: unknown[] = [];

  if (level) {
    query += ' AND cefr_level = ?';
    params.push(level.toUpperCase());
  }
  if (category) {
    query += ' AND category = ?';
    params.push(category.toLowerCase());
  }

  const countQuery = query.replace('SELECT *', 'SELECT COUNT(*) as total');
  const [countResult, rows] = await Promise.all([
    c.env.DB.prepare(countQuery).bind(...params).first<{ total: number }>(),
    c.env.DB.prepare(query + ' ORDER BY id ASC LIMIT ? OFFSET ?')
      .bind(...params, parseInt(limit), offset)
      .all<Sentence>(),
  ]);

  return c.json({
    success: true,
    data: rows.results,
    meta: { total: countResult?.total ?? 0, page: parseInt(page), limit: parseInt(limit) },
  } as ApiResponse<Sentence[]>);
});

// GET /api/sentences/:id
sentences.get('/:id', async (c) => {
  const id = parseInt(c.req.param('id'));
  if (isNaN(id)) return c.json({ success: false, error: 'Invalid ID' }, 400);

  const sentence = await c.env.DB.prepare('SELECT * FROM sentences WHERE id = ?')
    .bind(id)
    .first<Sentence>();
  if (!sentence) return c.json({ success: false, error: 'Sentence not found' }, 404);

  return c.json({ success: true, data: sentence } as ApiResponse<Sentence>);
});

// GET /api/sentences/builder/batch — fetch sentences for the sentence builder exercise
sentences.get('/builder/batch', async (c) => {
  const { level, count = '5' } = c.req.query();
  let query = 'SELECT * FROM sentences';
  const params: unknown[] = [];

  if (level) {
    query += ' WHERE cefr_level = ?';
    params.push(level.toUpperCase());
  }
  query += ' ORDER BY RANDOM() LIMIT ?';
  params.push(parseInt(count));

  const rows = await c.env.DB.prepare(query).bind(...params).all<Sentence>();
  return c.json({ success: true, data: rows.results } as ApiResponse<Sentence[]>);
});

// POST /api/sentences
sentences.post('/', async (c) => {
  const body = await c.req.json<Omit<Sentence, 'id' | 'created_at'>>();
  const { sentence, translation = '', cefr_level, category = 'general', word_ids = '[]', grammar_focus = '' } = body;

  if (!sentence || !cefr_level) {
    return c.json({ success: false, error: 'Missing required fields' }, 400);
  }

  const result = await c.env.DB.prepare(
    `INSERT INTO sentences (sentence, translation, cefr_level, category, word_ids, grammar_focus)
     VALUES (?, ?, ?, ?, ?, ?)`
  )
    .bind(sentence, translation, cefr_level, category, word_ids, grammar_focus)
    .run();

  return c.json({ success: true, data: { id: result.meta.last_row_id } }, 201);
});

export default sentences;
