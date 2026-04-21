import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';
import App from './App.jsx';

describe('Calculator UI', () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('renders default display', () => {
    render(<App />);
    expect(screen.getByTestId('display').textContent).toBe('0');
  });

  it('builds expression on keypad press', () => {
    render(<App />);
    fireEvent.click(screen.getByText('1'));
    fireEvent.click(screen.getByText('+'));
    fireEvent.click(screen.getByText('2'));
    expect(screen.getByTestId('display').textContent).toBe('1+2');
  });

  it('clears to zero', () => {
    render(<App />);
    fireEvent.click(screen.getByText('9'));
    fireEvent.click(screen.getByText('C'));
    expect(screen.getByTestId('display').textContent).toBe('0');
  });

  it('evaluates expression via backend API', async () => {
    vi.stubGlobal('fetch', vi.fn(() =>
      Promise.resolve({ ok: true, status: 200, json: () => Promise.resolve({ expression: '1+2', result: 3 }) })
    ));
    render(<App />);
    fireEvent.click(screen.getByText('1'));
    fireEvent.click(screen.getByText('+'));
    fireEvent.click(screen.getByText('2'));
    fireEvent.click(screen.getByText('='));
    await waitFor(() => expect(screen.getByTestId('display').textContent).toBe('3'));
    expect(fetch).toHaveBeenCalledWith(
      expect.stringContaining('/evaluate'),
      expect.objectContaining({ method: 'POST' })
    );
  });

  it('shows error when backend rejects', async () => {
    vi.stubGlobal('fetch', vi.fn(() =>
      Promise.resolve({ ok: false, status: 400, json: () => Promise.resolve({}) })
    ));
    render(<App />);
    fireEvent.click(screen.getByText('1'));
    fireEvent.click(screen.getByText('='));
    await waitFor(() => expect(screen.getByRole('alert')).toBeInTheDocument());
  });

  it('solves natural-language problem via AI service', async () => {
    vi.stubGlobal('fetch', vi.fn(() =>
      Promise.resolve({
        ok: true,
        status: 200,
        json: () => Promise.resolve({ question: 'what is 2+2?', expression: '2+2', result: 4, explanation: 'ok' })
      })
    ));
    render(<App />);
    const textarea = screen.getByPlaceholderText(/square root of the total/i);
    fireEvent.change(textarea, { target: { value: 'what is 2+2?' } });
    fireEvent.click(screen.getByText(/Solve with AI/));
    await waitFor(() => expect(screen.getByTestId('nl-result')).toBeInTheDocument());
    expect(screen.getByTestId('nl-result').textContent).toContain('"result": 4');
  });
});
