import { describe, it, expect, vi } from 'vitest';
import { render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import WriteReviewPage from './WriteReviewPage.jsx';

vi.mock('../api/courses.js', () => ({
  getCourseById: vi.fn().mockResolvedValue({ _id: 'c1', course_code: 'COP4331', title: 'Process of Software Dev' }),
}));

const createReview = vi.fn();
vi.mock('../api/reviews.js', () => ({
  createReview: (...args) => createReview(...args),
  updateReview: vi.fn(),
}));

vi.mock('../api/resources.js', () => ({
  createResource: vi.fn(),
}));

describe('WriteReviewPage', () => {
  it('warns instead of submitting when term and comment are missing', async () => {
    const user = userEvent.setup();
    render(<WriteReviewPage courseId="c1" existing={null} onCancel={() => {}} onSaved={() => {}} />);

    await user.click(await screen.findByRole('button', { name: /submit review/i }));

    expect(await screen.findByText(/please fill out the required fields/i)).toBeInTheDocument();
    expect(screen.getByText(/term is required/i)).toBeInTheDocument();
    expect(screen.getByText(/a review comment is required/i)).toBeInTheDocument();
    expect(createReview).not.toHaveBeenCalled();
  });

  it('submits once the required fields are filled in', async () => {
    const user = userEvent.setup();
    createReview.mockResolvedValueOnce({});
    const onSaved = vi.fn();
    render(<WriteReviewPage courseId="c1" existing={null} onCancel={() => {}} onSaved={onSaved} />);

    // Term select is the first combobox on the page (grade select comes later).
    const [termSelect] = await screen.findAllByRole('combobox');
    const someTerm = within(termSelect)
      .getAllByRole('option')
      .find((opt) => opt.value !== '').value;
    await user.selectOptions(termSelect, someTerm);
    await user.type(screen.getByPlaceholderText(/share your experience/i), 'Great course, learned a lot.');
    await user.click(screen.getByRole('button', { name: /submit review/i }));

    expect(createReview).toHaveBeenCalled();
    expect(screen.queryByText(/please fill out the required fields/i)).not.toBeInTheDocument();
  });
});
