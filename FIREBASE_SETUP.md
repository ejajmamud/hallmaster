# Firebase Setup

Real Firebase config files are intentionally ignored by Git because GitHub
secret scanning flags Google API keys.

Before running or building locally, keep these files on your machine:

- `android/app/google-services.json`
- `lib/firebase_options.dart`

Use the `.example` files beside them as templates only. Do not commit real
API keys.

If a real key was already pushed, restrict or rotate it in Google Cloud Console.
