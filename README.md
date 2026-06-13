# 📱 Gallery App

<p align="center">
  <img src="assets/images/logo.png" width="140" alt="Gallery App Logo"/>
</p>

A powerful **Flutter-based media sharing application** that allows users to upload, view, and manage images and videos using a PHP/MySQL backend.

---

## 🚀 Overview

**Gallery App** enables users to easily upload images and videos from their device gallery, store them on a server, and view them in a clean, modern feed. Images can be viewed in full-screen mode, and videos can be played directly inside the app.

This project demonstrates full-stack integration between **Flutter frontend** and **PHP/MySQL backend**.

---

## ✨ Features

* 🔐 User login and logout system
* 📤 Upload images from device gallery
* 🎥 Upload videos from device gallery
* 🖼️ Full-screen image viewer
* ▶️ In-app video player
* 🌐 Fetch media from PHP/MySQL backend
* 🔄 Automatic gallery refresh after uploads
* 💾 Persistent login using SharedPreferences
* 📱 Responsive and modern UI design

---

## 🛠️ Technologies Used

* Flutter (Frontend)
* Dart
* PHP (REST API Backend)
* MySQL (Database)
* HTTP Package (API Communication)
* Image Picker (Media Selection)
* Video Player (Media Playback)
* Shared Preferences (Session Management)

---

## ⚙️ Workflow

1. User logs into the application
2. User selects an image or video from device gallery
3. File is uploaded to PHP server via API
4. Media data is stored in MySQL database
5. Uploaded content appears in the gallery feed
6. Users can view images in full-screen mode
7. Users can play videos directly inside the app
8. Users can log out securely (session cleared)

---

## 📸 Screenshots

<p align="center">
  <img src="screenshots/home.png" width="250"/>
  <img src="screenshots/view.png" width="250"/>
  <img src="screenshots/video.png" width="250"/>
</p>

---

## 📦 Installation

```bash id="i1"
git clone https://github.com/AhmadSambil/flutter-gallery-app.git
```

```bash id="i2"
cd flutter-gallery-app
flutter pub get
flutter run
```

---

## 🚀 Build Release APK

```bash id="i3"
flutter build apk --release
```

APK location:

```
build/app/outputs/flutter-apk/
```

---

## 📁 Project Structure

```
lib/
 ├── main.dart
 ├── HomePage.dart
 ├── LoginPage.dart
 ├── ImageViewerPage.dart
 ├── VideoPlayerPage.dart
 ├── Api_Key.dart
 ├── widgets/
```

---

## 👨‍💻 Developer

**Ahmad Sambil**
📧 Email: [sambilhassan@gmail.com](mailto:sambilhassan@gmail.com)
🌐 GitHub: https://github.com/AhmadSambil/flutter-gallery-app

---

## ⭐ Support

If you like this project, please consider giving it a ⭐ star on GitHub.

---

## 📄 License

This project is for educational and personal use.

---

