import { useState } from 'react';
import Homepage from './pages/Homepage.jsx';
import AuthPage from './pages/AuthPage.jsx';
import AboutPage from './pages/AboutPage.jsx';
import FaqPage from './pages/FaqPage.jsx';
import CourseSearchPage from './pages/CourseSearchPage.jsx';
import './App.css';

function App() {
  const [view, setView] = useState('home'); // 'home' | 'auth' | 'about' | 'faq' | 'courses'

  const goToAuth = () => setView('auth');
  const goToAbout = () => setView('about');
  const goToFaq = () => setView('faq');
  const goToCourses = () => setView('courses');
  const goToHome = () => setView('home');

  if (view === 'auth') {
    return (
      <AuthPage
        onBack={goToHome}
        onInfoClick={goToAbout}
        onHelpClick={goToFaq}
        onCoursesClick={goToCourses}
      />
    );
  }

  if (view === 'about') {
    return (
      <AboutPage
        onBack={goToHome}
        onHelpClick={goToFaq}
        onCoursesClick={goToCourses}
        onAccountClick={goToAuth}
      />
    );
  }

  if (view === 'faq') {
    return (
      <FaqPage
        onBack={goToHome}
        onInfoClick={goToAbout}
        onCoursesClick={goToCourses}
        onAccountClick={goToAuth}
      />
    );
  }

  if (view === 'courses') {
    return (
      <CourseSearchPage
        onBack={goToHome}
        onInfoClick={goToAbout}
        onHelpClick={goToFaq}
        onAccountClick={goToAuth}
      />
    );
  }

  return (
    <Homepage
      onAccountClick={goToAuth}
      onInfoClick={goToAbout}
      onHelpClick={goToFaq}
      onCoursesClick={goToCourses}
    />
  );
}

export default App;