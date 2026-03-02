# Recognitions — Real-time Face Recognition App

A production-ready Flutter application implementing on-device real-time face recognition using **MobileFaceNet** (TFLite), **Google ML Kit** face detection, **Hive** local storage, and **Clean Architecture**.

---

## ✨ Features

| Feature | Detail |
|---|---|
| 🎯 Face Registration | Camera → ML Kit detection → crop to 112×112 → MobileFaceNet embedding → Hive |
| 🔐 Face Authentication | Camera → embedding → cosine similarity against stored faces |
| 📋 Manage Faces | View, delete individual or all registered faces |
| 🌙 Dark UI | Premium dark theme with glassmorphism cards and animated buttons |
| 🔒 On-device | All ML inference runs 100% on-device — no cloud, no network |
| 📴 Offline | Works without any internet connection |

---

## 🏗️ Architecture — Clean Architecture

```
lib/
├── main.dart                         # App entry point
├── core/
│   ├── constants/app_constants.dart  # Model paths, thresholds, sizes
│   ├── di/service_locator.dart       # GetIt dependency injection
│   ├── errors/failures.dart          # Typed failure hierarchy
│   └── theme/app_theme.dart          # Dark theme tokens
│
├── domain/                           # Pure Dart — NO framework dependencies
│   ├── entities/
│   │   ├── face_entity.dart          # Registered face domain object
│   │   └── auth_result.dart          # Authentication result value object
│   ├── repositories/
│   │   └── face_repository.dart      # Abstract repository contract
│   └── usecases/
│       ├── register_face_usecase.dart
│       ├── authenticate_face_usecase.dart
│       ├── get_all_faces_usecase.dart
│       └── delete_face_usecase.dart
│
├── data/                             # Concrete implementations
│   ├── models/
│   │   ├── face_embedding_model.dart     # Hive @HiveType model
│   │   ├── face_embedding_model.g.dart   # Auto-generated adapter
│   │   └── face_embedding_model_mapper.dart  # Entity ↔ Model mapper
│   ├── datasources/local/
│   │   └── hive_service.dart         # Hive CRUD wrapper
│   ├── services/
│   │   ├── face_service.dart         # ML Kit detection + crop + resize
│   │   └── embedding_model_service.dart  # TFLite MobileFaceNet inference
│   └── repositories/
│       └── face_repository_impl.dart # FaceRepository implementation
│
└── presentation/
    ├── providers/
    │   └── face_provider.dart        # ChangeNotifier — camera + use cases
    ├── screens/
    │   ├── home_screen.dart          # Landing: Register / Authenticate
    │   ├── register_screen.dart      # Face registration flow
    │   ├── authenticate_screen.dart  # Face authentication flow
    │   └── manage_faces_screen.dart  # List + delete registered faces
    └── widgets/
        ├── camera_preview_widget.dart    # Camera preview + oval guide
        ├── glass_card.dart               # Reusable card container
        ├── loading_overlay.dart          # Full-screen loading spinner
        ├── result_card.dart              # Animated success/failure card
        ├── animated_gradient_button.dart # Tap-to-scale gradient CTA
        └── stats_badge.dart              # Face count badge
```

---

## 🚀 Setup Instructions

### Prerequisites

| Tool | Version |
|---|---|
| Flutter | 3.x (stable) |
| Dart | 3.0+ |
| Android Studio / Xcode | Latest stable |
| Android minSdk | 21 |
| iOS deployment target | 14.0 |

---

### Step 1 — Clone / Open the project

```bash
cd "path/to/recognitions"
```

---

### Step 2 — Add the MobileFaceNet TFLite model ⚠️ REQUIRED

The model file is **not** included in this repo due to size. You must add it manually.

**Option A — Download pre-trained model**

1. Download `mobilefacenet.tflite` from one of these sources:
   - https://github.com/sigsep/sigsep-mus-db
   - Search GitHub for "mobilefacenet tflite" and filter by file
   - Use the model from [InsightFace](https://github.com/deepinsight/insightface)

2. Place it at:
   ```
   assets/models/mobilefacenet.tflite
   ```

**Option B — Convert from checkpoint (Python required)**

```bash
pip install tensorflow

# Convert SavedModel/checkpoint to TFLite with full-integer quantization
python - << 'EOF'
import tensorflow as tf

# Load your SavedModel
converter = tf.lite.TFLiteConverter.from_saved_model("path/to/mobilefacenet_saved_model")
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()

with open("assets/models/mobilefacenet.tflite", "wb") as f:
    f.write(tflite_model)
print("Done!")
EOF
```

**Expected model spec:**

```
Input:  [1, 112, 112, 3]  float32   # RGB normalised: pixel/127.5 - 1.0
Output: [1, 192]           float32   # L2-normalised embedding vector
```

---

### Step 3 — Install dependencies

```bash
flutter pub get
```

---

### Step 4 — (Optional) Regenerate Hive adapter

The `.g.dart` file is pre-generated and included. If you modify `FaceEmbeddingModel`, regenerate it:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

### Step 5 — Android setup

The `android/` directory is fully configured. Key settings:

| Setting | Value |
|---|---|
| `minSdkVersion` | 21 |
| `compileSdkVersion` | Flutter default |
| `aaptOptions.noCompress` | `"tflite"` |
| AndroidX | true |
| Jetifier | true |

No additional steps required for Android.

---

### Step 6 — iOS setup

```bash
cd ios
pod install
cd ..
```

Key settings in `Podfile`:

| Setting | Value |
|---|---|
| `platform :ios` | `'14.0'` |
| `ENABLE_BITCODE` | `'NO'` |
| Swift version | 5 |

**Sign the app in Xcode:**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Set your Team in *Signing & Capabilities*

---

### Step 7 — Run the app

```bash
# Android
flutter run --release

# iOS  
flutter run --release
```

> **Note:** Always test face recognition on a **physical device**. Camera emulators do not work properly with ML Kit.

---

## ⚙️ Configuration

Adjust core settings in `lib/core/constants/app_constants.dart`:

```dart
// Similarity threshold (0.0 – 1.0). Lower = more permissive.
static const double similarityThreshold = 0.70;

// Model input dimensions (must match your .tflite model)
static const int modelInputSize = 112;

// Embedding vector size (must match your .tflite output)
static const int embeddingSize = 192;
```

---

## 🔑 Permissions Summary

### Android (`AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.CAMERA" />
```

### iOS (`Info.plist`)
```xml
<key>NSCameraUsageDescription</key>
<string>Recognitions needs camera access to register and authenticate your face.</string>
```

---

## 🧪 Testing Checklist

- [ ] Model file placed at `assets/models/mobilefacenet.tflite`
- [ ] `flutter pub get` executed successfully
- [ ] App runs on physical device (Android or iOS)
- [ ] Camera permission granted
- [ ] Face registration with a clear, well-lit face
- [ ] Authentication returns the correct username
- [ ] Edge case: no face → shows "No face detected"
- [ ] Edge case: multiple faces → shows error message
- [ ] Edge case: permission denied → shows instructions

---

## 🛡️ Security Notes

- All face data is stored **locally** in Hive (device-only)
- Embeddings are 192-dimensional floating-point vectors — they cannot be reversed to reconstruct a face image
- No biometric data ever leaves the device
- Hive storage is not encrypted by default; add `hive_flutter` AES encryption for production if needed:

```dart
final key = Hive.generateSecureKey();
await Hive.openBox<FaceEmbeddingModel>(
  HiveService.faceEmbeddingsBoxName,
  encryptionCipher: HiveAesCipher(key),
);
```

---

## 📦 Key Dependencies

| Package | Purpose |
|---|---|
| `camera` | Camera preview and photo capture |
| `google_mlkit_face_detection` | On-device face bounding box detection |
| `tflite_flutter` | TFLite runtime for MobileFaceNet inference |
| `hive` + `hive_flutter` | Fast local key-value storage for embeddings |
| `provider` | Reactive state management (ChangeNotifier) |
| `get_it` | Service locator for dependency injection |
| `permission_handler` | Camera runtime permission requests |
| `image` | Image decoding, cropping, and resizing |
| `uuid` | UUID v4 generation for face IDs |
| `equatable` | Value equality for domain entities |
| `flutter_spinkit` | Loading spinners |
| `google_fonts` | Inter font family |

---

## 🐛 Troubleshooting

**"Model could not be loaded"**
→ Ensure `mobilefacenet.tflite` is in `assets/models/` and listed under `flutter > assets` in `pubspec.yaml`.

**"Camera initialisation failed" on Android**
→ Make sure `minSdkVersion` is ≥ 21 in `android/app/build.gradle`.

**"No face detected" even when face is visible**
→ Improve lighting; ensure only one face is fully visible in the oval guide.

**iOS build fails with "Bitcode" error**
→ Run `pod install` after `flutter pub get`; Podfile already sets `ENABLE_BITCODE = NO`.

**Hive adapter not found**
→ Run `flutter pub run build_runner build --delete-conflicting-outputs` to regenerate`.g.dart`.
