# QuranNow

A beautiful and modern Flutter application for reading the Holy Quran with features like audio recitation, bookmarks, and multiple translations.

## Features

- 📖 **Complete Quran**: All 114 surahs with Arabic text and multiple language translations
- 🎵 **Audio Recitation**: High-quality audio recitation for each verse
- 🔖 **Bookmarks**: Save your favorite verses for later reading
- 🌙 **Dark Mode**: Toggle between light and dark themes
- 📱 **Responsive Design**: Beautiful UI that works on all screen sizes
- 🔍 **Search**: Find specific surahs and verses quickly
- 📤 **Share**: Share verses with friends and family
- ⚙️ **Settings**: Customize font size, audio quality, and more

## Screenshots

*Screenshots will be added here*

## Getting Started

### Prerequisites

- Flutter SDK (3.6.2 or higher)
- Dart SDK
- Android Studio / VS Code
- Android/iOS device or emulator

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd quran_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── constants/
│   └── app_colors.dart          # App color scheme
├── models/
│   ├── surah.dart              # Surah data model
│   └── ayah.dart               # Ayah data model
├── providers/
│   ├── quran_provider.dart     # Quran data management
│   ├── audio_provider.dart     # Audio playback management
│   └── theme_provider.dart     # Theme management
├── screens/
│   ├── home_screen.dart        # Main screen with surah list
│   ├── surah_screen.dart       # Individual surah view
│   ├── ayah_screen.dart        # Individual ayah view
│   ├── bookmarks_screen.dart   # Saved verses
│   └── settings_screen.dart    # App settings
├── widgets/
│   ├── surah_card.dart         # Surah list item
│   ├── loading_widget.dart     # Loading indicator
│   └── error_widget.dart       # Error display
└── main.dart                   # App entry point
```

## Dependencies

- **http**: For API calls to fetch Quran data
- **provider**: State management
- **go_router**: Navigation
- **shared_preferences**: Local storage
- **audioplayers**: Audio playback
- **cached_network_image**: Image caching
- **pull_to_refresh**: Pull to refresh functionality
- **flutter_staggered_animations**: Beautiful animations
- **font_awesome_flutter**: Icons

## API

This app uses the [Al-Quran API](https://alquran-api.pages.dev/documentation) to fetch Quran data and translations in multiple languages.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Al-Quran API](https://alquran-api.pages.dev/documentation) for providing Quran data and translations
- Flutter team for the amazing framework
- The open-source community for various packages used in this project

## Support

If you have any questions or need help, please open an issue on GitHub.

---

Made with ❤️ for the Muslim community
