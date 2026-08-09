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

## Access requests and security

The public administrator-access form intentionally opens a prepared email and
does not write personal data to Firestore. The optional Cloud Functions/Resend
implementation under `functions/` is disabled by the Firestore rules until
App Check, rate limiting, and a retention policy are in place.

Country administrators can edit their country's content settings, but only a
superadmin can create a country or change whether it is enabled. Holy Ground
images are checked for type and size in the client before being sent to the
configured Cloudinary upload preset; the preset must also enforce equivalent
limits in Cloudinary.

## Development

```sh
flutter pub get
flutter analyze
flutter test
```

## Documentation

- [Import songs from XLSX or PPTX](docs/song_import.md)
- [Operational CRM](docs/operational_crm.md)
- [Holy Grounds MVP](docs/holy_grounds.md)
- [P0: operação de domingo e prontidão do país](docs/p0_product_cycle.md)
- [Weekly video automation](docs/weekly_video_automation.md)
- [Firestore schema](docs/firestore_schema.md)

## Notes

The song tests validate that required metadata exists, referenced audio files are present, and lyric timing data cannot read beyond the available lyrics.
