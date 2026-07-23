import { useState } from 'react';
import TopBar from './components/TopBar.jsx';
import './FaqPage.css';

const FAQ_SECTIONS = [
  {
    id: 'general',
    title: 'General',
    questions: [
      {
        id: 'q1',
        question: 'What is KnightRate?',
        answer:
          "KnightRate is a course review platform built for UCF Computer Science and IT students. Search the course catalog, see difficulty and quality ratings from students who've taken a class, and share your own experience once you have.",
      },
      {
        id: 'q2',
        question: 'Is KnightRate free to use?',
        answer: 'Yes — browsing courses, reading reviews, and creating an account are all completely free.',
      },
      {
        id: 'q3',
        question: 'Who can leave a course review?',
        answer:
          'Any registered, verified student can leave a review. You can submit one review per course, and you can edit or delete it any time from that course\'s page.',
      },
      {
        id: 'q4',
        question: 'What are some upcoming features?',
        answer:
          "We're continuing to build out course resources (student-submitted links and study materials) and bookmarking, along with more ways to sort and filter the course catalog.",
      },
    ],
  },
  {
    id: 'account',
    title: 'Account & Privacy',
    questions: [
      {
        id: 'q5',
        question: 'How do I create an account?',
        answer:
          "Click the account icon and choose Register. After signing up, we'll email you a verification code — enter it on the next screen to activate your account and log in automatically.",
      },
      {
        id: 'q6',
        question: 'Are my reviews anonymous?',
        answer:
          'Your reviews are tied to your account for moderation purposes, but your name is never shown next to a review — other students only see the rating, tags, and comment.',
      },
      {
        id: 'q7',
        question: 'How do I delete my account?',
        answer:
          'Open your profile page and choose Delete Account. This permanently removes your account along with your reviews, bookmarks, and submitted resources.',
      },
      {
        id: 'q8',
        question: 'How do I delete my reviews?',
        answer:
          "Open the course page for the review you want to remove and click Delete on your review. This can be undone only by writing a new review for that course.",
      },
    ],
  },
];

function FaqPage({ onBack, onInfoClick, onCoursesClick, onBookmarksClick, onAccountClick, onLogoClick }) {
  const [openId, setOpenId] = useState(null);

  const toggleQuestion = (id) => {
    setOpenId((prev) => (prev === id ? null : id));
  };

  return (
    <div className="faq-page">
      <TopBar
        showBackButton
        onBack={onBack}
        onLogoClick={onLogoClick}
        showHelpIcon={false}
        onInfoClick={onInfoClick}
        onCoursesClick={onCoursesClick}
        onBookmarksClick={onBookmarksClick}
        onAccountClick={onAccountClick}
        fixed
      />
      <div className="faq-page-top-spacer" />

      <h1 className="faq-page-title">Frequently Asked Questions</h1>

      <div className="faq-content">
        {FAQ_SECTIONS.map((section) => (
          <section key={section.id} className="faq-section">
            <h2 className="faq-section-title">{section.title}</h2>

            <div className="faq-list">
              {section.questions.map((item) => {
                const isOpen = openId === item.id;
                return (
                  <div key={item.id} className={`faq-item ${isOpen ? 'open' : ''}`}>
                    <button
                      className="faq-question"
                      onClick={() => toggleQuestion(item.id)}
                      aria-expanded={isOpen}
                    >
                      <span className="faq-question-label">
                        <span className="faq-q-marker">Q:</span> {item.question}
                      </span>
                      <span className={`faq-toggle-icon ${isOpen ? 'open' : ''}`} aria-hidden="true">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
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
          </section>
        ))}
      </div>
    </div>
  );
}

export default FaqPage;
