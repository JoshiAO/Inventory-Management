# Inventory Management

A Flutter-based inventory counting application built for KENEA.
It supports mobile count operations, image attachments, role-based access, and Firebase-backed data storage.

## What this app does

- Role-based login for standard users and superusers
- Mobile count sheet with draft saving and item photo attachments
- Discrepancy detection between actual counts and SSR baseline
- Price-backed value difference calculation in Philippine Peso (₱)
- Superuser dashboard with user management and inventory settings
- XLSX import for Item Master, Price List, and SSR Baseline
- Live web dashboard visualization using `fl_chart`

## Key features

- Multi-theme support with KENEA blue branding
- Firebase Authentication, Firestore, and Storage integration
- Camera upload flow for storing item photos in Firebase Storage
- XLSX export of actual count reports for audit and reconciliation

## Local setup

1. Install Flutter and Firebase CLI
2. Run package install:
   ```powershell
   flutter pub get
   ```
3. Ensure Firebase is configured:
   ```powershell
   flutterfire configure --project=inventory-count-app-jao
   ```
4. Run the app on web or mobile:
   ```powershell
   flutter run -d chrome
   ```

## Notes

- Do not commit sensitive service account files or private keys.
- This repository includes client-side Firebase config in `lib/firebase_options.dart`.
- Hosting can be deployed using Firebase Hosting after `flutter build web`.
