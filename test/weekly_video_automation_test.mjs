import test from 'node:test';
import assert from 'node:assert/strict';

import {
  chooseVimeoVideo,
  chooseYoutubeVideo,
  normalizeTitle,
  parseVimeoFeed,
  parseYoutubeFeed,
} from '../scripts/update_weekly_videos.mjs';

test('normalizes accents before title matching', () => {
  assert.equal(normalizeTitle('HJ Global News Português'), 'hj global news portugues');
});

test('parses YouTube Atom feed entries and prefers Portuguese', () => {
  const entries = parseYoutubeFeed(`
    <feed>
      <entry>
        <yt:videoId>english1</yt:videoId>
        <title>HJ Global News English (01.08.2026)</title>
        <link rel="alternate" href="https://www.youtube.com/watch?v=english1"/>
        <published>2026-08-01T00:00:00+00:00</published>
      </entry>
      <entry>
        <yt:videoId>pt1</yt:videoId>
        <title>HJ Global News Português (01.08.2026)</title>
        <link rel="alternate" href="https://www.youtube.com/watch?v=pt1"/>
        <published>2026-08-01T01:00:00+00:00</published>
      </entry>
    </feed>
  `);

  assert.equal(entries.length, 2);
  assert.equal(chooseYoutubeVideo(entries).videoId, 'pt1');
});

test('falls back to English YouTube video when Portuguese is missing', () => {
  const entries = [
    {
      title: '孝情全球新聞 (2026年 8月 1日)',
      watchUrl: 'https://www.youtube.com/watch?v=korean1',
      videoId: 'korean1',
      publishedAt: '2026-08-01T00:00:00+00:00',
    },
    {
      title: 'HJ Global News English (01.08.2026)',
      watchUrl: 'https://www.youtube.com/watch?v=english1',
      videoId: 'english1',
      publishedAt: '2026-08-01T01:00:00+00:00',
    },
  ];

  assert.equal(chooseYoutubeVideo(entries).videoId, 'english1');
});

test('parses Vimeo RSS and chooses Weekly News', () => {
  const entries = parseVimeoFeed(`
    <rss><channel>
      <item>
        <title>2026 - 260701 - EUME Prayer Call</title>
        <pubDate>Thu, 02 Jul 2026 01:12:19 -0400</pubDate>
        <link>https://vimeo.com/1206359858</link>
      </item>
      <item>
        <title>EUME Weekly News 440</title>
        <pubDate>Wed, 01 Jul 2026 12:31:38 -0400</pubDate>
        <link>https://vimeo.com/1206206314</link>
        <media:content medium="video">
          <media:player url="https://player.vimeo.com/video/1206206314?h=0f8a68b6af"/>
        </media:content>
      </item>
    </channel></rss>
  `);

  assert.equal(entries.length, 2);
  const weeklyNews = chooseVimeoVideo(entries);
  assert.equal(weeklyNews.videoId, '1206206314');
  assert.equal(
    weeklyNews.embedUrl,
    'https://player.vimeo.com/video/1206206314?h=0f8a68b6af',
  );
});
