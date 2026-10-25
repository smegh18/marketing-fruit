# Project Architecture

## Overview

The Marketing Fruit application is a cross-platform Flutter application (Mobile and Web) using a flat architectural structure with Firebase as the primary backend service. The application implements multiple user roles (Admin, Student, Brand, School, Guardian) and features complex flows such as the "Entertainment Arc" and a "Marketplace/NFT" segment.

## State Management

The application utilizes **Provider** (`ChangeNotifierProvider`) for state management. This approach was retained as the optimal choice since it was already integrated into the project and correctly handles standard state propagation requirements without necessitating a disruptive rewrite.

### Key Providers:
- `ThemeProvider`: Manages dark/light mode toggling globally. Initialized in `main.dart`.
- `AuthProvider`: Manages authentication flows and stores login states.
- `BooksFilterController` & `BookCreationController`: Manage domain-specific states for the book/course functionality.

## Navigation & Routing

The application primarily uses **GoRouter** for handling web-compatible URLs and deep linking (e.g., `/events/:eventId` and `/verify-guardian`).

**Note on Navigation:**
While GoRouter is the primary routing mechanism initialized in `main.dart`, some older screens (like `login_screen.dart` and the `entertainment_arc` frames) still utilize imperative navigation (`Navigator.push`). A future architectural improvement would be migrating all imperative pushes to GoRouter declarative routes to ensure a completely unified routing schema.

## Backend Infrastructure

**Firebase Ecosystem:**
- **Firebase Auth**: Used for Email/Password, Google, and Facebook authentication.
- **Firebase Realtime Database & Firestore**: Both databases are heavily utilized for user profiles, game mechanics (Entertainment Arc), wallet balances, and course metadata.
- **Firebase Cloud Functions**: Used for secure backend operations such as sending OTPs (`sendOtpEmail`) and guardian verifications (`verifyGuardian`).
- **Firebase App Check**: Secures backend resources from abuse.

**External API Integrations:**
- WordPress API integration for LearnPress token generation and user registration. (Credentials securely loaded via `flutter_dotenv`).

## Core Components
- `login_screen.dart` / `loginform.dart`: Orchestrates the complex onboarding flow (Roles -> Credentials -> OTP -> Guardian Verification).
- `main_layout.dart` / `main_layout_mobile.dart`: Responsive shell wrapping the inner application features.
- `user_event_page.dart`: Dashboard for specific events, optimizing widget reuse between Web and Mobile views.
- `entertainment_arc/`: A complex branching narrative module that dynamically saves player progression via `PlayerDetails` and `gameMechanics` tracking.

## Recommendations for Future Refactoring
1. **Feature-based Folder Structure**: Migrate from flat `lib/components` and `lib/screens` to a modular architecture (e.g., `lib/features/auth`, `lib/features/events`).
2. **Repository Layer**: Abstract direct Firebase calls out of the UI components into dedicated service/repository classes.
