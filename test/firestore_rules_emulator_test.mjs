import assert from 'node:assert/strict';
import { after, before, beforeEach, test } from 'node:test';
import { readFile } from 'node:fs/promises';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';

const projectId = 'ffpmupt-402e1';
let environment;

function country(database, code) {
  return doc(database, 'countries', code);
}

function notice(database, countryCode, noticeId) {
  return doc(database, 'countries', countryCode, 'notices', noticeId);
}

function holyGround(database, countryCode, holyGroundId) {
  return doc(database, 'countries', countryCode, 'holyGrounds', holyGroundId);
}

function validNotice(countryCode, overrides = {}) {
  return {
    countryCode,
    title: 'Aviso de teste',
    body: 'Conteúdo confirmado para o teste das regras.',
    category: 'general',
    date: '',
    location: '',
    linkUrl: '',
    imageUrl: '',
    languageCode: 'pt',
    enabled: false,
    pinned: false,
    sortOrder: 0,
    createdAt: Timestamp.fromMillis(1_700_000_000_000),
    updatedAt: Timestamp.fromMillis(1_700_000_000_000),
    ...overrides,
  };
}

before(async () => {
  const rules = await readFile('firestore.rules', 'utf8');
  environment = await initializeTestEnvironment({
    projectId,
    firestore: { rules },
  });
});

beforeEach(async () => {
  await environment.clearFirestore();
  await environment.withSecurityRulesDisabled(async (context) => {
    const database = context.firestore();
    await Promise.all([
      setDoc(country(database, 'pt'), {
        code: 'pt',
        name: 'Portugal',
        defaultLanguage: 'pt',
        timezone: 'Europe/Lisbon',
        enabled: true,
      }),
      setDoc(country(database, 'es'), {
        code: 'es',
        name: 'Espanha',
        defaultLanguage: 'es',
        timezone: 'Europe/Madrid',
        enabled: true,
      }),
      setDoc(country(database, 'disabled'), {
        code: 'disabled',
        name: 'País desativado',
        defaultLanguage: 'pt',
        timezone: 'UTC',
        enabled: false,
      }),
      setDoc(doc(database, 'users', 'admin-pt'), {
        role: 'admin',
        enabled: true,
        countryCodes: ['pt'],
      }),
      setDoc(doc(database, 'users', 'admin-es'), {
        role: 'admin',
        enabled: true,
        countryCodes: ['es'],
      }),
      setDoc(doc(database, 'users', 'superadmin'), {
        role: 'superadmin',
        enabled: true,
        countryCodes: [],
      }),
      setDoc(
        notice(database, 'pt', 'published'),
        validNotice('pt', { enabled: true }),
      ),
      setDoc(notice(database, 'pt', 'draft'), validNotice('pt')),
      setDoc(holyGround(database, 'pt', 'visible'), {
        countryCode: 'pt',
        name: 'Local público',
        enabled: true,
      }),
      setDoc(holyGround(database, 'pt', 'hidden'), {
        countryCode: 'pt',
        name: 'Local oculto',
        enabled: false,
      }),
      setDoc(holyGround(database, 'disabled', 'hidden-country'), {
        countryCode: 'disabled',
        name: 'Local de país desativado',
        enabled: true,
      }),
    ]);
  });
});

after(async () => {
  await environment.cleanup();
});

test('public reads only published notices from enabled countries', async () => {
  const database = environment.unauthenticatedContext().firestore();

  await assertSucceeds(getDoc(country(database, 'pt')));
  await assertSucceeds(getDoc(notice(database, 'pt', 'published')));
  await assertFails(getDoc(notice(database, 'pt', 'draft')));
  await assertFails(getDocs(collection(database, 'countries', 'pt', 'notices')));

  const published = await assertSucceeds(
    getDocs(
      query(
        collection(database, 'countries', 'pt', 'notices'),
        where('enabled', '==', true),
      ),
    ),
  );
  assert.equal(published.size, 1);
});

test('public cannot create or edit a notice', async () => {
  const database = environment.unauthenticatedContext().firestore();

  await assertFails(
    setDoc(notice(database, 'pt', 'public-write'), validNotice('pt')),
  );
  await assertFails(
    updateDoc(notice(database, 'pt', 'published'), { title: 'Alterado' }),
  );
});

test('country admin manages only their own country', async () => {
  const ptDatabase = environment
    .authenticatedContext('admin-pt')
    .firestore();
  const esDatabase = environment
    .authenticatedContext('admin-es')
    .firestore();

  await assertSucceeds(getDoc(notice(ptDatabase, 'pt', 'draft')));
  await assertSucceeds(
    setDoc(notice(ptDatabase, 'pt', 'new-draft'), validNotice('pt')),
  );
  await assertFails(
    setDoc(notice(ptDatabase, 'es', 'wrong-country'), validNotice('es')),
  );
  await assertFails(
    setDoc(notice(ptDatabase, 'pt', 'mismatch'), validNotice('es')),
  );
  await assertFails(getDoc(notice(esDatabase, 'pt', 'draft')));
});

test('notice validation rejects invalid categories, dates, and insecure links', async () => {
  const database = environment
    .authenticatedContext('admin-pt')
    .firestore();

  await assertFails(
    setDoc(
      notice(database, 'pt', 'bad-category'),
      validNotice('pt', { category: 'unknown' }),
    ),
  );
  await assertFails(
    setDoc(
      notice(database, 'pt', 'bad-date'),
      validNotice('pt', { date: '24/08/2026' }),
    ),
  );
  await assertFails(
    setDoc(
      notice(database, 'pt', 'bad-link'),
      validNotice('pt', { linkUrl: 'http://example.com' }),
    ),
  );
  await assertFails(
    setDoc(
      notice(database, 'pt', 'external-image'),
      validNotice('pt', {
        category: 'event',
        imageUrl: 'https://example.com/event.jpg',
      }),
    ),
  );
  await assertSucceeds(
    setDoc(
      notice(database, 'pt', 'image-on-workshop'),
      validNotice('pt', {
        category: 'workshop',
        imageUrl: 'https://res.cloudinary.com/example/event.jpg',
      }),
    ),
  );
  await assertSucceeds(
    setDoc(
      notice(database, 'pt', 'event-image'),
      validNotice('pt', {
        category: 'event',
        imageUrl: 'https://res.cloudinary.com/example/event.jpg',
      }),
    ),
  );
});

test('country admin cannot change country identity or availability', async () => {
  const database = environment
    .authenticatedContext('admin-pt')
    .firestore();

  await assertSucceeds(
    updateDoc(country(database, 'pt'), {
      name: 'Portugal atualizado',
      updatedAt: Timestamp.now(),
    }),
  );
  await assertFails(updateDoc(country(database, 'pt'), { enabled: false }));
  await assertFails(updateDoc(country(database, 'pt'), { code: 'xx' }));
});

test('superadmin can create notices but nobody can delete them', async () => {
  const database = environment
    .authenticatedContext('superadmin')
    .firestore();

  await assertSucceeds(
    setDoc(notice(database, 'es', 'super-draft'), validNotice('es')),
  );
  await assertFails(deleteDoc(notice(database, 'pt', 'draft')));
});

test('public Holy Ground access requires visible item and enabled country', async () => {
  const database = environment.unauthenticatedContext().firestore();

  await assertSucceeds(getDoc(holyGround(database, 'pt', 'visible')));
  await assertFails(getDoc(holyGround(database, 'pt', 'hidden')));
  await assertFails(
    getDoc(holyGround(database, 'disabled', 'hidden-country')),
  );
});
