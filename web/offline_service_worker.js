const CACHE_VERSION = 'ffpmupt-offline-v2';
const APP_CACHE = `${CACHE_VERSION}-app`;
const AUDIO_CACHE = `${CACHE_VERSION}-audio`;

const APP_SHELL = [
  './',
  './index.html',
  './flutter.js',
  './flutter_bootstrap.js',
  './main.dart.js',
  './manifest.json',
  './favicon.png',
  './icons/Icon-192.png',
  './icons/Icon-512.png',
  './assets/AssetManifest.bin',
  './assets/FontManifest.json',
  './assets/fonts/MaterialIcons-Regular.otf',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(APP_CACHE).then((cache) => cache.addAll(APP_SHELL)),
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((names) =>
      Promise.all(
        names
          .filter((name) =>
            name.startsWith('ffpmupt-offline-') &&
            name !== APP_CACHE &&
            name !== AUDIO_CACHE,
          )
          .map((name) => caches.delete(name)),
      ),
    ),
  );
  self.clients.claim();
});

self.addEventListener('message', (event) => {
  if (event.data?.type !== 'CACHE_AUDIO' || !Array.isArray(event.data.urls)) {
    return;
  }

  event.waitUntil(cacheAudioFiles(event.data.urls));
});

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') {
    return;
  }

  const url = new URL(event.request.url);
  const isAudio = url.pathname.toLowerCase().endsWith('.mp3');
  if (isAudio) {
    event.respondWith(audioFirst(event.request));
    return;
  }

  if (url.origin === self.location.origin) {
    event.respondWith(networkFirst(event.request));
  }
});

async function cacheAudioFiles(urls) {
  const cache = await caches.open(AUDIO_CACHE);
  for (const rawUrl of urls) {
    const url = normalizeAudioUrl(rawUrl);
    const existing = await cache.match(url);
    if (existing) {
      continue;
    }

    try {
      const response = await fetch(url);
      if (response.ok || response.type === 'opaque') {
        await cache.put(url, response);
      }
    } catch (_) {
      // A later synchronization will retry files that are still missing.
    }
  }
}

function normalizeAudioUrl(rawUrl) {
  if (/^https?:\/\//i.test(rawUrl)) {
    return rawUrl;
  }
  if (rawUrl.startsWith('assets/')) {
    return new URL(`assets/${rawUrl}`, self.registration.scope).toString();
  }
  return new URL(rawUrl, self.registration.scope).toString();
}

async function audioFirst(request) {
  const cache = await caches.open(AUDIO_CACHE);
  const cached = await cache.match(request.url);
  if (cached) {
    return cached;
  }

  const response = await fetch(request);
  if (response.ok || response.type === 'opaque') {
    await cache.put(request.url, response.clone());
  }
  return response;
}

async function networkFirst(request) {
  const cache = await caches.open(APP_CACHE);
  try {
    const response = await fetch(request);
    if (response.ok) {
      await cache.put(request, response.clone());
    }
    return response;
  } catch (_) {
    return (await cache.match(request)) || (await cache.match('./index.html'));
  }
}
