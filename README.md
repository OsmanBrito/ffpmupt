# FFPMU

Multi-country Flutter app for FFPMU church services.

The app shows:

- A Sunday service guide flow.
- The yearly motto.
- Country selection with independent content and administration.
- An interface language defined by the selected country.
- The Family Pledge in the country's main language, Korean, and English.
- Church songs with lyrics, categories, optional audio, and verse timing.
- Country-specific offerings/tithes methods with optional QR codes.

## Content

- Yearly motto: `lib/content/motto.dart`
- Family Pledge: `lib/content/family_promise.dart`
- Default Portugal payment details: `lib/content/offering.dart`
- Songs and audio timing: `lib/songs/songs.dart`
- Audio files: `assets/`

Country-specific songs, Promise content, payment methods, and weekly videos
are stored under `countries/{countryCode}` in Firestore.

## Development

```sh
flutter pub get
flutter analyze
flutter test
```

## Documentation

- [Add a new country](docs/new_country_setup.md)
- [Import songs from XLSX or PPTX](docs/song_import.md)
- [Operational CRM](docs/operational_crm.md)
- [Holy Grounds MVP](docs/holy_grounds.md)
- [Firestore schema](docs/firestore_schema.md)

## Notes

The song tests validate that required metadata exists, referenced audio files are present, and lyric timing data cannot read beyond the available lyrics.
