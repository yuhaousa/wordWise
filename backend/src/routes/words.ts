import { Hono } from 'hono';
import { Env, ApiResponse, Word } from '../types/index';

const words = new Hono<{ Bindings: Env }>();

// GET /api/words — list words with optional filters
words.get('/', async (c) => {
  const { level, category, search, page = '1', limit = '20' } = c.req.query();
  const offset = (parseInt(page) - 1) * parseInt(limit);

  let query = 'SELECT * FROM words WHERE 1=1';
  const params: unknown[] = [];

  if (level) {
    query += ' AND cefr_level = ?';
    params.push(level.toUpperCase());
  }
  if (category) {
    query += ' AND category = ?';
    params.push(category.toLowerCase());
  }
  if (search) {
    query += ' AND (word LIKE ? OR definition LIKE ?)';
    params.push(`%${search}%`, `%${search}%`);
  }

  const countQuery = query.replace('SELECT *', 'SELECT COUNT(*) as total');
  const [countResult, rows] = await Promise.all([
    c.env.DB.prepare(countQuery).bind(...params).first<{ total: number }>(),
    c.env.DB.prepare(query + ' ORDER BY id ASC LIMIT ? OFFSET ?')
      .bind(...params, parseInt(limit), offset)
      .all<Word>(),
  ]);

  const response: ApiResponse<Word[]> = {
    success: true,
    data: rows.results,
    meta: {
      total: countResult?.total ?? 0,
      page: parseInt(page),
      limit: parseInt(limit),
    },
  };
  return c.json(response);
});

// GET /api/words/:id — single word
words.get('/:id', async (c) => {
  const id = parseInt(c.req.param('id'));
  if (isNaN(id)) return c.json({ success: false, error: 'Invalid ID' }, 400);

  const word = await c.env.DB.prepare('SELECT * FROM words WHERE id = ?').bind(id).first<Word>();
  if (!word) return c.json({ success: false, error: 'Word not found' }, 404);

  return c.json({ success: true, data: word } as ApiResponse<Word>);
});

// GET /api/words/random — get N random words for flashcards
words.get('/random/batch', async (c) => {
  const { level, count = '10' } = c.req.query();
  let query = 'SELECT * FROM words';
  const params: unknown[] = [];

  if (level) {
    query += ' WHERE cefr_level = ?';
    params.push(level.toUpperCase());
  }
  query += ' ORDER BY RANDOM() LIMIT ?';
  params.push(parseInt(count));

  const rows = await c.env.DB.prepare(query).bind(...params).all<Word>();
  return c.json({ success: true, data: rows.results } as ApiResponse<Word[]>);
});

// POST /api/words — create a word (admin use)
words.post('/', async (c) => {
  const body = await c.req.json<Omit<Word, 'id' | 'created_at'>>();
  const { word, definition, part_of_speech, cefr_level, example_sentence = '', phonetic = '', category = 'general' } = body;

  if (!word || !definition || !part_of_speech || !cefr_level) {
    return c.json({ success: false, error: 'Missing required fields' }, 400);
  }

  const result = await c.env.DB.prepare(
    `INSERT INTO words (word, definition, part_of_speech, cefr_level, example_sentence, phonetic, category)
     VALUES (?, ?, ?, ?, ?, ?, ?)`
  )
    .bind(word, definition, part_of_speech, cefr_level, example_sentence, phonetic, category)
    .run();

  return c.json({ success: true, data: { id: result.meta.last_row_id } }, 201);
});

// DELETE /api/words/:id
words.delete('/:id', async (c) => {
  const id = parseInt(c.req.param('id'));
  await c.env.DB.prepare('DELETE FROM words WHERE id = ?').bind(id).run();
  return c.json({ success: true });
});

export default words;
