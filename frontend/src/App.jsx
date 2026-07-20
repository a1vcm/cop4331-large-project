import { useState } from 'react';
import Homepage from './pages/Homepage.jsx';
import AuthPage from './pages/AuthPage.jsx';
import AboutPage from './pages/AboutPage.jsx';
import FaqPage from './pages/FaqPage.jsx';
import CourseSearchPage from './pages/CourseSearchPage.jsx';
import CourseDetailPage from './pages/CourseDetailPage.jsx';
import ProfilePage from './pages/ProfilePage.jsx';
import { isLoggedIn } from './api/client.js';

function App() {
  const [view, setView] = useState('home'); // 'home' | 'auth' | 'about' | 'faq' | 'courses' | 'courseDetail' | 'profile'
  const [courseQuery, setCourseQuery] = useState('');
  const [selectedCourseId, setSelectedCourseId] = useState(null);

  const goToAbout = () => setView('about');
  const goToFaq = () => setView('faq');
  const goToHome = () => setView('home');

  // Account icon: profile when logged in, auth page when not.
  const goToAccount = () => setView(isLoggedIn() ? 'profile' : 'auth');

  // AuthPage calls onBack both for the manual back arrow AND after a
  // successful login/verify. By the time a successful login calls it, the
  // token is already stored — so this lands logged-in users on their
  // profile and everyone else back home. No AuthPage changes needed.
  const exitAuth = () => setView(isLoggedIn() ? 'profile' : 'home');

  const goToCourses = (query = '') => {
    setCourseQuery(query);
    setView('courses');
  };

  const goToCourseDetail = (course) => {
    setSelectedCourseId(course._id);
    setView('courseDetail');
  };

  if (view === 'auth') {
    return (
      <AuthPage
        onBack={exitAuth}
        onInfoClick={goToAbout}
        onHelpClick={goToFaq}
        onCoursesClick={() => goToCourses()}
      />
    );
  }

  if (view === 'profile') {
    return (
      <ProfilePage
        onBack={goToHome}
        onInfoClick={goToAbout}
        onHelpClick={goToFaq}
        onCoursesClick={() => goToCourses()}
        onLoggedOut={goToHome}
        onCourseClick={goToCourseDetail}
      />
    );
  }

  if (view === 'about') {
    return (
      <AboutPage
        onBack={goToHome}
        onHelpClick={goToFaq}
        onCoursesClick={() => goToCourses()}
        onAccountClick={goToAccount}
      />
    );
  }

  if (view === 'faq') {
    return (
      <FaqPage
        onBack={goToHome}
        onInfoClick={goToAbout}
        onCoursesClick={() => goToCourses()}
        onAccountClick={goToAccount}
      />
    );
  }

  if (view === 'courses') {
    return (
      <CourseSearchPage
        onBack={goToHome}
        onInfoClick={goToAbout}
        onHelpClick={goToFaq}
        onAccountClick={goToAccount}
        initialQuery={courseQuery}
        onShowReviews={goToCourseDetail}
      />
    );
  }

  if (view === 'courseDetail') {
    return (
      <CourseDetailPage
        courseId={selectedCourseId}
        onBack={() => setView('courses')}
        onAccountClick={goToAccount}
      />
    );
  }

  return (
    <Homepage
      onAccountClick={goToAccount}
      onInfoClick={goToAbout}
      onHelpClick={goToFaq}
      onCoursesClick={() => goToCourses()}
      onSearch={goToCourses}
      onCourseClick={goToCourseDetail}
    />
  );
}

export default App;
