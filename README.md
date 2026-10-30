# 🎬 Calium Mobile

> High-performance, modern cross-platform Anime Streaming client for Android & iOS built with Flutter.

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%2300B4AB.svg?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![Version](https://img.shields.io/badge/version-1.1.0--beta.1-green.style=for-the-badge)

Calium Mobile is the mobile counterpart to **Calium Web**, offering high-speed anime playback, Netflix-style offline downloading, watch history synchronization, user custom lists, and a sleek dark UI.

---

## ✨ Features

- ⚡ **High-Performance Player**: Powered by `media_kit` (libmpv engine) with 1080p, 720p, 480p, 360p stream quality selection, subtitle controls, auto-skip intro, and gesture controls.
- 📥 **Netflix-Style Offline Downloads**: Download episodes with multi-quality & audio track options, stored neatly grouped by anime for offline viewing.
- 🔄 **Cloud & Local Sync**: Synchronize your watch progress and history with your `calium.fun` account or store locally in Hive.
- 📅 **Broadcast Calendar & Explore**: Daily anime release schedule, TR Dubbed catalog, top-ranked rails, and trending shows.
- 🎨 **Modern Dark UI**: Designed with Glassmorphism, smooth animations, dynamic color schemes, and customized avatar upload support.

---

## 🛠️ Architecture & Tech Stack

This project strictly follows **Clean Architecture** principles decoupled into data, domain, and presentation layers:

- **State Management**: `flutter_bloc` / `bloc` / `cubit`
- **Dependency Injection**: `get_it` / `injectable`
- **Navigation**: `go_router` (Stateful Shell Route)
- **Local Database**: `hive_flutter` & `flutter_secure_storage`
- **Media Engine**: `media_kit` & `media_kit_video`
- **HTTP Client**: `dio` with caching interceptors

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `^3.13.0` or higher
- Android Studio / VS Code with Flutter extensions
- Android SDK 21+ / iOS 13+

### Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/Calium-mobile.git
   cd Calium-mobile
   ```

2. **Environment Variables**:
   Copy `.env.example` to `.env` and fill in your API credentials:
   ```bash
   cp .env.example .env
   ```

   For push notifications, register `com.calium.app` as an Android app in the
   same Firebase project used by the Calium web backend and fill the
   `FIREBASE_ANDROID_*`, `FIREBASE_MESSAGING_SENDER_ID`, and
   `FIREBASE_PROJECT_ID` values. If they are empty, the app keeps working with
   local device notifications only.

3. **Get Dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run the App**:
   ```bash
   flutter run
   ```

5. **Build Release APK**:
   ```bash
   flutter build apk --release
   ```

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.
