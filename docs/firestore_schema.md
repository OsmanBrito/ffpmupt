# Firestore Schema

## Countries

Path: `countries/{countryCode}`

```json
{
  "code": "pt",
  "name": "Portugal",
  "defaultLanguage": "pt",
  "timezone": "Europe/Lisbon",
  "enabled": true,
  "createdAt": "server timestamp",
  "updatedAt": "server timestamp"
}
```

The Web app lists every enabled country on first access. The selected country
is stored locally and reflected in the URL (`/pt`, `/es`, `/de`). Its
`defaultLanguage` controls the interface language.

For now, a new country is created manually in Firebase:

1. Create `countries/{countryCode}` with the fields above.
2. Create the administrator in Firebase Authentication.
3. Create `users/{uid}` with `role: admin`, `enabled: true`, and the new code in
   `countryCodes`.
4. In that country's admin, prepare the Promise defaults and import the Worship
   catalog.

Country content is independent. Editing or disabling a Promise or song under
one country never changes another country.

## Weekly Videos

Path: `countries/{countryCode}/settings/weeklyVideos`

The document contains `youtube` and `vimeo` maps with title, source URL,
watch URL, and embed URL.

```json
{
  "countryCode": "pt",
  "youtube": {
    "title": "HJ Global News Português (01.08.2026)",
    "sourceName": "YouTube",
    "sourceUrl": "https://www.youtube.com/@hjpeacetv8814/videos",
    "watchUrl": "https://www.youtube.com/watch?v=...",
    "embedUrl": "https://www.youtube-nocookie.com/embed/..."
  },
  "vimeo": {
    "title": "EUME Weekly News 440",
    "sourceName": "Vimeo",
    "sourceUrl": "https://vimeo.com/eume",
    "watchUrl": "https://vimeo.com/...",
    "embedUrl": "https://player.vimeo.com/video/..."
  },
  "updatedAt": "server timestamp or automation timestamp",
  "updatedBy": "admin uid or weekly-video-automation"
}
```

Admins can still edit this document through the app. The optional GitHub Actions
automation is documented in `docs/weekly_video_automation.md`.

## Payments and Tithes

Path: `countries/{countryCode}/settings/payments`

```json
{
  "enabled": true,
  "title": "Ofertas e dízimos",
  "subtitle": "Escolha uma opção para fazer a sua contribuição.",
  "note": "",
  "methods": [
    {
      "id": "bank-transfer",
      "type": "bankTransfer",
      "label": "Transferência bancária",
      "description": "",
      "details": [
        {"label": "Nome", "value": "..."},
        {"label": "IBAN", "value": "..."}
      ],
      "paymentUrl": "",
      "qrContent": "bank payload or URL",
      "enabled": true,
      "sortOrder": 0
    }
  ],
  "updatedAt": "server timestamp"
}
```

Method types: `bankTransfer`, `pix`, `mbWay`, `paymentLink`, and `other`.
The `details` list is flexible so each country can expose its own labels and
values. The app generates a QR code from `qrContent` and keeps the latest valid
settings in local storage for offline use.

## Initial Song Import

Path: `countries/{countryCode}/settings/songImport`

```json
{
  "completed": true,
  "songCount": 42,
  "completedAt": "server timestamp"
}
```

The marker prevents a country from confirming the initial XLSX/PPTX import
more than once. Existing Worship-only documents do not block the first local
import.

## Songs

Path: `countries/{countryCode}/songs/{songId}`

```json
{
  "title": "A Morada do Pai",
  "page": "1",
  "category": "holy",
  "languageCode": "pt",
  "lyrics": ["Verse one", "Verse two"],
  "chorusMode": "none",
  "enabled": true,
  "sortOrder": 1,
  "audioTracks": [
    {
      "id": "principal",
      "label": "Principal",
      "url": "https://...",
      "storagePath": "countries/pt/songs/song-id/principal.mp3",
      "verseStartSeconds": [0, 75, 142],
      "verseChangeSeconds": [75, 142],
      "enabled": true,
      "sortOrder": 0
    }
  ],
  "videoLinks": [
    {
      "id": "youtube",
      "provider": "youtube",
      "label": "YouTube",
      "watchUrl": "https://youtube.com/watch?v=...",
      "embedUrl": "https://www.youtube-nocookie.com/embed/...",
      "enabled": true,
      "sortOrder": 0
    }
  ],
  "createdAt": "server timestamp",
  "updatedAt": "server timestamp"
}
```

Song categories: `holy`, `fellowship`, `english`, `worship`, and
`international`.

Chorus modes: `none`, `first`, and `second`.

## Family Promise

Path: `countries/{countryCode}/promises/{languageCode}`

Each country owns an independent copy. Korean and English are the initial
defaults; the country's main language is added by its administrator.

```json
{
  "languageCode": "pt",
  "title": "Promessa da Família",
  "verses": ["Point 1", "Point 2"],
  "enabled": true,
  "sortOrder": 0,
  "createdAt": "server timestamp",
  "updatedAt": "server timestamp"
}
```

The Web app keeps three read layers for each country's song catalog:

1. The bundled catalog is always available as the first-install fallback.
2. The latest valid Firestore catalog is stored in browser local storage.
3. Firestore persistent cache and snapshots synchronize changes automatically.

The custom service worker caches the application shell and downloads enabled
audio tracks in the background. The home screen reports the number of cached
tracks and whether any files still require internet. Weekly videos remain
online-only.

## Users

Path: `users/{uid}`

```json
{
  "role": "admin",
  "enabled": true,
  "countryCodes": ["pt"],
  "email": "admin@example.com",
  "displayName": "Country administrator"
}
```

The global operational CRM uses `role: "superadmin"`. A superadministrator
can manage every country and invite administrators by email. Regular
administrators remain restricted to the exact codes in `countryCodes`.

## Administrator Invites

Path: `adminInvites/{inviteId}`

```json
{
  "email": "admin@example.com",
  "displayName": "Country administrator",
  "countryCodes": ["br"],
  "createdBy": "superadmin uid",
  "createdAt": "server timestamp",
  "expiresAt": "timestamp",
  "enabled": true,
  "acceptedBy": "",
  "acceptedAt": null
}
```

The invitee creates or signs in to a Firebase Authentication account through
the invite link. After email verification, one Firestore transaction marks the
invite as accepted and creates or extends `users/{uid}`. Security rules require
the authenticated email and granted country codes to match the invite.

## Local Churches

Path: `countries/{countryCode}/churches/{churchId}`

```json
{
  "name": "Lisbon Family Church",
  "city": "Lisbon",
  "address": "...",
  "timezone": "Europe/Lisbon",
  "contactName": "Local administrator",
  "contactEmail": "admin@example.com",
  "enabled": true,
  "createdAt": "server timestamp",
  "updatedAt": "server timestamp"
}
```

Church documents are operational data and are readable only by an authorized
country administrator or superadministrator.

## Holy Grounds

Path: `countries/{countryCode}/holyGrounds/{holyGroundId}`

```json
{
  "countryCode": "pt",
  "name": "Lisbon Holy Ground",
  "city": "Lisbon",
  "address": "...",
  "latitude": 38.7223,
  "longitude": -9.1393,
  "imageUrl": "https://...",
  "summary": "...",
  "history": "...",
  "visitInstructions": "...",
  "contactName": "...",
  "contactEmail": "...",
  "languageCode": "pt",
  "enabled": true,
  "sortOrder": 0,
  "createdAt": "server timestamp",
  "updatedAt": "server timestamp"
}
```

Enabled Holy Grounds are publicly readable through a collection-group query.
Only an administrator authorized for `countryCode` can create or update them.
Disabled documents remain stored but are omitted from the public directory.

## Notices and News

Path: `countries/{countryCode}/notices/{noticeId}`

```json
{
  "countryCode": "pt",
  "title": "Workshop para líderes",
  "body": "Informações e preparação para esta semana.",
  "category": "workshop",
  "date": "2026-09-12",
  "location": "Lisboa",
  "linkUrl": "https://...",
  "languageCode": "pt",
  "enabled": true,
  "pinned": false,
  "sortOrder": 0,
  "createdAt": "server timestamp",
  "updatedAt": "server timestamp"
}
```

Categories are `general`, `event`, `specialDay`, `workshop`, and
`weeklyHomework`. Public clients can read only enabled notices under an enabled
country. Country administrators can create, edit, publish, and hide their own
country's notices.
