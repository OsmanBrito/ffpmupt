const { initializeApp } = require('firebase-admin/app');
const {
  FieldValue,
  getFirestore,
} = require('firebase-admin/firestore');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const {
  defineSecret,
  defineString,
} = require('firebase-functions/params');

initializeApp();

const resendApiKey = defineSecret('RESEND_API_KEY');
const recipient = defineString('ACCESS_REQUEST_RECIPIENT', {
  default: 'osman.gimenes@gmail.com',
});
const sender = defineString('ACCESS_REQUEST_FROM', {
  default: 'FFPMU Connect <onboarding@resend.dev>',
});

exports.sendAccessRequestEmail = onDocumentCreated(
  {
    document: 'accessRequests/{requestId}',
    region: 'europe-west1',
    secrets: [resendApiKey],
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      return;
    }

    const data = snapshot.data();
    const email = normalize(data.email);
    const displayName = String(data.displayName || '').trim();
    const countryName = String(data.countryName || '').trim();
    const countryCode = String(data.countryCode || '').trim();
    const role = String(data.role || '').trim();
    const message = String(data.message || '').trim();

    if (!isValidEmail(email) || !displayName || !countryName || !countryCode) {
      await snapshot.ref.update({
        emailStatus: 'invalid',
        emailError: 'The request did not contain the required fields.',
        updatedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    const recent = await getFirestore()
      .collection('accessRequests')
      .where('email', '==', email)
      .limit(20)
      .get();
    const now = Date.now();
    const isRecentDuplicate = recent.docs.some((document) => {
      if (document.id === snapshot.id) {
        return false;
      }
      const createdAt = document.data().createdAt?.toDate?.();
      return createdAt && now - createdAt.getTime() < 24 * 60 * 60 * 1000;
    });
    if (isRecentDuplicate) {
      await snapshot.ref.update({
        emailStatus: 'rate_limited',
        emailError: 'A request from this email was already sent recently.',
        updatedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    const apiKey = resendApiKey.value();
    if (!apiKey) {
      throw new Error('RESEND_API_KEY is not configured.');
    }

    const subject = `[FFPMU Connect] Administrator access request — ${countryName}`;
    const html = `
      <h2>FFPMU Connect administrator access request</h2>
      <p><strong>Country:</strong> ${escapeHtml(countryName)} (${escapeHtml(countryCode)})</p>
      <p><strong>Name:</strong> ${escapeHtml(displayName)}</p>
      <p><strong>Role:</strong> ${escapeHtml(role)}</p>
      <p><strong>Email:</strong> ${escapeHtml(email)}</p>
      <p><strong>Message:</strong><br>${escapeHtml(message || '—').replace(/\n/g, '<br>')}</p>
      <p>Review this request before creating an invitation in Operational CRM.</p>
    `;

    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
        'Idempotency-Key': `access-request-${snapshot.id}`,
      },
      body: JSON.stringify({
        from: sender.value(),
        to: [recipient.value()],
        reply_to: email,
        subject,
        html,
      }),
    });

    if (!response.ok) {
      const body = await response.text();
      await snapshot.ref.update({
        emailStatus: 'failed',
        emailError: `Email provider returned ${response.status}.`,
        updatedAt: FieldValue.serverTimestamp(),
      });
      throw new Error(`Resend failed (${response.status}): ${body}`);
    }

    const result = await response.json();
    await snapshot.ref.update({
      emailStatus: 'sent',
      providerMessageId: result.id || '',
      emailSentAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  },
);

function normalize(value) {
  return String(value || '').trim().toLowerCase();
}

function isValidEmail(value) {
  return /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(value);
}

function escapeHtml(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}
