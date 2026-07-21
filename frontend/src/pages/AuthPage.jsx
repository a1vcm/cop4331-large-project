import { useState } from 'react';
import TopBar from './components/TopBar.jsx';
import PasswordRequirements from './components/PasswordRequirements.jsx';
import { setAuthToken, setAuthUser, getErrorMessage } from '../api/client.js';
import { register, verifyEmail, resendVerification, login, forgotPassword, resetPassword } from '../api/auth.js';
import { MIN_PASSWORD_LENGTH, isPasswordValid } from '../utils/validatePassword.js';
import './AuthPage.css';

function AuthPage({ onBack, onInfoClick, onHelpClick, onCoursesClick }) {
  const [mode, setMode] = useState('login');
  const [showVerification, setShowVerification] = useState(false);
  const [verificationCode, setVerificationCode] = useState('');
  const [verificationMessage, setVerificationMessage] = useState(null);

  const [loginEmail, setLoginEmail] = useState('');
  const [loginPassword, setLoginPassword] = useState('');
  const [authMessage, setAuthMessage] = useState(null);

  const [regEmail, setRegEmail] = useState('');
  const [regUsername, setRegUsername] = useState('');
  const [regPassword, setRegPassword] = useState('');
  const [regConfirmPassword, setRegConfirmPassword] = useState('');
  const [agreedToTerms, setAgreedToTerms] = useState(false);

  const [showForgotPassword, setShowForgotPassword] = useState(false);
  const [forgotStep, setForgotStep] = useState('request'); // 'request' | 'reset'
  const [forgotEmail, setForgotEmail] = useState('');
  const [resetCode, setResetCode] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [newPasswordConfirm, setNewPasswordConfirm] = useState('');
  const [forgotMessage, setForgotMessage] = useState(null);

  const handleLogin = async (e) => {
    e.preventDefault();
    setAuthMessage(null);
    try {
      const data = await login({ email: loginEmail, password: loginPassword });
      setAuthToken(data.token);
      setAuthUser({ id: data.id, username: data.username, email: data.email });
      if (onBack) onBack();
    } catch (err) {
      if (err?.response?.data?.unverified) {
        setRegEmail(loginEmail);
        setVerificationMessage({ type: 'error', text: 'Please verify your email to continue.' });
        setShowVerification(true);
      } else {
        setAuthMessage({ type: 'error', text: getErrorMessage(err) });
      }
    }
  };

  const handleRegister = async (e) => {
    e.preventDefault();
    setAuthMessage(null);
    if (!isPasswordValid(regPassword)) {
      setAuthMessage({ type: 'error', text: `Password must be at least ${MIN_PASSWORD_LENGTH} characters` });
      return;
    }
    if (regPassword !== regConfirmPassword) {
      setAuthMessage({ type: 'error', text: 'Passwords do not match' });
      return;
    }
    if (!agreedToTerms) {
      setAuthMessage({ type: 'error', text: 'You must agree to the Terms of Service' });
      return;
    }

    try {
      await register({ username: regUsername, email: regEmail, password: regPassword });
      setVerificationMessage(null);
      setShowVerification(true);
    } catch (err) {
      setAuthMessage({ type: 'error', text: getErrorMessage(err) });
    }
  };

  const handleVerify = async (e) => {
    e.preventDefault();
    try {
      const data = await verifyEmail({ email: regEmail, code: verificationCode });
      setAuthToken(data.token);
      setAuthUser({ id: data.id, username: data.username, email: data.email });
      setShowVerification(false);
      if (onBack) onBack();
    } catch (err) {
      setVerificationMessage({ type: 'error', text: getErrorMessage(err) });
    }
  };

  const handleResend = async () => {
    try {
      await resendVerification({ email: regEmail });
      setVerificationMessage({ type: 'success', text: 'Code resent — check your email.' });
    } catch (err) {
      setVerificationMessage({ type: 'error', text: getErrorMessage(err) });
    }
  };

  const openForgotPassword = () => {
    setForgotEmail(loginEmail);
    setForgotStep('request');
    setForgotMessage(null);
    setResetCode('');
    setNewPassword('');
    setNewPasswordConfirm('');
    setShowForgotPassword(true);
  };

  const handleForgotRequest = async (e) => {
    e.preventDefault();
    try {
      const data = await forgotPassword({ email: forgotEmail });
      setForgotStep('reset');
      setForgotMessage({ type: 'success', text: data.message });
    } catch (err) {
      setForgotMessage({ type: 'error', text: getErrorMessage(err) });
    }
  };

  const handleResetPassword = async (e) => {
    e.preventDefault();
    if (!isPasswordValid(newPassword)) {
      setForgotMessage({ type: 'error', text: `Password must be at least ${MIN_PASSWORD_LENGTH} characters` });
      return;
    }
    if (newPassword !== newPasswordConfirm) {
      setForgotMessage({ type: 'error', text: 'Passwords do not match' });
      return;
    }
    try {
      await resetPassword({ email: forgotEmail, code: resetCode, newPassword });
      setShowForgotPassword(false);
      setMode('login');
      setLoginEmail(forgotEmail);
      setLoginPassword('');
      setAuthMessage({ type: 'success', text: 'Password reset — log in with your new password.' });
    } catch (err) {
      setForgotMessage({ type: 'error', text: getErrorMessage(err) });
    }
  };

  return (
    <div className="auth-page">
      <TopBar
        showBackButton
        onBack={onBack}
        showAccountIcon={false}
        onInfoClick={onInfoClick}
        onHelpClick={onHelpClick}
        onCoursesClick={onCoursesClick}
        fixed
      />
      <div className="auth-page-top-spacer" />

      <div className="auth-page-content">
        <div className="auth-card">
          <div className="auth-tabs">
            <button
              type="button"
              className={`auth-tab ${mode === 'login' ? 'active' : ''}`}
              onClick={() => setMode('login')}
            >
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4" />
                <path d="M10 17l5-5-5-5" />
                <path d="M15 12H3" />
              </svg>
              <span>Log In</span>
            </button>
            <button
              type="button"
              className={`auth-tab ${mode === 'register' ? 'active' : ''}`}
              onClick={() => setMode('register')}
            >
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M9 11a3 3 0 1 0 0-6 3 3 0 0 0 0 6z" />
                <path d="M3 20c0-3.5 2.7-6 6-6s6 2.5 6 6" />
                <path d="M18 8v6M15 11h6" />
              </svg>
              <span>Register</span>
            </button>
          </div>

          {mode === 'login' && (
            <form className="auth-form" onSubmit={handleLogin}>
              <h1 className="auth-heading">Welcome Back</h1>

              <label className="input-field">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <rect x="3" y="5" width="18" height="14" rx="2" />
                  <path d="M3 7l9 6 9-6" />
                </svg>
                <input
                  type="email"
                  placeholder="Email"
                  value={loginEmail}
                  onChange={(e) => setLoginEmail(e.target.value)}
                  required
                />
              </label>

              <label className="input-field">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <rect x="5" y="11" width="14" height="9" rx="2" />
                  <path d="M8 11V7a4 4 0 0 1 8 0v4" />
                </svg>
                <input
                  type="password"
                  placeholder="Password"
                  value={loginPassword}
                  onChange={(e) => setLoginPassword(e.target.value)}
                  required
                />
              </label>

              {authMessage && <p className={`auth-message ${authMessage.type}`}>{authMessage.text}</p>}

              <button type="submit" className="auth-submit">Log In</button>

              <button type="button" className="auth-link" onClick={openForgotPassword}>
                Forgot password?
              </button>
            </form>
          )}

          {mode === 'register' && (
            <form className="auth-form" onSubmit={handleRegister}>
              <h1 className="auth-heading">Create Your Account</h1>

              <label className="input-field">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <rect x="3" y="5" width="18" height="14" rx="2" />
                  <path d="M3 7l9 6 9-6" />
                </svg>
                <input
                  type="email"
                  placeholder="Email"
                  value={regEmail}
                  onChange={(e) => setRegEmail(e.target.value)}
                  required
                />
              </label>

              <label className="input-field">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <circle cx="12" cy="8" r="4" />
                  <path d="M4 20c0-4 4-6 8-6s8 2 8 6" />
                </svg>
                <input
                  type="text"
                  placeholder="Username"
                  value={regUsername}
                  onChange={(e) => setRegUsername(e.target.value)}
                  required
                />
              </label>

              <label className="input-field">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <rect x="5" y="11" width="14" height="9" rx="2" />
                  <path d="M8 11V7a4 4 0 0 1 8 0v4" />
                </svg>
                <input
                  type="password"
                  placeholder="Password"
                  value={regPassword}
                  onChange={(e) => setRegPassword(e.target.value)}
                  required
                />
              </label>

              <PasswordRequirements password={regPassword} />

              <label className="input-field">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <rect x="5" y="11" width="14" height="9" rx="2" />
                  <path d="M8 11V7a4 4 0 0 1 8 0v4" />
                </svg>
                <input
                  type="password"
                  placeholder="Confirm Password"
                  value={regConfirmPassword}
                  onChange={(e) => setRegConfirmPassword(e.target.value)}
                  required
                />
              </label>

              <label className="checkbox-field">
                <input
                  type="checkbox"
                  checked={agreedToTerms}
                  onChange={(e) => setAgreedToTerms(e.target.checked)}
                />
                <span>I agree to the Terms of Service</span>
              </label>

              {authMessage && <p className={`auth-message ${authMessage.type}`}>{authMessage.text}</p>}

              <button type="submit" className="auth-submit">Create Account</button>
            </form>
          )}

          {showVerification && (
            <div className="verification-overlay">
              <form className="verification-card" onSubmit={handleVerify}>
                <h2 className="verification-heading">Verify Your Email</h2>
                <p className="verification-subtext">
                  We sent a code to {regEmail || 'your email'}
                </p>

                <input
                  type="text"
                  className="verification-input"
                  placeholder="Enter code"
                  value={verificationCode}
                  onChange={(e) => setVerificationCode(e.target.value)}
                  maxLength={6}
                  required
                />

                {verificationMessage && (
                  <p className={`auth-message ${verificationMessage.type}`}>{verificationMessage.text}</p>
                )}

                <button type="submit" className="verification-submit">Verify</button>

                <button
                  type="button"
                  className="verification-resend"
                  onClick={handleResend}
                >
                  Resend code
                </button>
              </form>
            </div>
          )}

          {showForgotPassword && (
            <div className="verification-overlay">
              {forgotStep === 'request' ? (
                <form className="verification-card" onSubmit={handleForgotRequest}>
                  <h2 className="verification-heading">Reset Password</h2>
                  <p className="verification-subtext">
                    Enter your account email and we'll send a reset code.
                  </p>

                  <input
                    type="email"
                    className="verification-input"
                    placeholder="Email"
                    value={forgotEmail}
                    onChange={(e) => setForgotEmail(e.target.value)}
                    required
                  />

                  {forgotMessage && (
                    <p className={`auth-message ${forgotMessage.type}`}>{forgotMessage.text}</p>
                  )}

                  <button type="submit" className="verification-submit">Send Code</button>

                  <button
                    type="button"
                    className="verification-resend"
                    onClick={() => setShowForgotPassword(false)}
                  >
                    Back to Log In
                  </button>
                </form>
              ) : (
                <form className="verification-card" onSubmit={handleResetPassword}>
                  <h2 className="verification-heading">Enter Reset Code</h2>
                  <p className="verification-subtext">
                    We sent a code to {forgotEmail || 'your email'}
                  </p>

                  <input
                    type="text"
                    className="verification-input"
                    placeholder="Reset code"
                    value={resetCode}
                    onChange={(e) => setResetCode(e.target.value)}
                    maxLength={6}
                    required
                  />

                  <input
                    type="password"
                    className="verification-input"
                    placeholder="New password"
                    value={newPassword}
                    onChange={(e) => setNewPassword(e.target.value)}
                    required
                  />

                  <PasswordRequirements password={newPassword} />

                  <input
                    type="password"
                    className="verification-input"
                    placeholder="Confirm new password"
                    value={newPasswordConfirm}
                    onChange={(e) => setNewPasswordConfirm(e.target.value)}
                    required
                  />

                  {forgotMessage && (
                    <p className={`auth-message ${forgotMessage.type}`}>{forgotMessage.text}</p>
                  )}

                  <button type="submit" className="verification-submit">Reset Password</button>

                  <button
                    type="button"
                    className="verification-resend"
                    onClick={handleForgotRequest}
                  >
                    Resend code
                  </button>
                </form>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default AuthPage;
