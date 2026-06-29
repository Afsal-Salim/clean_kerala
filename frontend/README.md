# Frontend — Make Kerala Clean

Flutter mobile app for Android and iOS.

## Setup

Install [Flutter SDK](https://docs.flutter.dev/get-started/install), then:

```bash
cd frontend
chmod +x setup.sh && ./setup.sh   # creates android/ios if needed + pub get
```

Or manually:

```bash
flutter create . --org org.makekeralaclean --project-name make_kerala_clean
flutter pub get
```

## Run

Start the backend first (port 8000), then:

```bash
# Create report (auth required)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1

# Physical device or iOS simulator — pass your machine IP
flutter run --dart-define=API_BASE_URL=http://192.168.1.x:8000/api/v1
```

## Screens (implemented)

| Screen | Route | Notes |
|--------|-------|-------|
| Home (guest + logged in) | `/` | Feed + awareness quote banner |
| Login | `/login` | |
| Sign up | `/signup` | Basic / NGO / Admin account types |
| Verify email OTP | `/verify-email` | After signup |
| Forgot password | `/forgot-password` | |
| Reset password | `/reset-password` | OTP + new password |

Guest users see the full feed and quotes; login/signup buttons in the app bar.

## Stack

Riverpod · go_router · dio · flutter_secure_storage
