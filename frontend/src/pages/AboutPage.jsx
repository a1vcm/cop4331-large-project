import { useEffect, useRef, useState } from 'react';
import TopBar from './components/TopBar.jsx';
import ucfSeal from '../assets/ucflogos.png';
import pondsPhoto from '../assets/ponds.jpg';
import campusPhoto from '../assets/ucfcampus.png';
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
    description: '',
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
    role: 'UI/UX Designer',
    description: '',
  },
  {
    id: 6,
    name: 'Justin Ciar',
    role: 'Frontend, Mobile',
    description: '',
  },
];

const FAQ_SECTIONS = [
  {
    id: 'section-1',
    title: 'Getting Started',
    questions: [
      {
        id: 'q1',
        question: 'What is KnightRate?',
        answer:
          "KnightRate is a course review platform built for UCF Computer Science and IT students. Search the course catalog, see difficulty and quality ratings from students who've taken a class, and share your own experience once you have.",
      },
      {
        id: 'q2',
        question: 'How do I search for a class?',
        answer:
          'Use the search bar on the homepage or the Courses page and type a course code (like COP3502C) or a course name. You can filter by difficulty and sort by name, credits, or difficulty from the Courses page.',
      },
      {
        id: 'q3',
        question: 'Do I need an account to browse courses?',
        answer:
          'No — anyone can search the catalog and read reviews without an account. You only need to register and log in to write your own review.',
      },
    ],
  },
  {
    id: 'section-2',
    title: 'Account & Reviews',
    questions: [
      {
        id: 'q4',
        question: 'How do I create an account?',
        answer:
          "Click the account icon and choose Register. After signing up, we'll email you a verification code — enter it on the next screen to activate your account and log in automatically.",
      },
      {
        id: 'q5',
        question: 'How do I write or edit a review?',
        answer:
          "Open a course's page and click Write a Review. You can rate quality and difficulty, add the instructor, term, and grade, and leave a comment. You can only submit one review per course, but you can edit or delete it any time from that course's page.",
      },
      {
        id: 'q6',
        question: 'I forgot my password — what do I do?',
        answer:
          "On the Log In tab, click Forgot password?. We'll send a reset code to your email that you can use to set a new password.",
      },
    ],
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

function AboutPage({ onBack, onCoursesClick, onAccountClick }) {
  const [openId, setOpenId] = useState(null);
  const rootRef = useReveal();

  const toggleQuestion = (id) => {
    setOpenId((prev) => (prev === id ? null : id));
  };

  return (
    <div className="about-page" ref={rootRef}>
      <TopBar
        showBackButton
        onBack={onBack}
        showInfoIcon={false}
        showHelpIcon={false}
        onCoursesClick={onCoursesClick}
        onAccountClick={onAccountClick}
        fixed
        transparent
      />

      <section className="about-hero" style={{ backgroundImage: `url(${pondsPhoto})` }}>
        <div className="about-hero-overlay" />
        <div className="about-hero-content">
          <img src={ucfSeal} alt="UCF" className="about-hero-seal" />
          <h1 className="about-hero-title">About Us</h1>
          <p className="about-hero-tagline">Meet the people behind it, and their thought process.</p>
        </div>
      </section>

      <section className="story-section reveal">
        <div className="story-media">
          <img src={campusPhoto} alt="UCF campus" />
          <span className="story-media-frame" aria-hidden="true" />
        </div>
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

      <section className="faq-band reveal">
        <div className="section-heading-wrap">
          <span className="section-kicker">Q &amp; A</span>
          <h2 className="section-heading">Frequently Asked Questions</h2>
        </div>

        <div className="faq-content">
          {FAQ_SECTIONS.map((section) => (
            <div key={section.id} className="faq-section">
              <h3 className="faq-section-title">{section.title}</h3>

              <div className="faq-list">
                {section.questions.map((item) => {
                  const isOpen = openId === item.id;
                  return (
                    <div key={item.id} className="faq-item">
                      <button
                        className="faq-question"
                        onClick={() => toggleQuestion(item.id)}
                        aria-expanded={isOpen}
                      >
                        <span className="faq-question-label">{item.question}</span>
                        <span className={`faq-toggle-icon ${isOpen ? 'open' : ''}`}>
                          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                            <path d="M5 12h14" />
                            <path d="M12 5v14" />
                          </svg>
                        </span>
                      </button>

                      <div className={`faq-answer-wrapper ${isOpen ? 'open' : ''}`}>
                        <div className="faq-answer">{item.answer}</div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          ))}
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
