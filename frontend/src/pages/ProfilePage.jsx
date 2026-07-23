import { useEffect, useState } from 'react';
import TopBar from './components/TopBar.jsx';
import PasswordRequirements from './components/PasswordRequirements.jsx';
import { getMyReviews } from '../api/reviews.js';
import {
  changeUsername,
  requestEmailChange,
  verifyEmailChange,
  changePassword,
  deleteAccount,
} from '../api/users.js';
import { getAuthUser, setAuthUser, clearAuthSession, getErrorMessage } from '../api/client.js';
import { MIN_PASSWORD_LENGTH, isPasswordValid } from '../utils/validatePassword.js';
import './ProfilePage.css';

function ProfilePage({
  onBack,
  onInfoClick,
  onHelpClick,
  onCoursesClick,
  onBookmarksClick,
  onLoggedOut,
  onCourseClick,
  onLogoClick,
}) {
  const [user, setUser] = useState(getAuthUser());
  const [tab, setTab] = useState('overview'); // 'overview' | 'edit'

  // Recent reviews (top 3, most recent first — per the Figma comment)
  const [reviews, setReviews] = useState([]);
  const [loadingReviews, setLoadingReviews] = useState(true);
  const [reviewsError, setReviewsError] = useState(null);

  // Account settings state
  const [openSection, setOpenSection] = useState(null); // 'username' | 'email' | 'password' | null
  const [message, setMessage] = useState(null); // { section, type, text }
  const [saving, setSaving] = useState(false);

  const [newUsername, setNewUsername] = useState('');
  const [newEmail, setNewEmail] = useState('');
  const [emailStep, setEmailStep] = useState('request'); // 'request' | 'verify'
  const [emailCode, setEmailCode] = useState('');
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [newPasswordConfirm, setNewPasswordConfirm] = useState('');
  const [deletePassword, setDeletePassword] = useState('');

  useEffect(() => {
    getMyReviews()
      .then((data) => {
        const sorted = [...data].sort(
          (a, b) => new Date(b.createdAt ?? 0) - new Date(a.createdAt ?? 0)
        );
        setReviews(sorted.slice(0, 3));
      })
      .catch((err) => setReviewsError(getErrorMessage(err, 'Failed to load your reviews.')))
      .finally(() => setLoadingReviews(false));
  }, []);

  const say = (section, type, text) => setMessage({ section, type, text });

  const handleLogout = () => {
    clearAuthSession();
    if (onLoggedOut) onLoggedOut();
  };

  const toggleSection = (name) => {
    setMessage(null);
    setOpenSection((prev) => (prev === name ? null : name));
    setNewUsername('');
    setNewEmail('');
    setEmailStep('request');
    setEmailCode('');
    setCurrentPassword('');
    setNewPassword('');
    setNewPasswordConfirm('');
  };

  const handleUsername = async (e) => {
    e.preventDefault();
    setSaving(true);
    setMessage(null);
    try {
      const data = await changeUsername({ username: newUsername.trim() });
      const updated = { ...user, username: data.username ?? newUsername.trim() };
      setAuthUser(updated);
      setUser(updated);
      setOpenSection(null);
      say('username', 'success', 'Username updated.');
    } catch (err) {
      say('username', 'error', getErrorMessage(err));
    } finally {
      setSaving(false);
    }
  };

  const handleEmailRequest = async (e) => {
    e.preventDefault();
    setSaving(true);
    setMessage(null);
    try {
      await requestEmailChange({ newEmail: newEmail.trim() });
      setEmailStep('verify');
      say('email', 'success', `Code sent to ${newEmail.trim()} — check that inbox.`);
    } catch (err) {
      say('email', 'error', getErrorMessage(err));
    } finally {
      setSaving(false);
    }
  };

  const handleEmailVerify = async (e) => {
    e.preventDefault();
    setSaving(true);
    setMessage(null);
    try {
      const data = await verifyEmailChange({ code: emailCode.trim() });
      const updated = { ...user, email: data.email ?? newEmail.trim() };
      setAuthUser(updated);
      setUser(updated);
      setOpenSection(null);
      setEmailStep('request');
      say('email', 'success', 'Email updated.');
    } catch (err) {
      say('email', 'error', getErrorMessage(err));
    } finally {
      setSaving(false);
    }
  };

  const handlePassword = async (e) => {
    e.preventDefault();
    if (!isPasswordValid(newPassword)) {
      say('password', 'error', `Password must be at least ${MIN_PASSWORD_LENGTH} characters`);
      return;
    }
    if (newPassword !== newPasswordConfirm) {
      say('password', 'error', 'Passwords do not match');
      return;
    }
    setSaving(true);
    setMessage(null);
    try {
      await changePassword({ currentPassword, newPassword });
      setOpenSection(null);
      say('password', 'success', 'Password changed.');
    } catch (err) {
      say('password', 'error', getErrorMessage(err));
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (e) => {
    e.preventDefault();
    if (!window.confirm("Delete your account permanently? This removes all your reviews and can't be undone.")) {
      return;
    }
    setSaving(true);
    setMessage(null);
    try {
      await deleteAccount({ password: deletePassword });
      clearAuthSession();
      if (onLoggedOut) onLoggedOut();
    } catch (err) {
      say('delete', 'error', getErrorMessage(err));
      setSaving(false);
    }
  };

  return (
    <div className="profile-page">
      <TopBar
        showBackButton
        onBack={onBack}
        onLogoClick={onLogoClick}
        showAccountIcon={false}
        onInfoClick={onInfoClick}
        onHelpClick={onHelpClick}
        onCoursesClick={onCoursesClick}
        onBookmarksClick={onBookmarksClick}
        fixed
      />
      <div className="profile-top-spacer" />

      <div className="profile-content">
        <div className="profile-card">
          <div className="profile-avatar" aria-hidden="true">
            {user?.username ? (
              <span className="profile-avatar-initial">
                {user.username[0].toUpperCase()}
              </span>
            ) : (
              // Default blank-user icon — same silhouette as the TopBar
              // account button, in the brand accent color.
              <svg
                className="profile-avatar-icon"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
              >
                <circle cx="12" cy="8" r="4" />
                <path d="M4 20c0-4 4-6 8-6s8 2 8 6" />
              </svg>
            )}
          </div>

          <nav className="profile-sidebar">
            <button
              type="button"
              className={`profile-nav-btn ${tab === 'overview' ? 'active' : ''}`}
              onClick={() => setTab('overview')}
            >
              Overview
            </button>
            <button
              type="button"
              className={`profile-nav-btn ${tab === 'edit' ? 'active' : ''}`}
              onClick={() => {
                setTab('edit');
                setOpenSection(null);
                setMessage(null);
              }}
            >
              Account
            </button>
            <button type="button" className="profile-nav-btn" onClick={handleLogout}>
              Log Out
            </button>
          </nav>

          <div className="profile-main">
            {tab === 'overview' && (
              <>
                <h1 className="profile-username">{user?.username}</h1>
                <p className="profile-email">{user?.email}</p>

                <h2 className="profile-section-heading">Recent Reviews</h2>

                {loadingReviews && <p className="profile-muted">Loading your reviews…</p>}
                {reviewsError && <p className="profile-muted">{reviewsError}</p>}
                {!loadingReviews && !reviewsError && reviews.length === 0 && (
                  <p className="profile-muted">You haven't written any reviews yet.</p>
                )}

                <div className="profile-review-list">
                  {reviews.map((review) => {
                    const course = typeof review.courseId === 'object' ? review.courseId : null;
                    return (
                      <button
                        key={review._id}
                        type="button"
                        className="profile-review-card"
                        onClick={() => course && onCourseClick && onCourseClick(course)}
                      >
                        <span className="profile-review-course">
                          {course ? `${course.course_code} — ${course.title}` : 'Course review'}
                        </span>
                        <span className="profile-review-meta">
                          Quality: {review.quality}/5 &nbsp;•&nbsp; Difficulty: {review.difficulty}/5
                          {review.term ? ` • ${review.term}` : ''}
                        </span>
                        {review.comment && (
                          <span className="profile-review-comment">{review.comment}</span>
                        )}
                      </button>
                    );
                  })}
                </div>
              </>
            )}

            {tab === 'edit' && (
              <>
                <h1 className="profile-section-title">Account Settings</h1>

                {/* Username */}
                <div className="settings-row">
                  <div className="settings-row-info">
                    <span className="settings-label">Username</span>
                    <span className="settings-value">{user?.username}</span>
                  </div>
                  <button
                    type="button"
                    className="settings-change-btn"
                    onClick={() => toggleSection('username')}
                  >
                    Change
                  </button>
                </div>
                {message?.section === 'username' && (
                  <p className={`settings-message ${message.type}`}>{message.text}</p>
                )}
                {openSection === 'username' && (
                  <form className="settings-form" onSubmit={handleUsername}>
                    <input
                      type="text"
                      placeholder="New username"
                      value={newUsername}
                      onChange={(e) => setNewUsername(e.target.value)}
                      required
                    />
                    <div className="settings-form-actions">
                      <button
                        type="button"
                        className="settings-cancel"
                        onClick={() => setOpenSection(null)}
                        disabled={saving}
                      >
                        Cancel
                      </button>
                      <button type="submit" className="settings-save" disabled={saving}>
                        {saving ? 'Saving…' : 'Save'}
                      </button>
                    </div>
                  </form>
                )}

                {/* Email */}
                <div className="settings-row">
                  <div className="settings-row-info">
                    <span className="settings-label">Email</span>
                    <span className="settings-value">{user?.email}</span>
                  </div>
                  <button
                    type="button"
                    className="settings-change-btn"
                    onClick={() => toggleSection('email')}
                  >
                    Change
                  </button>
                </div>
                {message?.section === 'email' && (
                  <p className={`settings-message ${message.type}`}>{message.text}</p>
                )}
                {openSection === 'email' && emailStep === 'request' && (
                  <form className="settings-form" onSubmit={handleEmailRequest}>
                    <input
                      type="email"
                      placeholder="New email address"
                      value={newEmail}
                      onChange={(e) => setNewEmail(e.target.value)}
                      required
                    />
                    <div className="settings-form-actions">
                      <button
                        type="button"
                        className="settings-cancel"
                        onClick={() => setOpenSection(null)}
                        disabled={saving}
                      >
                        Cancel
                      </button>
                      <button type="submit" className="settings-save" disabled={saving}>
                        {saving ? 'Sending…' : 'Send Code'}
                      </button>
                    </div>
                  </form>
                )}
                {openSection === 'email' && emailStep === 'verify' && (
                  <form className="settings-form" onSubmit={handleEmailVerify}>
                    <input
                      type="text"
                      placeholder="Verification code"
                      value={emailCode}
                      onChange={(e) => setEmailCode(e.target.value)}
                      maxLength={6}
                      required
                    />
                    <div className="settings-form-actions">
                      <button
                        type="button"
                        className="settings-cancel"
                        onClick={() => {
                          setOpenSection(null);
                          setEmailStep('request');
                        }}
                        disabled={saving}
                      >
                        Cancel
                      </button>
                      <button type="submit" className="settings-save" disabled={saving}>
                        {saving ? 'Verifying…' : 'Verify'}
                      </button>
                    </div>
                  </form>
                )}

                {/* Password */}
                <div className="settings-row">
                  <div className="settings-row-info">
                    <span className="settings-label">Password</span>
                    <span className="settings-value">••••••••</span>
                  </div>
                  <button
                    type="button"
                    className="settings-change-btn"
                    onClick={() => toggleSection('password')}
                  >
                    Change
                  </button>
                </div>
                {message?.section === 'password' && (
                  <p className={`settings-message ${message.type}`}>{message.text}</p>
                )}
                {openSection === 'password' && (
                  <form className="settings-form" onSubmit={handlePassword}>
                    <input
                      type="password"
                      placeholder="Current password"
                      value={currentPassword}
                      onChange={(e) => setCurrentPassword(e.target.value)}
                      required
                    />
                    <input
                      type="password"
                      placeholder="New password"
                      value={newPassword}
                      onChange={(e) => setNewPassword(e.target.value)}
                      required
                    />
                    <PasswordRequirements password={newPassword} />
                    <input
                      type="password"
                      placeholder="Confirm new password"
                      value={newPasswordConfirm}
                      onChange={(e) => setNewPasswordConfirm(e.target.value)}
                      required
                    />
                    <div className="settings-form-actions">
                      <button
                        type="button"
                        className="settings-cancel"
                        onClick={() => setOpenSection(null)}
                        disabled={saving}
                      >
                        Cancel
                      </button>
                      <button type="submit" className="settings-save" disabled={saving}>
                        {saving ? 'Saving…' : 'Save'}
                      </button>
                    </div>
                  </form>
                )}

                <hr className="settings-divider" />

                <h2 className="danger-heading">Delete Account</h2>
                <p className="profile-muted">
                  This permanently removes your account and all of your reviews.
                </p>
                <form className="settings-form" onSubmit={handleDelete}>
                  <input
                    type="password"
                    placeholder="Confirm your password"
                    value={deletePassword}
                    onChange={(e) => setDeletePassword(e.target.value)}
                    required
                  />
                  {message?.section === 'delete' && (
                    <p className={`settings-message ${message.type}`}>{message.text}</p>
                  )}
                  <button type="submit" className="delete-btn" disabled={saving}>
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                      <path d="M3 6h18" />
                      <path d="M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
                      <path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6" />
                      <path d="M10 11v6M14 11v6" />
                    </svg>
                    {saving ? 'Deleting…' : 'Delete Account'}
                  </button>
                </form>
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

export default ProfilePage;
