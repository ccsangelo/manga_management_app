# Manga Recommendation App

A Flutter app for discovering and tracking manga. Browse rankings, search by genre, get personalized recommendations based on your reading history, and manage your reading list — powered by the [Jikan API](https://jikan.moe/) (MyAnimeList).

## Features

### Discovery
- **Home feed** — Popular, latest updates, personalized recommendations, and a random pick, all on one screen
- **Search** — Free-text search with a genre/theme filter modal and OR-mode toggle
- **Rankings** — Top manga across 9 categories (All, One-shots, Doujinshi, Light Novels, Novels, Manhwa, Manhua, Most Popular)
- **Adapted Anime** — Browse anime adaptations across Explore, Airing Now, and Upcoming tabs
- **Manga detail** — Cover art, score, synopsis, genres, themes, demographics, and magazine info

### Reading List
- **Track manga** — Assign a status: Reading, Completed, Dropped, On Hold, or Want to Read
- **Library** — View your tracked manga grouped by status
- **Personalized recommendations** — Home feed recommends manga based on the top genres from your Reading and Completed history

### Account
- **Register** — Email + username + password with email verification (6-digit SMTP code, 10-minute expiry)
- **Login / Logout** — JWT session with 1-hour expiry and session-takeover detection
- **NSFW toggle** — Per-user preference that filters content across all pages
- **Data isolation** — Reading list and preferences are cleared on logout

### Technical
- **Persistent search state** — Search results survive app restarts via HydratedBloc
- **Image caching** — Network images cached locally via `cached_network_image`
- **Scroll debounce** — Prevents excessive API calls on infinite-scroll pages
- **Dark theme** — Material Design dark UI with a centralized color system

## Tech Stack

| Package | Role |
|---|---|
| `flutter_bloc` + `hydrated_bloc` | State management; persistent search state |
| `dio` | HTTP client for Jikan API v4 |
| `go_router` | Declarative routing with shell route navigation |
| `hive_flutter` | Local storage for users, statuses, and search cache |
| `flutter_secure_storage` | Secure JWT token storage |
| `dart_jsonwebtoken` | JWT generation and verification |
| `bcrypt` | Password hashing |
| `mailer` | SMTP email for verification codes |
| `cached_network_image` | Network image caching with placeholder support |
| `freezed` + `json_serializable` | Immutable models with JSON codegen |
| `dartz` | Functional `Either` error handling |
| `flutter_dotenv` | Environment variable configuration |
| `mocktail` | Mocking for unit tests |

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (≥ 3.11.0)

### Environment Setup

Create a `.env` file in the project root:

```env
JIKAN_BASE_URL=https://api.jikan.moe/v4
JWT_SECRET=your_jwt_secret
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=your_email
SMTP_PASSWORD=your_password
```

### Installation

```bash
git clone https://github.com/ccsangelo/manga_management_app.git
cd manga_recommendation_app
flutter pub get
flutter run
```

## Project Structure

```
lib/
├── main.dart                    # App entry point, providers, Hive init
├── config/
│   ├── app_config.dart          # Environment variable reader
│   ├── app_theme.dart           # AppColors constants (dark theme)
│   └── router.dart              # GoRouter configuration
├── bloc/
│   ├── auth/                    # AuthBloc — login, logout, session check
│   ├── home/                    # HomeCubit — 4-section home feed loader
│   ├── paginated_list/          # PaginatedListCubit — reusable pagination
│   ├── register/                # RegisterBloc — registration + verification
│   └── search/                  # SearchBloc — HydratedBloc, persists state
├── models/
│   ├── anime/                   # Anime, AnimeSearchResult
│   ├── genre/                   # GenreItem
│   ├── manga/                   # Manga (freezed)
│   └── search_result/           # MangaSearchResult
├── pages/
│   ├── auth/                    # Login, Register, Verification, Profile
│   ├── home/                    # Home feed
│   ├── manga/                   # Manga detail
│   ├── rankings/                # Rankings tabs, Adapted Anime, Paginated list
│   ├── reading_status/          # Library grouped by status
│   ├── search/                  # Search + results
│   └── shell/                   # Bottom navigation shell
├── services/
│   ├── auth/                    # AuthService, UserService, EmailVerificationService
│   ├── manga/                   # MangaService (API + cache), MangaStatusService (Hive)
│   └── preferences/             # UserPreferencesService (NSFW toggle)
└── widgets/
    ├── manga_card.dart           # Shared MangaCard and GridMangaCard
    ├── anime_card.dart           # Shared AnimeCard and GridAnimeCard
    └── card_components.dart      # Shared ScoreGradient and ScoreBadge
```

## API

This app uses the [Jikan REST API v4](https://docs.api.jikan.moe/) — an unofficial MyAnimeList API. No API key required.

## Testing

```bash
flutter test
```

Unit tests cover `AuthBloc`, `RegisterBloc`, `HomeCubit`, `PaginatedListCubit`, and `SearchBloc`. Widget tests cover `LoginPage` and `UserPage`.

## License

This project is for educational purposes.