# WTSub 🎬🤖

WTSub is a cross-platform mobile application built with Flutter that automatically transcribes, translates, and generates precise `.srt` subtitle files from video inputs using the Google Gemini API.

## Author

* **GitHub:** [Kiarash Fattahikhah](https://github.com/kia161078)

## Features

- **AI-Powered Subtitle Generation:** Leverages Google Gemini (`gemini-3.5-flash-lite`) to transcribe video audio and format output directly into clean `.srt` files with exact timestamps.
- **Multi-Language Support:** Translate and generate subtitles in multiple languages including Farsi, English, Spanish, German, French, Russian, Turkish, Arabic, and more.
- **Firebase Integration:** Secure user authentication via Firebase Auth and Firestore-backed usage tracking to manage free-tier limitations and premium status.
- **Local History & Storage:** Automatically saves generated subtitle files to device storage and maintains a local history log using `SharedPreferences`.
- **Modern UI/UX:** Custom dark-themed interface featuring smooth navigation, video duration validation, and real-time loading states.

## Tech Stack

- **Framework:** Flutter (Dart)
- **Backend & Database:** Firebase (Authentication, Cloud Firestore)
- **AI Engine:** Google Generative AI (`gemini-3.5-flash-lite`)
- **Key Packages:** `file_picker`, `video_player`, `path_provider`, `shared_preferences`

## Getting Started

### Prerequisites

- Flutter SDK installed on your system.
- An active Firebase project with Authentication and Cloud Firestore enabled.
- A valid Google Gemini API key.

### Screenshots 

<img width="576" height="1280" alt="9" src="https://github.com/user-attachments/assets/b73f689d-8460-42a2-9b51-c406771326eb" />
<img width="576" height="1280" alt="8" src="https://github.com/user-attachments/assets/fe387619-8e12-4478-8633-c1196984812d" />
<img width="576" height="1280" alt="7" src="https://github.com/user-attachments/assets/cb26dc97-ee38-452b-b0d6-e4449f4833ed" />
<img width="576" height="1280" alt="6" src="https://github.com/user-attachments/assets/01cce8b3-aa90-4f47-90c5-cd3d25b2c00b" />
<img width="576" height="1280" alt="5" src="https://github.com/user-attachments/assets/8d6f5f14-4e2c-47a6-ba94-fd428bd19d23" />
<img width="576" height="1280" alt="4" src="https://github.com/user-attachments/assets/63470707-91c6-47a4-bcda-34dc075a61fd" />
<img width="576" height="1280" alt="3" src="https://github.com/user-attachments/assets/9f905e98-711a-4ed6-8aa8-41b94a3272fa" />
<img width="576" height="1280" alt="2" src="https://github.com/user-attachments/assets/11b8bcf8-d5c4-4c93-a10c-191634c24184" />
<img width="576" height="1280" alt="1" src="https://github.com/user-attachments/assets/686916b5-a349-414d-8e70-97e31951f568" />


### Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/kia161078/subtitle.git
   cd subtitle
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   - Download your `google-services.json` file from the Firebase Console.
   - Place it inside the `android/app/` directory.

4. **Add API Key:**
   - Open `subtitle_screen.dart` and insert your Gemini API key:
     ```dart
     final String geminiApiKey = 'YOUR_GEMINI_API_KEY';
     ```

5. **Run the app:**
   ```bash
   flutter run
   ```

## License

This project is open-source and available for educational and personal use.
