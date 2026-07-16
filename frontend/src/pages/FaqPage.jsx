import { useState } from 'react';
import TopBar from './components/TopBar.jsx';
import './FaqPage.css';

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

function FaqPage({ onBack, onInfoClick, onCoursesClick, onAccountClick }) {
  const [openId, setOpenId] = useState(null);

  const toggleQuestion = (id) => {
    setOpenId((prev) => (prev === id ? null : id));
  };

  return (
    <div className="faq-page">
      <TopBar
        showBackButton
        onBack={onBack}
        showHelpIcon={false}
        onInfoClick={onInfoClick}
        onCoursesClick={onCoursesClick}
        onAccountClick={onAccountClick}
        fixed
      />
      <div className="faq-page-top-spacer" />

      <div className="faq-content">
        {FAQ_SECTIONS.map((section) => (
          <section key={section.id} className="faq-section">
            <h2 className="faq-section-title">{section.title}</h2>

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
                      <span className="faq-question-label">
                        <span className="faq-q-marker">Q:</span> {item.question}
                      </span>
                      <span className={`faq-toggle-icon ${isOpen ? 'open' : ''}`}>
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                          <path d="M5 12h14" />
                          <path d="M12 5v14" />
                        </svg>
                      </span>
                    </button>

                    <div className={`faq-answer-wrapper ${isOpen ? 'open' : ''}`}>
                      <div className="faq-answer">
                        <span className="faq-a-marker">A:</span> {item.answer}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </section>
        ))}
      </div>
    </div>
  );
}

export default FaqPage;