# 🚀 Command Cheat Sheet - Firebase Face Recognition

## 📋 Quick Reference

### Initial Setup Commands

```bash
# 1. Install FlutterFire CLI
dart pub global activate flutterfire_cli

# 2. Login to Firebase
firebase login

# 3. Navigate to project directory
cd D:\StudioProjects\Other\Learn\test_face_recognition

# 4. Configure Firebase (Auto-generates config)
flutterfire configure

# 5. Get dependencies
flutter pub get

# 6. Run the app
flutter run
```

---

## 🔧 Development Commands

### Clean Build

```bash
# Full clean rebuild
flutter clean
flutter pub get
flutter run
```

### Android Only

```bash
# Clean Android build
cd android
./gradlew clean
cd ..
flutter run
```

### Check for Issues

```bash
# Check for outdated packages
flutter pub outdated

# Analyze code
flutter analyze

# Check pub.dev compatibility
flutter pub get --no-example
```

---

## 🔥 Firebase Commands

### Configure Firebase

```bash
# Initial setup or reconfigure
flutterfire configure

# Specify project
flutterfire configure --project=your-project-id

# Select platforms
flutterfire configure --platforms=android,ios
```

### Firebase CLI

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# List projects
firebase projects:list

# Deploy Firestore rules
firebase deploy --only firestore:rules

# View logs
firebase functions:log
```

---

## 📱 Device Commands

### List Devices

```bash
# List connected devices
flutter devices

# List Android emulators
flutter emulators

# Launch emulator
flutter emulators --launch <emulator-id>
```

### Install & Run

```bash
# Install release build
flutter install

# Run in release mode
flutter run --release

# Run on specific device
flutter run -d <device-id>
```

---

## 🧪 Testing Commands

### Test Registration Flow

```bash
# Run app
flutter run

# In app: Click "Register Face"
# Capture face, enter details
# Check Firebase Console -> Firestore
```

### Test Cross-Device Login

```bash
# On Device A - Register
flutter run -d device-a

# Uninstall to clear local data
flutter clean
adb uninstall com.example.test_face_recognition

# Reinstall and test login
flutter run -d device-a
# Should login using cloud data!
```

### Test Offline Mode

```bash
# Enable airplane mode on device
adb shell cmd connectivity airplane-mode enable

# Try login - should use local database
flutter run

# Disable airplane mode
adb shell cmd connectivity airplane-mode disable
```

---

## 🐛 Debugging Commands

### View Logs

```bash
# Flutter logs
flutter logs

# Android logs
adb logcat | grep Flutter

# Clear logs
adb logcat -c

# Filter specific tag
adb logcat -s "TAG_NAME"
```

### Firestore Debug

```bash
# View Firestore data
firebase firestore:get users
firebase firestore:get face_embeddings

# Delete collection (careful!)
firebase firestore:delete --all-collections
```

### Build Debug

```bash
# Build APK
flutter build apk --debug

# Build with verbose
flutter build apk --debug --verbose

# Clean and rebuild
flutter clean && flutter pub get && flutter build apk --debug
```

---

## 📊 Firebase Console URLs

```bash
# Firebase Console
open https://console.firebase.google.com/

# Firestore Database
open https://console.firebase.google.com/project/YOUR_PROJECT/firestore

# Authentication
open https://console.firebase.google.com/project/YOUR_PROJECT/authentication

# Project Settings
open https://console.firebase.google.com/project/YOUR_PROJECT/settings/general
```

---

## 🔐 Security Commands

### Update Firestore Rules

```bash
# Navigate to project
cd D:\StudioProjects\Other\Learn\test_face_recognition

# Create firestore.rules file
echo 'rules_version = "2";
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    match /face_embeddings/{faceId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}' > firestore.rules

# Deploy rules
firebase deploy --only firestore:rules
```

---

## 📦 Package Management

### Update Packages

```bash
# Update all packages
flutter pub upgrade

# Update specific package
flutter pub upgrade cloud_firestore

# Update with major versions
flutter pub upgrade --major-versions
```

### Add Packages

```bash
# Add Firebase Auth (for production)
flutter pub add firebase_auth

# Add Firebase Analytics
flutter pub add firebase_analytics

# Add Firebase Crashlytics
flutter pub add firebase_crashlytics
```

---

## 🚨 Troubleshooting Commands

### Firebase Connection Issues

```bash
# Reconfigure Firebase
flutterfire configure --force

# Clear Gradle cache
cd android
./gradlew clean
rm -rf .gradle
cd ..
flutter clean
flutter pub get
```

### Build Errors

```bash
# Nuclear option - complete reset
flutter clean
cd android
rm -rf .gradle build
cd app
rm -rf build
cd ../../ios
rm -rf Pods Podfile.lock
pod deintegrate
cd ..
flutter pub get
flutter run
```

### Permission Issues

```bash
# Android permissions
adb shell pm grant com.example.test_face_recognition android.permission.CAMERA

# iOS permissions (in Xcode)
open ios/Runner.xcworkspace
# Update Info.plist with camera usage description
```

---

## 📈 Performance Commands

### Profile App

```bash
# Run in profile mode
flutter run --profile

# Generate performance report
flutter analyze --watch

# Check app size
flutter build apk --analyze-size
```

### Firestore Performance

```bash
# Enable Firestore debug logging
adb shell setprop log.tag.Firestore DEBUG
adb logcat -s Firestore
```

---

## 🎯 Quick Copy-Paste Sequences

### First Time Setup

```bash
dart pub global activate flutterfire_cli && firebase login && cd D:\StudioProjects\Other\Learn\test_face_recognition && flutterfire configure && flutter pub get && flutter run
```

### Clean Rebuild

```bash
flutter clean && flutter pub get && cd android && ./gradlew clean && cd .. && flutter run
```

### Test on All Devices

```bash
flutter run -d all
```

### Emergency Reset

```bash
flutter clean && rm -rf android/.gradle android/build && flutter pub get && flutter run
```

---

## 📚 Helpful Aliases (Optional)

Add to your `.bashrc` or `.zshrc`:

```bash
# Flutter shortcuts
alias fc='flutter clean'
alias fpg='flutter pub get'
alias fr='flutter run'
alias frd='flutter run --debug'
alias frr='flutter run --release'
alias fa='flutter analyze'

# Firebase shortcuts  
alias fblogin='firebase login'
alias fblist='firebase projects:list'
alias ffdeploy='firebase deploy'

# Combined shortcuts
alias fcr='flutter clean && flutter pub get && flutter run'
alias fcrd='flutter clean && flutter pub get && flutter run --debug'
```

---

## 🎓 Learning Commands

### Dart/Flutter Info

```bash
# Check versions
flutter --version
dart --version
firebase --version

# Check Flutter doctor
flutter doctor -v

# Flutter help
flutter --help
```

### Package Info

```bash
# Show package details
flutter pub deps
flutter pub deps --style=compact

# Show package tree
flutter pub deps --style=tree
```

---

## 💡 Pro Tips

1. **Always clean before major changes**: `flutter clean`
2. **Check Firebase Console frequently**: Monitor data in real-time
3. **Use verbose logging**: `flutter run --verbose` for detailed output
4. **Test on real devices**: Emulators may have different behavior
5. **Keep Firebase CLI updated**: `npm update -g firebase-tools`

---

## 🆘 Emergency Contacts

```bash
# If everything fails, restart from scratch:

# 1. Backup your lib/ folder
cp -r lib lib_backup

# 2. Delete project
cd ..
rm -rf test_face_recognition

# 3. Clone fresh
flutter create test_face_recognition
cd test_face_recognition

# 4. Restore your lib/ folder
cp -r ../lib_backup/* lib/

# 5. Setup again
flutterfire configure
flutter pub get
flutter run
```

---

**Bookmark this page for quick reference! 🔖**

