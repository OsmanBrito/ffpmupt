# FFPMU PT

Flutter app for FFPMU Portugal church services.

The app shows:

- A Sunday service guide flow.
- The yearly motto.
- A global app language preference.
- The Family Pledge in Portuguese, Korean, and English.
- Church songs with lyrics, categories, optional audio, and verse timing.
- Offerings/tithes payment details with a QR that opens a public IBAN copy page.

## Content

- Yearly motto: `lib/content/motto.dart`
- Family Pledge: `lib/content/family_promise.dart`
- Offerings/tithes account details: `lib/content/offering.dart`
- Songs and audio timing: `lib/songs/songs.dart`
- Audio files: `assets/`

Fill the real bank account values in `lib/content/offering.dart` before using
the offerings page publicly.

## Development

```sh
flutter pub get
flutter analyze
flutter test
```

## Notes

The song tests validate that required metadata exists, referenced audio files are present, and lyric timing data cannot read beyond the available lyrics.
