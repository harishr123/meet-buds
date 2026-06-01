# MeetBuddies 

Spontaneous campus meetups for NUS students, find people to gym, study, eat, or hang out with, right now.

MeetBuddies is a Flutter app built for NUS students to post and discover impromptu activities happening around campus. Think of it like a live bulletin board: someone posts "heading to UTown gym in 20 mins, anyone joining?" and others can see it, like it, and show up.

Built for **Orbital 2026 (Apollo 11)** by Parthiv Murugesh & Raghupathy Harish.

---

## Features

- **Sign Up / Login**  Secure email and password authentication via Firebase Auth
- **Live Post Feed** Real-time timeline that updates instantly when new posts are created or liked
- **Create Posts**  Write a post with an optional location tag to let others know where you'll be
- **Likes**  Toggle likes on any post; the counter updates live for everyone
- **Delete Own Posts**  A menu appears on your own posts letting you remove them from the app and database

---

## Project Structure

```
lib/
├── main.dart                   # App entry point; initializes Firebase and opens LoginScreen
├── feed_screen.dart            # Fetches and streams all posts from Firestore in real-time
├── post_card.dart              # UI for a single post (username, time, text, location, like/delete)
├── post_model.dart             # Dart class that maps Firestore documents to typed objects
├── post_service.dart           # Firestore CRUD operations for posts
├── create_post_screen.dart     # Form to write a post and add an optional location tag
├── screens/
│   ├── login_screen.dart       # Login UI; navigates to HomeScreen on success
│   ├── signup_screen.dart      # Sign-up UI with email and password fields
│   └── home_screen.dart        # Wraps FeedScreen with app bar and logout button
└── services/
    └── auth_service.dart       # Firebase Auth wrapper (login, sign up, logout)
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) |
| Authentication | Firebase Auth |
| Database | Cloud Firestore |
| File Storage | Firebase Storage *(free version)* |
| IDE | VS Code |
| Version Control | GitHub |

---

## Getting Started

### Prerequisites

- Flutter SDK (3.x or above)
- Dart SDK (comes with Flutter)
- Xcode (for iOS) or Android Studio (for Android)
- A Firebase project with Firestore and Auth enabled

### Firebase Setup

This project requires Firebase config files that are **not committed to the repo** for security reasons. To run it locally:

1. Go to the [Firebase Console](https://console.firebase.google.com/) and create or use an existing project
2. Enable **Email/Password** under Authentication → Sign-in methods
3. Enable **Cloud Firestore** in test or production mode
4. Download the config files and place them:
   - iOS: `ios/Runner/GoogleService-Info.plist`
   - Android: `android/app/google-services.json`

### Running the App

```bash
git clone https://github.com/harishr123/meet-buds
cd meet-buds
flutter pub get
flutter run
```

To run on a specific iOS simulator:
select iOS device on VS Code
```bash
flutter run
```

---

## Known Limitations

- **No image uploads** — Firebase Storage is on the Spark (free) plan; image upload is disabled. `imageUrls` is always empty for now.
- **No NUS email enforcement** — Any email can be used to sign up. NUS SSO / `.nus.edu.sg` verification is planned.
- **No RSVP system yet** — Joining activities is coming in the next milestone.

---

## Roadmap

- [ ] Join / RSVP for activities
- [ ] User profiles (display name, avatar)
- [ ] Filter feed by activity type and location
- [ ] In-app chat
- [ ] NUS email verification
- [ ] Push notifications

---

## Team

| Name | GitHub |
|---|---|
| Parthiv Murugesh | [@harishr123](https://github.com/harishr123) |
| Raghupathy Harish | [@nus-cs25](https://github.com/nus-cs25) |

**Orbital 2026 — Apollo 11**, School of Computing, National University of Singapore
