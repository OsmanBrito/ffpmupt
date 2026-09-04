import { execFileSync } from 'node:child_process';

const projectId = process.env.FIREBASE_PROJECT_ID ?? 'ffpmupt-402e1';
const countryCode = process.env.NOTICE_COUNTRY_CODE ?? 'pt';

const templates = [
  {
    id: 'draft-template-event-v1',
    title: '[Rascunho] Próximo evento',
    body: 'Substitua este texto pelas informações confirmadas do próximo evento antes de publicar.',
    category: 'event',
    sortOrder: 10,
  },
  {
    id: 'draft-template-special-day-v1',
    title: '[Rascunho] Dia especial',
    body: 'Adicione aqui a data, o significado e as orientações do próximo dia especial antes de publicar.',
    category: 'specialDay',
    sortOrder: 20,
  },
  {
    id: 'draft-template-workshop-v1',
    title: '[Rascunho] Workshop',
    body: 'Adicione aqui o tema, a data, o local e a inscrição do próximo workshop antes de publicar.',
    category: 'workshop',
    sortOrder: 30,
  },
  {
    id: 'draft-template-weekly-homework-v1',
    title: '[Rascunho] Tarefa da semana',
    body: 'Adicione aqui a tarefa da semana e as instruções para as famílias antes de publicar.',
    category: 'weeklyHomework',
    sortOrder: 40,
  },
];

function firebaseAccessToken() {
  const response = JSON.parse(
    execFileSync('firebase', ['login:list', '--json'], {
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe'],
    }),
  );
  const token = response.result?.find(
    (entry) => typeof entry.tokens?.access_token === 'string',
  )?.tokens?.access_token;
  if (!token) {
    throw new Error('No authenticated Firebase CLI session was found.');
  }
  return token;
}

function stringValue(value) {
  return { stringValue: value };
}

function integerValue(value) {
  return { integerValue: String(value) };
}

function documentBody(template, timestamp) {
  return {
    fields: {
      countryCode: stringValue(countryCode),
      title: stringValue(template.title),
      body: stringValue(template.body),
      category: stringValue(template.category),
      date: stringValue(''),
      location: stringValue(''),
      linkUrl: stringValue(''),
      imageUrl: stringValue(''),
      languageCode: stringValue('pt'),
      enabled: { booleanValue: false },
      pinned: { booleanValue: false },
      sortOrder: integerValue(template.sortOrder),
      createdAt: { timestampValue: timestamp },
      updatedAt: { timestampValue: timestamp },
    },
  };
}

async function main() {
  const accessToken = firebaseAccessToken();
  const headers = {
    Authorization: `Bearer ${accessToken}`,
    'Content-Type': 'application/json',
  };
  const root =
    `https://firestore.googleapis.com/v1/projects/${projectId}` +
    `/databases/(default)/documents/countries/${countryCode}/notices`;
  const timestamp = new Date().toISOString();
  const created = [];
  const skipped = [];

  for (const template of templates) {
    const documentUrl = `${root}/${template.id}`;
    const existing = await fetch(documentUrl, { headers });
    if (existing.ok) {
      skipped.push(template.id);
      continue;
    }
    if (existing.status !== 404) {
      throw new Error(
        `Could not check ${template.id}: HTTP ${existing.status}`,
      );
    }

    const result = await fetch(
      `${documentUrl}?currentDocument.exists=false`,
      {
        method: 'PATCH',
        headers,
        body: JSON.stringify(documentBody(template, timestamp)),
      },
    );
    if (!result.ok) {
      throw new Error(
        `Could not create ${template.id}: HTTP ${result.status}`,
      );
    }
    created.push(template.id);
  }

  console.log(JSON.stringify({ projectId, countryCode, created, skipped }));
}

await main();
