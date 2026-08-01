# Automacao dos videos semanais

Este fluxo atualiza automaticamente o documento:

```txt
countries/{countryCode}/settings/weeklyVideos
```

O app ja le esse documento na tela **Videos / Semanario**. Se a automacao
atualizar o Firestore, o app passa a mostrar os novos links sem precisar de
deploy.

## Como funciona

1. O GitHub Actions roda em horarios fixos.
2. O script busca o feed publico do YouTube do canal HJ PeaceTV.
3. Ele procura primeiro por `HJ Global News Portugues`.
4. Se nao encontrar portugues, procura por ingles.
5. O script busca o RSS publico do Vimeo `https://vimeo.com/eume/videos/rss`.
6. Ele procura o ultimo video com `Weekly News`.
7. Se encontrar YouTube e Vimeo, grava os dois links no Firestore.
8. Se nao encontrar algum video, o processo falha e nao substitui o conteudo
   atual.

## Horarios

O workflow esta configurado em UTC:

- Sexta, `18:30 UTC`: tentativa para Vimeo.
- Sabado, `17:30 UTC`: tentativa para YouTube.
- Domingo, `07:30 UTC`: retry antes do servico.

No horario de verao em Portugal, isto fica aproximadamente 1 hora a frente.

## Configurar no GitHub

1. Abra o projeto no GitHub.
2. Va em **Settings > Secrets and variables > Actions**.
3. Crie um secret chamado:

```txt
FIREBASE_SERVICE_ACCOUNT_JSON
```

4. No Firebase Console, va em **Project settings > Service accounts**.
5. Gere uma nova chave privada.
6. Copie o JSON inteiro da chave para o secret do GitHub.
7. Opcional: crie uma variable chamada:

```txt
WEEKLY_VIDEO_COUNTRY_CODES
```

8. Coloque os paises que devem receber os mesmos videos, separados por virgula:

```txt
pt,br
```

Se essa variable nao existir, o script usa `pt,br`.

## Rodar manualmente

No GitHub:

1. Abra **Actions**.
2. Abra **Update weekly videos**.
3. Clique em **Run workflow**.
4. Depois confira no Firebase:

```txt
countries/pt/settings/weeklyVideos
countries/br/settings/weeklyVideos
```

## Testar localmente sem salvar

Na raiz do projeto:

```sh
node scripts/update_weekly_videos.mjs --dry-run
```

Isso mostra quais videos seriam escolhidos, mas nao grava no Firestore.

## Rodar localmente salvando

Use apenas se tiver uma chave local de service account.

```sh
export FIREBASE_SERVICE_ACCOUNT_JSON='{"type":"service_account",...}'
export COUNTRY_CODES='pt,br'
node scripts/update_weekly_videos.mjs
```

## Fallback manual

Mesmo com automacao, mantenha o painel admin da tela **Videos / Semanario** como
fallback. Se o YouTube ou Vimeo mudarem o formato do feed, o admin ainda pode
colar o link correto e salvar.
