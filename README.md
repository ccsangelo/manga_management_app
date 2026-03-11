# Manga Recommendation App

A Flutter app that helps you discover manga by genre. Search by genre/theme keywords or get a random recommendation — powered by the [Jikan API](https://jikan.moe/) (MyAnimeList).

## Features

- **Genre-based search** — Enter comma-separated genres/themes to find matching manga, sorted by score
- **Random recommendation** — "Surprise Me" button for a random manga pick
- **NSFW filter** — Toggle to include or exclude adult content
- **Paginated results** — Browse through pages of search results
- **Detail view** — View synopsis, score, genres, themes, demographics, and cover art
- **Dark theme** — Material Design dark UI

## Tech Stack

- **Flutter** (Dart)
- **flutter_bloc** — State management via the BLoC pattern
- **http** — REST API calls to Jikan v4

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (≥ 3.11.0)

### Installation

```bash
git clone https://github.com/ccsangelo/manga_management_app.git
cd manga_management_app
flutter pub get
flutter run
```

## Project Structure

```
lib/
├── main.dart              # App entry point & theme
├── bloc/                  # BLoC (events, states, logic)
├── models/                # Data models (Manga, MangaSearchResult)
├── pages/                 # UI screens (Home, Results, MangaInfo)
└── services/              # API service (Jikan)
```

## API

This app uses the [Jikan REST API v4](https://docs.api.jikan.moe/) — an unofficial MyAnimeList API. No API key required.

## License

This project is for educational purposes.