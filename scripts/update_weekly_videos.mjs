import { createSign } from 'node:crypto';
import { readFile } from 'node:fs/promises';

const youtubeChannelId = 'UCKBcbApQ73-PJJfF77Dz4EQ';
const youtubeSourceUrl = 'https://www.youtube.com/@hjpeacetv8814/videos';
const youtubeFeedUrl =
  `https://www.youtube.com/feeds/videos.xml?channel_id=${youtubeChannelId}`;
const vimeoSourceUrl = 'https://vimeo.com/eume';
const vimeoFeedUrl = 'https://vimeo.com/eume/videos/rss';

const defaultCountryCodes = ['pt', 'br'];
const portugueseKeywords = ['portugues', 'portuguese', 'português'];
const englishKeywords = ['english', 'ingles', 'inglês'];
const weeklyNewsKeywords = ['global news', 'weekly news'];

export function decodeXmlText(value) {
  return value
    .replaceAll('&amp;', '&')
    .replaceAll('&quot;', '"')
    .replaceAll('&#039;', "'")
    .replaceAll('&apos;', "'")
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>');
}

export function normalizeTitle(value) {
  return value
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase();
}

function tagText(block, tagName) {
  const match = block.match(new RegExp(`<${tagName}[^>]*>([\\s\\S]*?)<\\/${tagName}>`));
  return match ? decodeXmlText(match[1].trim()) : '';
}

function linkHref(block) {
  const match = block.match(/<link[^>]+href="([^"]+)"/);
  return match ? decodeXmlText(match[1]) : '';
}

export function parseYoutubeFeed(xml) {
  const entries = [];
  const matches = xml.matchAll(/<entry>([\s\S]*?)<\/entry>/g);

  for (const match of matches) {
    const block = match[1];
    const videoId = tagText(block, 'yt:videoId');
    const title = tagText(block, 'title');
    const publishedAt = tagText(block, 'published');
    const watchUrl = linkHref(block) || `https://www.youtube.com/watch?v=${videoId}`;

    if (!videoId || !title || !watchUrl) {
      continue;
    }

    entries.push({ title, watchUrl, videoId, publishedAt });
  }

  return entries;
}

export function parseVimeoFeed(xml) {
  const items = [];
  const matches = xml.matchAll(/<item>([\s\S]*?)<\/item>/g);

  for (const match of matches) {
    const block = match[1];
    const title = tagText(block, 'title');
    const watchUrl = tagText(block, 'link');
    const publishedAt = tagText(block, 'pubDate');
    const videoId = watchUrl.match(/vimeo\.com\/(\d+)/)?.[1] ?? '';

    if (!videoId || !title || !watchUrl) {
      continue;
    }

    items.push({ title, watchUrl, videoId, publishedAt });
  }

  return items;
}

function includesAny(title, keywords) {
  const normalized = normalizeTitle(title);
  return keywords.some((keyword) => normalized.includes(normalizeTitle(keyword)));
}

function findByKeywords(entries, languageKeywords) {
  return (
    entries.find(
      (entry) =>
        includesAny(entry.title, languageKeywords) &&
        includesAny(entry.title, weeklyNewsKeywords),
    ) ??
    entries.find((entry) => includesAny(entry.title, languageKeywords))
  );
}

export function chooseYoutubeVideo(entries) {
  return (
    findByKeywords(entries, portugueseKeywords) ??
    findByKeywords(entries, englishKeywords) ??
    entries[0] ??
    null
  );
}

export function chooseVimeoVideo(entries) {
  return (
    entries.find((entry) => includesAny(entry.title, ['weekly news', 'weekly-news'])) ??
    entries.find((entry) => includesAny(entry.title, ['weekly'])) ??
    null
  );
}

function weeklyVideoMap({ title, sourceName, sourceUrl, watchUrl, videoId }) {
  const embedUrl =
    sourceName === 'YouTube'
      ? `https://www.youtube-nocookie.com/embed/${videoId}`
      : `https://player.vimeo.com/video/${videoId}`;

  return { title, sourceName, sourceUrl, watchUrl, embedUrl };
}

function firestoreValue(value) {
  if (typeof value === 'string') {
    return { stringValue: value };
  }

  if (value && typeof value === 'object' && !Array.isArray(value)) {
    return {
      mapValue: {
        fields: Object.fromEntries(
          Object.entries(value).map(([key, nestedValue]) => [
            key,
            firestoreValue(nestedValue),
          ]),
        ),
      },
    };
  }

  throw new Error(`Unsupported Firestore value: ${value}`);
}

function firestoreDocument(data) {
  return {
    fields: Object.fromEntries(
      Object.entries(data).map(([key, value]) => [key, firestoreValue(value)]),
    ),
  };
}

function base64Url(input) {
  return Buffer.from(input)
    .toString('base64')
    .replaceAll('+', '-')
    .replaceAll('/', '_')
    .replaceAll('=', '');
}

async function loadServiceAccount() {
  const raw =
    process.env.FIREBASE_SERVICE_ACCOUNT_JSON ??
    process.env.GOOGLE_APPLICATION_CREDENTIALS_JSON;
  if (raw) {
    return JSON.parse(raw);
  }

  const credentialsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (credentialsPath) {
    return JSON.parse(await readFile(credentialsPath, 'utf8'));
  }

  throw new Error(
    'Missing FIREBASE_SERVICE_ACCOUNT_JSON or GOOGLE_APPLICATION_CREDENTIALS.',
  );
}

async function fetchAccessToken(serviceAccount) {
  const now = Math.floor(Date.now() / 1000);
  const header = base64Url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claim = base64Url(
    JSON.stringify({
      iss: serviceAccount.client_email,
      scope: 'https://www.googleapis.com/auth/datastore',
      aud: serviceAccount.token_uri ?? 'https://oauth2.googleapis.com/token',
      exp: now + 3600,
      iat: now,
    }),
  );
  const unsignedJwt = `${header}.${claim}`;
  const signature = createSign('RSA-SHA256')
    .update(unsignedJwt)
    .sign(serviceAccount.private_key, 'base64')
    .replaceAll('+', '-')
    .replaceAll('/', '_')
    .replaceAll('=', '');
  const assertion = `${unsignedJwt}.${signature}`;

  const response = await fetch(serviceAccount.token_uri, {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });

  if (!response.ok) {
    throw new Error(`Could not authenticate with Google: ${response.status}`);
  }

  const data = await response.json();
  return data.access_token;
}

async function projectIdFromConfig() {
  const raw = await readFile('.firebaserc', 'utf8');
  return JSON.parse(raw).projects.default;
}

async function fetchText(url) {
  const response = await fetch(url, {
    headers: {
      accept: 'application/rss+xml, application/atom+xml, application/xml',
      'user-agent': 'ffpmupt-weekly-video-updater/1.0',
    },
  });

  if (!response.ok) {
    throw new Error(`Could not fetch ${url}: ${response.status}`);
  }

  return response.text();
}

export async function discoverWeeklyVideos() {
  const [youtubeXml, vimeoXml] = await Promise.all([
    fetchText(youtubeFeedUrl),
    fetchText(vimeoFeedUrl),
  ]);

  const youtubeEntry = chooseYoutubeVideo(parseYoutubeFeed(youtubeXml));
  const vimeoEntry = chooseVimeoVideo(parseVimeoFeed(vimeoXml));

  if (!youtubeEntry) {
    throw new Error('No YouTube weekly video found.');
  }

  if (!vimeoEntry) {
    throw new Error('No Vimeo weekly video found.');
  }

  return {
    youtube: weeklyVideoMap({
      ...youtubeEntry,
      sourceName: 'YouTube',
      sourceUrl: youtubeSourceUrl,
    }),
    vimeo: weeklyVideoMap({
      ...vimeoEntry,
      sourceName: 'Vimeo',
      sourceUrl: vimeoSourceUrl,
    }),
  };
}

function countryCodesFromEnv() {
  const raw = process.env.COUNTRY_CODES ?? process.env.WEEKLY_VIDEO_COUNTRY_CODES;
  if (!raw) {
    return defaultCountryCodes;
  }

  return raw
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean);
}

async function updateCountry({ projectId, accessToken, countryCode, videos }) {
  const now = new Date().toISOString();
  const url =
    `https://firestore.googleapis.com/v1/projects/${projectId}` +
    `/databases/(default)/documents/countries/${countryCode}/settings/weeklyVideos`;
  const document = firestoreDocument({
    countryCode,
    youtube: videos.youtube,
    vimeo: videos.vimeo,
    updatedAt: now,
    updatedBy: 'weekly-video-automation',
  });
  const response = await fetch(url, {
    method: 'PATCH',
    headers: {
      authorization: `Bearer ${accessToken}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify(document),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(
      `Could not update ${countryCode}: ${response.status} ${body}`,
    );
  }
}

export async function main() {
  const dryRun = process.argv.includes('--dry-run') || process.env.DRY_RUN === '1';
  const countryCodes = countryCodesFromEnv();
  const projectId = process.env.FIREBASE_PROJECT_ID ?? (await projectIdFromConfig());
  const videos = await discoverWeeklyVideos();

  console.log(`YouTube: ${videos.youtube.title} (${videos.youtube.watchUrl})`);
  console.log(`Vimeo: ${videos.vimeo.title} (${videos.vimeo.watchUrl})`);
  console.log(`Countries: ${countryCodes.join(', ')}`);

  if (dryRun) {
    console.log('Dry run only. Firestore was not updated.');
    return;
  }

  const serviceAccount = await loadServiceAccount();
  const accessToken = await fetchAccessToken(serviceAccount);

  for (const countryCode of countryCodes) {
    await updateCountry({ projectId, accessToken, countryCode, videos });
    console.log(`Updated countries/${countryCode}/settings/weeklyVideos`);
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}
