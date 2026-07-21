import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import App from './App'

describe('App', () => {
  it('renders the homepage', () => {
    render(<App />)
    expect(screen.getByRole('heading', { name: /knightrate/i })).toBeInTheDocument()
    expect(screen.getByPlaceholderText(/search classes/i)).toBeInTheDocument()
  })

  it('navigates to the About page via the Info nav icon', async () => {
    const user = userEvent.setup()
    render(<App />)
    await user.click(screen.getByRole('button', { name: /info/i }))
    expect(screen.getByRole('heading', { name: /meet the team/i })).toBeInTheDocument()
  })

  it('navigates to the FAQ page via the Help nav icon', async () => {
    const user = userEvent.setup()
    render(<App />)
    await user.click(screen.getByRole('button', { name: /help/i }))
    expect(screen.getByRole('heading', { name: /general/i })).toBeInTheDocument()
  })
})
