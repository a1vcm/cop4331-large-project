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
        question: 'Placeholder question one?',
        answer:
          'Placeholder answer text goes here. This will explain the answer to the first question in more detail once real content is written.',
      },
      {
        id: 'q2',
        question: 'Placeholder question two?',
        answer: 'Placeholder answer text goes here for question two.',
      },
      {
        id: 'q3',
        question: 'Placeholder question three?',
        answer: 'Placeholder answer text goes here for question three.',
      },
    ],
  },
  {
    id: 'section-2',
    title: 'Account & Reviews',
    questions: [
      {
        id: 'q4',
        question: 'Placeholder question four?',
        answer: 'Placeholder answer text goes here for question four.',
      },
      {
        id: 'q5',
        question: 'Placeholder question five?',
        answer: 'Placeholder answer text goes here for question five.',
      },
      {
        id: 'q6',
        question: 'Placeholder question six?',
        answer: 'Placeholder answer text goes here for question six.',
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