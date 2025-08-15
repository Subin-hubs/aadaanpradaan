
# 📱 AadanPradaan

AadanPradaan is a Flutter mobile application designed to allow users to **share and request resources** with the community.  
It enables people to connect, offer help, and request items in a seamless and intuitive interface.

---

## 📖 Purpose of the App

The main goal of **AadanPradaan** is to create a platform where users can:
- **Give resources** they no longer need.
- **Request resources** they require.
- Promote a culture of **sharing** and **community support**.
- Provide a simple and friendly UI for all age groups.

---

## 🚀 How the App Works

1. **Sign Up / Log In** – Users create an account or log in.
2. **Add a Resource** – Fill in details such as:
    - Resource Name
    - Description
    - Category
    - Image of the resource
3. **Post the Resource** – The item will be visible to other users.
4. **Request a Resource** – Browse and request available resources.
5. **Manage Posts** – Edit or delete your own listings.

---

## 🛠️ Tech Stack

- **Framework:** Flutter
- **Backend & Database:** Firebase Firestore
- **Authentication:** Firebase Authentication
- **Storage:** Firebase Storage (for images)
- **State Management:** setState (basic) / Future integration with Provider or Riverpod

---
![App Screenshot](1.png)
![App Screenshot](2.png)
![App Screenshot](3.png)
![App Screenshot](4.png)
---

## 🧑‍💻 Getting Started

### 1️⃣ Prerequisites
Make sure you have:
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- Dart installed
- Android Studio or VS Code with Flutter extensions
- Firebase project set up (Authentication, Firestore, Storage)

### 2️⃣ Clone the Repository
```bash
clone: https://github.com/Subin-hubs/aadaanpradaan.git
cd aadanpradaan

3️⃣ Install Dependencies
flutter pub get

4️⃣ Configure Firebase

Download your google-services.json file from Firebase Console.

Place it inside android/app/ folder.

5️⃣ Run the App
flutter run