# Activity 09 — Local Storage Lab Part II

## Overview

Sweater Weather is a Flutter guestbook application extended with SQLite-backed folders and cards. The original guestbook remains available after upgrading the database from version 1 to version 2.

## Features

- Guestbook: add, view, edit, and delete guests.
- Folders: create, list, and delete folders; show card counts.
- Cards: create, view, edit, and delete cards inside a folder, including title, suit, optional notes, and optional image reference.
- Validation: a card cannot be saved with an empty title.
- Persistence: data is stored locally using SQLite.

## Database migration

The existing `MyDatabase.db` database is upgraded to **version 2**. The original `my_table` guestbook data is retained, and `folders` and `cards` tables are added. The `cards.folder_id` foreign key references `folders.id` with `ON DELETE CASCADE`; an index on `cards(folder_id)` supports folder-based queries.

## Observed tests

| Check | Observed result |
|---|---|
| Guestbook after migration | Guest #1 Nour (age 20) and Guest #2 Mnowar (age 25) displayed; total count 2 |
| Folder creation | `Favorites` displayed with 1 card |
| Card creation and editing | `Queen of Hearts` displayed in `Favorites`, suit `Hearts`, notes `My first card` |
| Card deletion | A separate test card, `King of Spades`, was deleted successfully |
| Invalid card title | Form displayed `Enter a card title` and did not close |
| Folder deletion | Reported working in manual testing; verify cascade separately if required |
| Flutter static analysis | `No issues found!` |
| Release APK | `flutter build apk --release` succeeded (47.6 MB) |

**Testing note:** A Flutter assertion occurred once after creating a folder. The folder persisted after restarting. This issue should be retested and fixed before declaring the UI fully stable. Database version and foreign-key enforcement have not been independently verified in this README.

## Evidence

- `evidence/T1_before.png` — earlier guestbook view (1 guest)
- `evidence/T2_cards.png` — card displayed in Favorites
- `evidence/T4_after.png` — guestbook view after migration (2 guests)
- `evidence/T6_invalid.png` — empty card-title validation
- `evidence/analysis_output.txt` — Flutter analysis output

## Run and build

```bash
flutter pub get
flutter analyze
flutter run
flutter build apk --release
```

Release APK: `build/app/outputs/flutter-apk/app-release.apk`.

## Technologies

Flutter, Dart, SQLite (`sqflite`), Android emulator.
