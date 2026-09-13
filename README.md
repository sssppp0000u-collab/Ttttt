# ذي قار TV 2028 — SAT-VIEW 4K PRO IPTV

Flutter IPTV starter project with:
- Glassmorphism dark navy UI
- Neon blue + gold visual identity
- Xtream Codes API integration
- Login screen
- Dashboard
- Live TV channel list
- Search/favorites
- Video player
- Android build support
- GitHub Actions workflow

## Server
The project is configured for an Xtream-compatible server. Credentials are placed in `lib/main.dart` because they were explicitly supplied for this project.

> For production distribution, do not publish private IPTV credentials in a public repository. Use secure configuration or a protected backend.

## Build locally
```bash
flutter pub get
flutter build apk --release
```

APK output:
`build/app/outputs/flutter-apk/app-release.apk`

## GitHub Actions
Push the project to GitHub and run:
Actions → Build Android APK → Run workflow
