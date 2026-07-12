import { useState } from 'react';
import TopBar from './components/TopBar.jsx';
import './AuthPage.css';

function AuthPage({ onBack, onInfoClick, onHelpClick, onCoursesClick }) {
  const [mode, setMode] = useState('login');
  const [showVerification, setShowVerification] = useState(false);
  const [verificationCode, setVerificationCode] = useState('');

  const [loginEmail, setLoginEmail] = useState('');
  const [loginPassword, setLoginPassword] = useState('');

  const [regEmail, setRegEmail] = useState('');
  const [regUsername, setRegUsername] = useState('');
  const [regPassword, setRegPassword] = useState('');
  const [regConfirmPassword, setRegConfirmPassword] = useState('');
  const [agreedToTerms, setAgreedToTerms] = useState(false);

  const handleLogin = (e) => {
    e.preventDefault();
    console.log('Logging in with:', loginEmail);
  };

  const handleRegister = (e) => {
    e.preventDefault();
    if (regPassword !== regConfirmPassword) {
      console.log('Passwords do not match');
      return;
    }
    if (!agreedToTerms) {
      console.log('Must agree to terms');
      return;
    }
    console.log('Registering:', regEmail, regUsername);
    setShowVerification(true);
  };

  const handleVerify = (e) => {
    e.preventDefault();
    console.log('Verifying code:', verificationCode);
  };

  const handleResend = () => {
    console.log('Resending verification code to', regEmail);
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

              <button type="submit" className="auth-submit">Log In</button>

              <a href="#forgot" className="auth-link">Forgot password?</a>
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
        </div>
      </div>
    </div>
  );
}

export default AuthPage;