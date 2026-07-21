import { MIN_PASSWORD_LENGTH, isPasswordValid } from '../../utils/validatePassword.js';
import './PasswordRequirements.css';

// Live red/green + asterisk requirement checklist shown under a new-password
// field. Structured as a list (of one, for now) so it's easy to add more
// requirements later without changing callers.
function PasswordRequirements({ password }) {
  const met = isPasswordValid(password);

  return (
    <ul className="password-requirements">
      <li className={`password-requirement ${met ? 'met' : 'unmet'}`}>
        <span className="requirement-marker" aria-hidden="true">{met ? '✓' : '*'}</span>
        <span>At least {MIN_PASSWORD_LENGTH} characters</span>
      </li>
    </ul>
  );
}

export default PasswordRequirements;
