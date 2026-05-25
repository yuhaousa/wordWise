# 📚 English Learning App

A full-stack mobile app for teen/student English learners — vocabulary flashcards, sentence builder, quizzes, and spaced-repetition progress tracking.

| Layer    | Tech stack |
|----------|------------|
| Mobile   | Flutter 3+ (Dart) |
| Backend  | Cloudflare Workers · TypeScript · Hono framework |
| Database | Cloudflare D1 (SQLite) |

---

## Project Structure

```
english-learning-app/
├── backend/                  Cloudflare Workers API
│   ├── src/
│   │   ├── index.ts          Main app entry (Hono router)
│   │   ├── middleware/
│   │   │   └── cors.ts
│   │   ├── routes/
│   │   │   ├── words.ts      GET /api/words  (list, random batch)
│   │   │   ├── sentences.ts  GET /api/sentences  (list, builder batch)
│   │   │   ├── quiz.ts       GET /api/quiz/questions · POST /api/quiz/submit
│   │   │   └── progress.ts   Spaced-repetition progress tracking
│   │   ├── db/
│   │   │   ├── schema.sql    D1 table definitions
│   │   │   └── seed.sql      Sample words, sentences, quiz questions
│   │   └── types/
│   │       └── index.ts      Shared TypeScript interfaces
│   ├── wrangler.toml
│   ├── package.json
│   └── tsconfig.json
│
└── mobile/                   Flutter app
    ├── lib/
    │   ├── main.dart
    │   ├── config/api_config.dart
    │   ├── theme/app_theme.dart
    │   ├── models/           word · sentence · quiz_question · user_progress
    │   ├── services/         api_service · audio_service (TTS)
    │   ├── providers/        word_provider · quiz_provider · progress_provider
    │   └── screens/
    │       ├── home_screen.dart
    │       ├── flashcard_screen.dart       Flip cards + spaced repetition
    │       ├── sentence_builder_screen.dart Drag-and-drop word arrangement
    │       ├── quiz_screen.dart            Multiple-choice + fill-blank quizzes
    │       └── progress_screen.dart        Mastery stats + due-for-review
    └── pubspec.yaml
```

---

## 1 · Backend Setup (Cloudflare Workers)

### Prerequisites
- Node.js 18+
- Cloudflare account (free tier works)
- Wrangler CLI: `npm install -g wrangler`

### Steps

```bash
cd backend
npm install

# 1. Authenticate with Cloudflare
wrangler login

# 2. Create the D1 database
npm run db:create
# Copy the database_id printed and paste it into wrangler.toml → database_id

# 3. Run migrations + seed (remote)
npm run db:migrate
npm run db:seed

# 4. Start local dev server (uses local D1 copy)
npm run db:migrate:local
npm run db:seed:local
npm run dev
# → http://localhost:8787
```

### Deploy to Cloudflare

```bash
npm run deploy
# Your API will be live at:
# https://english-learning-api.<your-subdomain>.workers.dev
```

After deploy, update `mobile/lib/config/api_config.dart`:
```dart
static const String _productionBaseUrl =
    'https://english-learning-api.YOUR_SUBDOMAIN.workers.dev';
```

---

## 2 · API Reference

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET    | `/api/words?level=A1&page=1` | List words (filters: level, category, search) |
| GET    | `/api/words/random/batch?count=10&level=B1` | Random flashcard batch |
| GET    | `/api/sentences/builder/batch?count=5` | Sentence builder batch |
| GET    | `/api/quiz/questions?count=10&level=A2` | Quiz questions |
| POST   | `/api/quiz/submit` | Submit answer `{question_id, answer}` |
| GET    | `/api/quiz/stats/:userId` | User accuracy stats |
| GET    | `/api/progress/:userId/due` | Items due for spaced-repetition review |
| POST   | `/api/progress/update` | Record review result `{item_type, item_id, is_correct}` |
| GET    | `/api/progress/:userId/summary` | Dashboard summary |

All endpoints return `{ success: true, data: ... }` or `{ success: false, error: "..." }`.

Pass user identity via the `X-User-Id` header.

---

## 3 · Flutter App Setup

### Prerequisites
- Flutter 3.19+ (`flutter --version`)
- Android Studio or Xcode for device/emulator

### Run

```bash
cd mobile
flutter pub get

# Android
flutter run

# iOS
flutter run -d ios

# Production build pointing to Cloudflare
flutter build apk --dart-define=ENV=prod
flutter build ios --dart-define=ENV=prod
```

---

## 4 · Features

### 🃏 Flashcards
Tap to flip between word and definition. Tapping **Got It!** or **Don't Know** records spaced-repetition progress. Filter by CEFR level (A1–C2). Audio pronunciation via TTS.

### 🔤 Sentence Builder
Words from the answer sentence are shuffled into a word bank. Tap to place and remove words. Instant visual feedback on submission, with TTS reading the correct sentence.

### 📝 Quiz
10-question sessions combining word definitions, fill-in-the-blank, choose-the-word, and spelling questions. Results screen with per-question breakdown and accuracy score.

### 📊 Progress
Spaced-repetition engine schedules reviews (10 min → 1 h → 8 h → 1 day → 3 days → 1 week → mastered). Dashboard shows mastery breakdown for words and sentences, plus a due-for-review badge.

---

## 5 · Adding Content

Insert words via the API or directly into D1:

```sql
-- Add a new word
INSERT INTO words (word, definition, part_of_speech, cefr_level, example_sentence, phonetic, category)
VALUES ('persevere', 'continue despite difficulty', 'verb', 'B2',
        'She persevered through all the challenges.', '/ˌpɜːsɪˈvɪə/', 'motivation');

-- Add a quiz question
INSERT INTO quiz_questions (type, question, correct_answer, options, cefr_level)
VALUES ('word_definition', 'What does "persevere" mean?',
        'continue despite difficulty',
        '["continue despite difficulty","give up easily","celebrate success","ask for help"]',
        'B2');
```

---

## 6 · Environment Variables

| Variable | Location | Purpose |
|----------|----------|---------|
| `ENVIRONMENT` | `wrangler.toml [vars]` | `"production"` or `"development"` |
| `ENV=prod` | Flutter `--dart-define` | Switches API base URL to Cloudflare |

---

## 7 · Roadmap

- [ ] User authentication (Cloudflare Access or JWT)
- [ ] Admin dashboard for content management
- [ ] Listening comprehension (audio clips)
- [ ] Leaderboard / gamification (streaks, badges)
- [ ] Offline-first with local Hive cache sync
- [ ] Push notifications for daily review reminders
