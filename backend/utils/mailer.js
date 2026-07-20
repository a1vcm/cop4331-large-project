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

  // error handling
  try {
    await sgMail.send({ to, from: fromEmail, subject, text, html });
    console.log(`[mailer] Email successfully sent to ${to}`);
  } catch (error) {
    // SendGrid embeds the specific API error message inside error.response.body
    console.error(`[mailer error] Failed to send email to ${to}:`, error.response?.body || error.message);
    throw error; // Re-throw so your controller knows the email failed
  }
}

module.exports = { sendEmail };