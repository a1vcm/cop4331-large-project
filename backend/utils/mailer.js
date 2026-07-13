const sgMail = require('@sendgrid/mail');

const apiKey = process.env.SENDGRID_API_KEY;
const fromEmail = process.env.SENDGRID_FROM_EMAIL;

if (apiKey) {
  sgMail.setApiKey(apiKey);
}

// Without SendGrid configured (local dev, CI), print the email instead of
// sending it so the register/verify/reset flows still work end-to-end.
async function sendEmail({ to, subject, text, html }) {
  if (!apiKey || !fromEmail) {
    console.log(
      `[mailer] SENDGRID_API_KEY/SENDGRID_FROM_EMAIL not set — printing email instead of sending.\n` +
      `To: ${to}\nSubject: ${subject}\n${text}`
    );
    return;
  }

  await sgMail.send({ to, from: fromEmail, subject, text, html });
}

module.exports = { sendEmail };
