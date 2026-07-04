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

## Weekly Videos

Path: `countries/{countryCode}/settings/weeklyVideos`

The document contains `youtube` and `vimeo` maps with title, source URL,
watch URL, and embed URL.

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

The Web app keeps three read layers for the song catalog:

1. The bundled catalog is always available as the first-install fallback.
2. The latest valid Firestore catalog is stored in browser local storage.
3. Firestore persistent cache and snapshots synchronize changes automatically.

The custom service worker caches the application shell and downloads enabled
audio tracks in the background. Weekly videos remain online-only.

## Users

Path: `users/{uid}`

```json
{
  "role": "admin",
  "enabled": true,
  "countryCodes": ["pt"]
}
```
