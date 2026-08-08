# Add a New Country

This guide explains how to create a country, give its administrator access,
and prepare its content. Spain (`es`) is used as the example.

Each country is independent. Its administrators can edit or disable its
Promise, songs, audio, and videos without changing another country.

## Before You Start

You need:

- Access to the Firebase project.
- An email address for the country's administrator.
- A lowercase country code, such as `es`, `de`, or `fr`.
- The country's main language code.
- The country's IANA timezone, such as `Europe/Madrid`.

Supported interface languages:

| Language | Code |
| --- | --- |
| Portuguese | `pt` |
| Korean | `ko` |
| English | `en` |
| Spanish | `es` |
| German | `de` |
| Italian | `it` |
| French | `fr` |

The latest Firestore rules and Web app must be deployed before the new admin
can save Promise content. A superadministrator can now complete the country,
church, and admin setup from **Administration > Operational CRM**. The manual
Firebase steps below remain useful for recovery and initial bootstrap.

## How a Country Leader Requests Access

Before signing in, open **Request administrator access** on the first screen
and select the country. The form includes all European countries, including
countries that have not been configured in the app yet. Submit:

- Country name (and country code, if already known).
- Full name and role (country leader or country administrator).
- The individual email address that will be used for the account.

The form opens a prepared email addressed to the coordinator. Press **Send** in
your email application to complete the request. This free flow does not need
the Firebase Blaze plan, Cloud Functions, or a mail service. The coordinator
reviews the email, creates the country invitation, and sends a private link.
If no email application opens, copy the prepared request shown on the page and
send it manually to the displayed coordinator email address.
The leader does not need Firebase access and should not share an administrator
password. Open the invitation link, create or sign in to the account using the
invited email, verify the email, and accept the invitation. Invitation links
expire after seven days; ask the coordinator for a new link if necessary.

## Step 1: Create the Country

1. Open **Firebase Console**.
2. Select the FFPMU project.
3. Open **Firestore Database**.
4. Open the `countries` collection.
5. Click **Add document**.
6. Use the lowercase country code as the document ID. For Spain, use `es`.
7. Add these fields with the exact field types shown below.

| Field | Type | Spain example |
| --- | --- | --- |
| `code` | string | `es` |
| `name` | string | `Spain` |
| `defaultLanguage` | string | `es` |
| `timezone` | string | `Europe/Madrid` |
| `enabled` | boolean | `true` |

The finished document should represent:

```json
{
  "code": "es",
  "name": "Spain",
  "defaultLanguage": "es",
  "timezone": "Europe/Madrid",
  "enabled": true
}
```

Important:

- The document ID and `code` must be identical.
- `enabled` must be a boolean, not the text `"true"`.
- Disabled or not-yet-created countries do not appear on the normal country
  selection screen. They can still be selected on the access-request form.

## Step 2: Create the Administrator Login

1. In Firebase Console, open **Authentication**.
2. Open the **Users** tab.
3. Click **Add user**.
4. Enter the administrator's email and a temporary password.
5. Create the user.
6. Copy the user's **UID**. You will need it in the next step.

Use a separate account for each administrator. Do not share administrator
passwords between countries.

## Step 3: Give the Administrator Access

1. Return to **Firestore Database**.
2. Open the `users` collection.
3. Click **Add document**.
4. Use the Authentication **UID** as the document ID.
5. Add these fields:

| Field | Type | Value |
| --- | --- | --- |
| `role` | string | `admin` |
| `enabled` | boolean | `true` |
| `countryCodes` | array | `es` |

The document should represent:

```json
{
  "role": "admin",
  "enabled": true,
  "countryCodes": ["es"]
}
```

An administrator can manage more than one country by adding more codes to the
array. Only add countries that person should be allowed to edit.

## Step 4: Select the Country in the App

1. Open the Web app while online.
2. On the first screen, select **Spain**.
3. Confirm that the URL changes to `/es`.
4. Confirm that the interface is displayed in Spanish.

The app remembers the selection. Use the globe icon in the top-right corner to
change country later.

If Spain does not appear, check that:

- The country document ID is `es`.
- The `code` field is also `es`.
- `enabled` is the boolean `true`.

## Step 5: Confirm the Country Settings

1. Click the administration icon in the top-right corner.
2. Log in with the new administrator account.
3. Open **Country settings**.
4. Confirm the name, main language, timezone, and enabled status.
5. Save the settings.

Changing the main language changes the interface language for that country.

## Step 6: Prepare the Family Promise

1. In Administration, open **Family Promise**.
2. Click **Prepare default languages**.
3. Korean and English are added as the standard starting content.
4. Open the country's main language, Spanish in this example.
5. Enter the translated title and all eight Promise points.
6. Enable **Language visible**.
7. Save the Promise.

Expected public languages:

- Spain: Spanish, Korean, and English.
- An English-speaking country: English and Korean.
- A Korean-speaking country: Korean and English.

The country administrator may edit or disable any of these versions. The
change only affects that country.

## Step 7: Prepare the Songs

1. In Administration, open **Songs**.
2. Click **Standard catalog**.
3. A new country receives the current Worship songs as its starting catalog.
4. For a bulk initial load, download **XLSX template** or prepare one PPTX per
   song.
5. Click **Import XLSX/PPTX**, review the preview, and confirm the import.
6. Use the add button for later songs.
7. Add audio individually after the text import.

See [Import Songs](song_import.md) for the complete format and validation
steps.

To remove a song from the public catalog, turn off its active switch. This
keeps the data available for later without showing it to users.

For new audio, use a stable HTTPS URL that the browser can access. The app will
download enabled audio automatically for offline use.

## Step 8: Configure Payments and Tithes

1. In Administration, open **Payments and tithes**.
2. Set the page title, introduction, and optional final note.
3. Add one or more methods, such as bank transfer, PIX, MB Way, or a payment
   link.
4. Add the labels and values users should see.
5. Paste the bank-provided QR payload or URL when a QR code is needed.
6. Save and validate the public Offerings screen.

Payment settings belong only to the selected country.

## Step 9: Configure Weekly Videos

1. In Administration, open **Weekly videos**.
2. Add the current YouTube and Vimeo links.
3. Save the links.

Videos require an internet connection. They are not downloaded for offline
use.

## Step 10: Validate the Country

Complete this check before giving the app to users:

- The country appears on the selection screen.
- The URL contains the correct country code.
- The interface uses the country's main language.
- The Promise shows the correct two or three languages.
- Worship songs are visible.
- A local song can be created, edited, and disabled.
- Payment methods and QR codes belong to the correct country.
- The administrator cannot edit another country.
- The offline audio indicator reaches **Audio available offline**.
- After disconnecting the internet, the app still opens and shows the Promise,
  songs, and downloaded audio.

## Publishing When Ready

Building does not publish the app. When a release is approved, run:

```sh
flutter build web --pwa-strategy=none --source-maps
npx --yes firebase-tools deploy --only firestore:rules,hosting --project ffpmupt-402e1
```

Do not deploy until the current release has been reviewed.

## Troubleshooting

### The country is not listed

Check the country document ID, `code`, and boolean `enabled` field. Then reload
the app while online.

### The administrator sees "Access denied"

Confirm that the `users/{uid}` document uses the exact Authentication UID and
contains the correct country code in `countryCodes`.

### The Promise cannot be saved

The new Firestore rules may not be deployed yet. Deploy the approved rules,
then sign out and sign in again.

### Worship songs disappear after adding a local song

Update to the latest app version. The current version merges country songs over
the Worship template instead of replacing it.

### Some audio still needs internet

Keep the app open while online and check that every audio URL works directly in
the browser. Invalid URLs or blocked cross-origin requests cannot be cached.
