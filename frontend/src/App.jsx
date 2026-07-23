import { lazy, Suspense, useState } from 'react';
// Homepage is the landing view for every fresh visit, so it stays a static
// import (it's needed for first paint anyway). Every other page is loaded
// on demand — nobody pays for AuthPage/ProfilePage/etc. JS or CSS until
// they actually navigate there.
import Homepage from './pages/Homepage.jsx';
import Footer from './pages/components/Footer.jsx';
import ScrollToTopButton from './pages/components/ScrollToTopButton.jsx';
import { isLoggedIn } from './api/client.js';

const AuthPage = lazy(() => import('./pages/AuthPage.jsx'));
const AboutPage = lazy(() => import('./pages/AboutPage.jsx'));
const FaqPage = lazy(() => import('./pages/FaqPage.jsx'));
const CourseSearchPage = lazy(() => import('./pages/CourseSearchPage.jsx'));
const CourseDetailPage = lazy(() => import('./pages/CourseDetailPage.jsx'));
const ProfilePage = lazy(() => import('./pages/ProfilePage.jsx'));
const ResourcesPage = lazy(() => import('./pages/ResourcesPage.jsx'));
const WriteReviewPage = lazy(() => import('./pages/WriteReviewPage.jsx'));
const BookmarksPage = lazy(() => import('./pages/BookmarksPage.jsx'));

function App() {
  const [view, setView] = useState('home'); // 'home' | 'auth' | 'about' | 'faq' | 'courses' | 'courseDetail' | 'profile' | 'resources' | 'writeReview' | 'bookmarks'
  const [courseQuery, setCourseQuery] = useState('');
  const [selectedCourseId, setSelectedCourseId] = useState(null);
  const [reviewDraft, setReviewDraft] = useState(null); // null = new review, review object = editing
  // Bumped whenever a review is saved, so CourseDetailPage's fetch effect
  // (keyed on courseId, which doesn't change on save) knows to refetch.
  const [refreshSignal, setRefreshSignal] = useState(0);

  const goToAbout = () => setView('about');
  const goToFaq = () => setView('faq');
  const goToHome = () => setView('home');

  // Account icon: profile when logged in, auth page when not.
  const goToAccount = () => setView(isLoggedIn() ? 'profile' : 'auth');

  // Bookmarks icon: bookmarks list when logged in, auth page when not
  // (bookmarking requires an account).
  const goToBookmarks = () => setView(isLoggedIn() ? 'bookmarks' : 'auth');

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
        onBookmarksClick={goToBookmarks}
      />
    );
  } else if (view === 'profile') {
    content = (
      <ProfilePage
        onBack={goToHome}
        onInfoClick={goToAbout}
        onHelpClick={goToFaq}
        onCoursesClick={() => goToCourses()}
        onBookmarksClick={goToBookmarks}
        onLoggedOut={goToHome}
        onCourseClick={goToCourseDetail}
      />
    );
  } else if (view === 'about') {
    content = (
      <AboutPage
        onBack={goToHome}
        onHelpClick={goToFaq}
        onCoursesClick={() => goToCourses()}
        onBookmarksClick={goToBookmarks}
        onAccountClick={goToAccount}
      />
    );
  } else if (view === 'faq') {
    content = (
      <FaqPage
        onBack={goToHome}
        onInfoClick={goToAbout}
        onCoursesClick={() => goToCourses()}
        onBookmarksClick={goToBookmarks}
        onAccountClick={goToAccount}
      />
    );
  } else if (view === 'courses') {
    content = (
      <CourseSearchPage
        onBack={goToHome}
        onInfoClick={goToAbout}
        onHelpClick={goToFaq}
        onBookmarksClick={goToBookmarks}
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
        onBookmarksClick={goToBookmarks}
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
        onBookmarksClick={goToBookmarks}
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
        onViewResources={goToResources}
      />
    );
  } else if (view === 'bookmarks') {
    content = (
      <BookmarksPage
        onBack={goToHome}
        onInfoClick={goToAbout}
        onHelpClick={goToFaq}
        onCoursesClick={() => goToCourses()}
        onAccountClick={goToAccount}
        onCourseClick={goToCourseDetail}
      />
    );
  } else {
    content = (
      <Homepage
        onAccountClick={goToAccount}
        onInfoClick={goToAbout}
        onHelpClick={goToFaq}
        onCoursesClick={() => goToCourses()}
        onBookmarksClick={goToBookmarks}
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
      {/* Only non-home views are lazy chunks; a null fallback avoids a
          flash of loading UI for what's typically a near-instant fetch
          on a warm connection. */}
      <Suspense fallback={null}>{content}</Suspense>
      {showFooter && <Footer />}
      <ScrollToTopButton />
    </>
  );
}

export default App;
