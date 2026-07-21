import { useState } from 'react';
import Homepage from './pages/Homepage.jsx';
import AuthPage from './pages/AuthPage.jsx';
import AboutPage from './pages/AboutPage.jsx';
import CourseSearchPage from './pages/CourseSearchPage.jsx';
import CourseDetailPage from './pages/CourseDetailPage.jsx';
import ProfilePage from './pages/ProfilePage.jsx';
import ResourcesPage from './pages/ResourcesPage.jsx';
import WriteReviewPage from './pages/WriteReviewPage.jsx';
import Footer from './pages/components/Footer.jsx';
import ScrollToTopButton from './pages/components/ScrollToTopButton.jsx';
import { isLoggedIn } from './api/client.js';

function App() {
  const [view, setView] = useState('home'); // 'home' | 'auth' | 'about' | 'courses' | 'courseDetail' | 'profile' | 'resources' | 'writeReview'
  const [courseQuery, setCourseQuery] = useState('');
  const [selectedCourseId, setSelectedCourseId] = useState(null);
  const [reviewDraft, setReviewDraft] = useState(null); // null = new review, review object = editing
  // Bumped whenever a review is saved, so CourseDetailPage's fetch effect
  // (keyed on courseId, which doesn't change on save) knows to refetch.
  const [refreshSignal, setRefreshSignal] = useState(0);

  const goToAbout = () => setView('about');
  // FAQ content now lives inside the unified About page.
  const goToFaq = goToAbout;
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

  const goToResources = (courseId) => {
    setSelectedCourseId(courseId);
    setView('resources');
  };

  const goToWriteReview = (courseId, existing = null) => {
    setSelectedCourseId(courseId);
    setReviewDraft(existing);
    setView('writeReview');
  };

  const exitWriteReview = () => setView('courseDetail');

  const handleReviewSaved = () => {
    setRefreshSignal((n) => n + 1);
    setView('courseDetail');
  };

  let content;

  if (view === 'auth') {
    content = (
      <AuthPage
        onBack={exitAuth}
        onInfoClick={goToAbout}
        onHelpClick={goToFaq}
        onCoursesClick={() => goToCourses()}
      />
    );
  } else if (view === 'profile') {
    content = (
      <ProfilePage
        onBack={goToHome}
        onInfoClick={goToAbout}
        onHelpClick={goToFaq}
        onCoursesClick={() => goToCourses()}
        onLoggedOut={goToHome}
        onCourseClick={goToCourseDetail}
      />
    );
  } else if (view === 'about') {
    content = (
      <AboutPage
        onBack={goToHome}
        onCoursesClick={() => goToCourses()}
        onAccountClick={goToAccount}
      />
    );
  } else if (view === 'courses') {
    content = (
      <CourseSearchPage
        onBack={goToHome}
        onInfoClick={goToAbout}
        onHelpClick={goToFaq}
        onAccountClick={goToAccount}
        initialQuery={courseQuery}
        onShowReviews={goToCourseDetail}
      />
    );
  } else if (view === 'courseDetail') {
    content = (
      <CourseDetailPage
        courseId={selectedCourseId}
        onBack={() => setView('courses')}
        onAccountClick={goToAccount}
        onInfoClick={goToAbout}
        onHelpClick={goToFaq}
        onCoursesClick={() => goToCourses()}
        onViewResources={goToResources}
        onWriteReview={goToWriteReview}
        refreshSignal={refreshSignal}
      />
    );
  } else if (view === 'resources') {
    content = (
      <ResourcesPage
        courseId={selectedCourseId}
        onBack={() => setView('courseDetail')}
        onAccountClick={goToAccount}
      />
    );
  } else if (view === 'writeReview') {
    content = (
      <WriteReviewPage
        courseId={selectedCourseId}
        existing={reviewDraft}
        onCancel={exitWriteReview}
        onSaved={handleReviewSaved}
        onAccountClick={goToAccount}
      />
    );
  } else {
    content = (
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

  // Homepage mounts its own Footer (full-bleed, outside its centered content
  // wrapper) so it isn't rendered a second time here.
  const showFooter = view !== 'home';

  return (
    <>
      {content}
      {showFooter && <Footer />}
      <ScrollToTopButton />
    </>
  );
}

export default App;
