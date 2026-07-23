import { useEffect, useState } from 'react';
import TopBar from './components/TopBar.jsx';
import { getCourseById } from '../api/courses.js';
import { getCourseResources, createResource, deleteResource } from '../api/resources.js';
import { getAuthUser, isLoggedIn, getErrorMessage } from '../api/client.js';
import './ResourcesPage.css';

function ResourcesPage({ courseId, onBack, onBookmarksClick, onAccountClick, onLogoClick }) {
  const [course, setCourse] = useState(null);
  const [resources, setResources] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [title, setTitle] = useState('');
  const [url, setUrl] = useState('');
  const [formError, setFormError] = useState(null);
  const [saving, setSaving] = useState(false);

  const currentUser = getAuthUser();

  const load = async () => {
    setLoading(true);
    setError(null);
    try {
      const [courseData, resourceData] = await Promise.all([
        getCourseById(courseId),
        getCourseResources(courseId),
      ]);
      setCourse(courseData);
      setResources(resourceData);
    } catch (err) {
      setError(getErrorMessage(err, 'Failed to load resources.'));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect -- initial data fetch on mount
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [courseId]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setFormError(null);
    if (!title.trim() || !url.trim()) {
      setFormError('Title and link are required');
      return;
    }
    setSaving(true);
    try {
      await createResource({ courseId, title: title.trim(), url: url.trim() });
      setTitle('');
      setUrl('');
      await load();
    } catch (err) {
      setFormError(getErrorMessage(err));
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (resource) => {
    if (!window.confirm('Remove this resource?')) return;
    try {
      await deleteResource(resource._id);
      setResources((prev) => prev.filter((r) => r._id !== resource._id));
    } catch (err) {
      setFormError(getErrorMessage(err));
    }
  };

  return (
    <div className="resources-page">
      <TopBar
        showBackButton
        onBack={onBack}
        onLogoClick={onLogoClick}
        showCoursesIcon={false}
        onBookmarksClick={onBookmarksClick}
        onAccountClick={onAccountClick}
        fixed
      />
      <div className="resources-top-spacer" />

      <div className="resources-content">
        {loading && <p className="resources-status">Loading…</p>}
        {error && <p className="resources-status">{error}</p>}

        {!loading && !error && (
          <>
            <h1 className="resources-heading">Resources{course ? ` — ${course.course_code}` : ''}</h1>
            <p className="resources-subheading">
              Links other students have found useful for this course — syllabi, video series, practice sites.
            </p>

            {isLoggedIn() ? (
              <form className="resource-form" onSubmit={handleSubmit}>
                <input
                  type="text"
                  placeholder="Title, e.g. Course YouTube playlist"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  maxLength={120}
                />
                <input
                  type="url"
                  placeholder="https://…"
                  value={url}
                  onChange={(e) => setUrl(e.target.value)}
                />
                {formError && <p className="resource-form-error">{formError}</p>}
                <button type="submit" className="resource-form-submit" disabled={saving}>
                  {saving ? 'Adding…' : 'Add Resource'}
                </button>
              </form>
            ) : (
              <p className="resources-status">Log in to add a resource.</p>
            )}

            <div className="resource-list">
              {resources.length === 0 && (
                <p className="resources-status">No resources yet — be the first to add one!</p>
              )}
              {resources.map((resource) => {
                const isMine = currentUser && (resource.userId?._id ?? resource.userId) === currentUser.id;
                return (
                  <div key={resource._id} className="resource-card">
                    <a href={resource.url} target="_blank" rel="noopener noreferrer" className="resource-link">
                      {resource.title}
                    </a>
                    <div className="resource-meta">
                      <span>added by {resource.userId?.username ?? 'a student'}</span>
                      {isMine && (
                        <button type="button" className="resource-delete" onClick={() => handleDelete(resource)}>
                          Delete
                        </button>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          </>
        )}
      </div>
    </div>
  );
}

export default ResourcesPage;
