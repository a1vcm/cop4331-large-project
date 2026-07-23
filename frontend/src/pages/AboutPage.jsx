import { useEffect, useRef } from 'react';
import TopBar from './components/TopBar.jsx';
import ucfSeal from '../assets/ucflogos.webp';
import pondsPhoto from '../assets/ponds.webp';
import './AboutPage.css';

const TEAM_MEMBERS = [
  {
    id: 1,
    name: 'Alvaro Canseco-Martinez',
    role: 'Project Manager, Backend, Mobile',
    description: 'Focused on the backend code alongside making sure the mobile app worked.',
  },
  {
    id: 2,
    name: 'Mariem Touati',
    role: 'Frontend Developer',
    description: 'Focused on the UI/UX, some theming, and ensuring a flawless user flow.',
  },
  {
    id: 3,
    name: 'Jesus Gonzalez',
    role: 'Frontend, Backend, Mobile',
    description: '',
  },
  {
    id: 4,
    name: 'Jaden Harris',
    role: 'Frontend, Database',
    description: 'Designed the database and granted the team access, and floated in on frontend.',
  },
  {
    id: 5,
    name: 'Egor Schevchenko',
    role: 'API, Backend',
    description: 'Developed the necessary API endpoints and middleware for KnightRate to function.',
  },
  {
    id: 6,
    name: 'Justin Ciar',
    role: 'Frontend, Mobile',
    description: '',
  },
];

function initials(name) {
  return name
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0])
    .join('')
    .toUpperCase();
}

function useReveal() {
  const rootRef = useRef(null);

  useEffect(() => {
    const nodes = rootRef.current?.querySelectorAll('.reveal') ?? [];
    if (typeof IntersectionObserver === 'undefined') {
      nodes.forEach((node) => node.classList.add('in-view'));
      return;
    }
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add('in-view');
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.15 }
    );
    nodes.forEach((node) => observer.observe(node));
    return () => observer.disconnect();
  }, []);

  return rootRef;
}

function AboutPage({ onBack, onHelpClick, onCoursesClick, onBookmarksClick, onAccountClick }) {
  const rootRef = useReveal();

  return (
    <div className="about-page" ref={rootRef}>
      <TopBar
        showBackButton
        onBack={onBack}
        showInfoIcon={false}
        onHelpClick={onHelpClick}
        onCoursesClick={onCoursesClick}
        onBookmarksClick={onBookmarksClick}
        onAccountClick={onAccountClick}
        fixed
        transparent
      />

      <section className="about-hero" style={{ backgroundImage: `url(${pondsPhoto})` }}>
        <div className="about-hero-overlay" />
        <div className="about-hero-content">
          <img src={ucfSeal} alt="UCF" className="about-hero-seal" width="400" height="252" />
          <h1 className="about-hero-title">About Us</h1>
          <p className="about-hero-tagline">Meet the people behind it, and their thought process.</p>
        </div>
      </section>

      <section className="story-section reveal">
        <div className="story-copy">
          <span className="story-kicker">Why KnightRate</span>
          <h2 className="story-heading">For students, by students</h2>
          <p className="story-line">
            We got tired of guessing whether a course would wreck our GPA. Scrolling through Reddit
            threads was a chore, and finding real syllabi or study resources was worse — so we built
            the thing we wished we'd had freshman year.
          </p>
          <p className="story-line">
            Every rating comes from a verified fellow Knight, so you can trust what you're reading
            before you register. No more winging a class off a five-word review from three years ago.
          </p>
        </div>
      </section>

      <section className="team-band reveal">
        <div className="section-heading-wrap">
          <span className="section-kicker">The Crew</span>
          <h2 className="section-heading">Meet the Team</h2>
        </div>

        <div className="team-grid">
          {TEAM_MEMBERS.map((member) => (
            <div key={member.id} className="team-card">
              <div className="team-avatar">{initials(member.name)}</div>
              <h3 className="team-name">{member.name}</h3>
              <p className="team-role">{member.role}</p>
              {member.description && <p className="team-desc">{member.description}</p>}
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}

export default AboutPage;
