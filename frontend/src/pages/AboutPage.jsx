import TopBar from './components/TopBar.jsx';
import stockUcf1 from '../assets/STOCK_UCF_1.jpg';
import './AboutPage.css';

const TEAM_MEMBERS = [
  {
    id: 1,
    name: 'Alvaro Canseco-Martinez',
    role: 'Project Manager, Backend, Mobile',
    description:
      'Focused on working on the backend code alongside making sure the mobile app worked. ',
  },
  {
    id: 2,
    name: 'Mariem Touati',
    role: 'Frontend Developer',
    description:
      'Fill in...',
  },
  {
    id: 3,
    name: 'Jesus Gonzalez',
    role: 'Frontend, Backend, Mobile',
    description:
      'Fill in...',
  },
  {
    id: 4,
    name: 'Jaden Harris',
    role: 'Frontend, Database',
    description:
      'Focused on designing the database and granting the team access, and acted as the floater for the frontend.',
  },
  {
    id: 5,
    name: 'Egor Schevchenko',
    role: 'UI/UX Designer',
    description:
      'Fill in...',
  },
  {
    id: 6,
    name: 'Justin Ciar',
    role: 'Frontend, Mobile',
    description:
      'Fill in...',
  },
];

function AboutPage({ onBack, onHelpClick, onCoursesClick, onAccountClick }) {
  return (
    <div className="about-page">
      <TopBar
        showBackButton
        onBack={onBack}
        showInfoIcon={false}
        onHelpClick={onHelpClick}
        onCoursesClick={onCoursesClick}
        onAccountClick={onAccountClick}
        fixed
      />
      <div className="about-page-top-spacer" />

      <section
        className="about-hero"
        style={{ backgroundImage: `url(${stockUcf1})` }}
      >
        <div className="about-hero-overlay" />
        <h1 className="about-hero-title">Meet the Team!</h1>
      </section>

      <section className="team-list">
        {TEAM_MEMBERS.map((member, index) => (
          <div
            key={member.id}
            className={`team-row ${index % 2 === 1 ? 'reversed' : ''}`}
          >
            <div className="team-photo-placeholder">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
                <rect x="3" y="3" width="18" height="18" rx="2" />
                <circle cx="8.5" cy="8.5" r="1.5" />
                <path d="M21 15l-5-5L5 21" />
              </svg>
            </div>

            <div className="team-info">
              <h2 className="team-name">{member.name}</h2>
              <p className="team-role">{member.role}</p>
              <p className="team-description">{member.description}</p>
            </div>
          </div>
        ))}
      </section>
    </div>
  );
}

export default AboutPage;