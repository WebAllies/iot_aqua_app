# 🌿 IoT Aqua App (AquaFarm)

A smart aquaponics monitoring and control application built with Flutter. This app integrates IoT sensors, AI-based plant disease detection, and real-time data monitoring to help users manage their aquaponics systems efficiently.

## 🚀 Features

- **Real-time Monitoring**: View live data from IoT sensors (water temperature, pH, etc.) via Firebase.
- **AI Disease Detection**: Analyze plant health using on-device Machine Learning (TensorFlow Lite) to detect diseases like lettuce rot.
- **Smart Control**: Manage actuators and system settings remotely.
- **User Authentication**: Secure login and sign-up using Firebase Auth and Google Sign-In.
- **Dark/Light Mode**: Adaptive UI with theme persistence.
- **Onboarding Flow**: Guided introduction for new users.

## 🛠 Tech Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **Backend / Database**: [Firebase](https://firebase.google.com/) (Firestore, Auth, Core)
- **Machine Learning**: [TensorFlow Lite](https://www.tensorflow.org/lite) (`tflite_flutter`)
- **State Management**: Provider
- **Local Storage**: Shared Preferences

## 📱 Prerequisites

Before you begin, ensure you have the following installed:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Latest stable version recommended)
- [Dart SDK](https://dart.dev/get-dart)
- [Firebase CLI](https://firebase.google.com/docs/cli) (For configuring Firebase)
- **Android Studio** or **VS Code** with Flutter extensions.

## ⚡ Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/iot_aqua_app.git
cd iot_aqua_app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Configuration

This project relies on Firebase. You must configure it for your own Firebase project:

1.  **Install FlutterFire CLI** (if not already installed):
    ```bash
    dart pub global activate flutterfire_cli
    ```
2.  **Configure the App**:
    Run the following command in the project root and follow the interactive prompts to link your Firebase project. This will generate the `lib/firebase_options.dart` file.
    ```bash
    flutterfire configure
    ```
    *Select the platforms you want to support (Android, iOS, Web).*

### 4. Machine Learning Models

Ensure the TFLite models are present in the `assets/models/` directory:
- `assets/models/lettuce_model.tflite`
- `assets/models/labels.txt`

These are referenced in `pubspec.yaml` and are required for the AI features.

### 5. Type Generation (Optional)

If you modify attributes or models, you might need to run build runner (though this project currently uses standard providers, checking `pubspec.yaml` doesn't show `build_runner` dependencies like `freezed` or `json_serializable`, so you can skip this unless you add them).

### 6. Run the App

Connect a device or start an emulator/simulator:

```bash
flutter run
```

## 📂 Project Structure

```
lib/
├── ai/                 # AI & Machine Learning logic (TFLite integration)
├── analytics/          # Data visualization and analytics components
├── control/            # IoT control logic (actuators, pumps)
├── core/               # Core utilities, theme, and shared constants
├── dashboard/          # Main dashboard UI
├── features/           # Feature-based modules
│   ├── auth/           # Authentication screens and logic
│   ├── onboarding/     # Onboarding screens
│   ├── sensors/        # Sensor data display components
│   └── settings/       # App settings and configuration
├── pages/              # General app pages (legacy or simple pages)
├── shell/              # Navigation shell (BottomNavigationBar, etc.)
├── firebase_options.dart # Generated Firebase configuration
└── main.dart           # App entry point
```

## ⚙️ Configuration details

### Environment Variables
Currently, the app uses `firebase_options.dart` for environment-specific keys. Ensure this file is not committed to public repositories if you want to keep your Firebase project private (though client-side keys are generally safe to expose).

### Theme
To customize the theme, check `lib/core/theme/` (if implemented) or modify the `ThemeData` in `lib/main.dart`.

## 🤝 Contributing

1.  Fork the repository.
2.  Create your feature branch (`git checkout -b feature/AmazingFeature`).
3.  Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4.  Push to the branch (`git push origin feature/AmazingFeature`).
5.  Open a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
