import './Stars.css';

// A single star rendered as a gray outline with a gold fill clipped to
// `fillPercent` (0-100) — gives smooth fractional fill for half-stars and
// for read-only display of averaged ratings (e.g. 4.3/5).
function Star({ fillPercent }) {
  return (
    <span className="star-shape" aria-hidden="true">
      <span className="star-shape-bg">★</span>
      <span className="star-shape-fill" style={{ width: `${fillPercent}%` }}>★</span>
    </span>
  );
}

// Shared star rating component — read-only display (used in ReviewCard,
// course summaries) or interactive picker (used in WriteReviewPage).
// allowHalf enables 0.5-increment clicks; only the class-quality rating
// uses it, per the design decision to keep other scales whole-number.
function Stars({ value = 0, onChange, allowHalf = false, readOnly = false, size = 22 }) {
  const isInteractive = !readOnly && typeof onChange === 'function';

  const handlePick = (n, isHalf) => {
    if (!isInteractive) return;
    onChange(isHalf ? n - 0.5 : n);
  };

  return (
    <div className={`star-picker ${readOnly ? 'read-only' : ''}`} style={{ fontSize: size }}>
      {[1, 2, 3, 4, 5].map((n) => {
        const fillPercent = Math.max(0, Math.min(1, value - (n - 1))) * 100;
        return (
          <span key={n} className="star-wrapper">
            <Star fillPercent={fillPercent} />
            {isInteractive && (
              <>
                {allowHalf && (
                  <button
                    type="button"
                    className="star-hit-half"
                    onClick={() => handlePick(n, true)}
                    aria-label={`${n - 0.5} stars`}
                  />
                )}
                <button
                  type="button"
                  className={`star-hit-full ${allowHalf ? '' : 'full-width'}`}
                  onClick={() => handlePick(n, false)}
                  aria-label={`${n} stars`}
                />
              </>
            )}
          </span>
        );
      })}
    </div>
  );
}

export default Stars;
