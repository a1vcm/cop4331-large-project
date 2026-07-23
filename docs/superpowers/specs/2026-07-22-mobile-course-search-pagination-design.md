# Mobile course search: true pagination

## Problem

`mobile/lib/screens/course_search_screen.dart` mirrors web's `CourseSearchPage.jsx`
cumulative-reveal behavior: tapping "Next" grows a `_visibleCount` and appends more
results to the bottom of one long scrolling list. On mobile this reads as an
ever-growing vertical list rather than pagination.

## Scope

Mobile only. `frontend/src/pages/CourseSearchPage.jsx` is unchanged and keeps its
current cumulative-reveal "Next" behavior — the two are intentionally diverging.

## Design

**State**

- Replace `int _visibleCount` with `int _currentPage` (0-indexed).
- Every call site that currently calls `_resetVisibleCount(...)` (search submit,
  filter/prefix/sort change, page-size change) instead resets `_currentPage = 0`.

**Slicing (`_displayedCourses` getter)**

- `pageSize == -1` ("All"): return the full `_visibleCourses` list, unchanged.
- Otherwise: `visible.skip(page * pageSize).take(pageSize)`.
- Clamp: if `_currentPage` falls outside `[0, totalPages - 1]` after a filter/sort
  change shrinks the result set, clamp it back into range inside the getter (no
  setState needed — the getter self-corrects on read).

**UI**

- Remove the single centered `_NextButton` ("Next" text pill).
- Add a centered Prev/Next row: two icon-only `OutlinedButton`s
  (`Icons.chevron_left` / `Icons.chevron_right`), same visual style (gold/blue
  outline, rounded, 44px min tap target) as the button they replace.
  - Prev disabled (onPressed: null) on page 0.
  - Next disabled on the last page.
  - Whole row omitted when `totalPages <= 1`.
- Between the two buttons: `Page X of Y` text label.
- Results-count line above the list drops the `— showing N` suffix (redundant
  once the page label is present); keeps `N results`.

## Out of scope

- Web (`CourseSearchPage.jsx`) behavior change.
- Any backend/API change — pagination is purely client-side slicing of the
  already-fetched `_courses` list, same as today.
