# Optional FFPMU Connect access-request email backend

The current app uses a free `mailto:` flow: the public access-request page
opens the user's email application with a prepared message addressed to the
coordinator. The user presses **Send**, so the app does not need Cloud
Functions, Resend, or the Firebase Blaze plan.

This folder contains an optional server-side alternative for a future decision.
It is not referenced by `firebase.json` and is not required for the app.

If enabled later, the public Flutter form would create
`accessRequests/{requestId}` and `sendAccessRequestEmail` would send the
request to the coordinator through Resend. It never creates an administrator
account or grants access.

## Configure and deploy

The Firebase project must be on the **Blaze (pay-as-you-go) plan** before
Cloud Functions can be deployed. I did not change the billing plan
automatically.

1. Create a Resend account and obtain an API key.
2. Store the key in Firebase Secret Manager:

   ```sh
   firebase functions:secrets:set RESEND_API_KEY --project ffpmupt-402e1
   ```

3. Use `onboarding@resend.dev` only for initial testing. For production,
   verify a sender domain, copy `.env.example` to
   `.env.ffpmupt-402e1`, and set `ACCESS_REQUEST_FROM` there to a sender on
   that domain. Do not commit the project-specific `.env` file.
4. Install the function dependencies and deploy the function, rules, and web
   app:

   ```sh
   cd functions
   npm install
   cd ..
   flutter build web
   firebase deploy --only functions,firestore:rules,hosting --project ffpmupt-402e1
   ```

The recipient defaults to `osman.gimenes@gmail.com`. Change it with the
`ACCESS_REQUEST_RECIPIENT` deployment parameter if needed.
