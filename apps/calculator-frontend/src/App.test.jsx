import { render, screen, fireEvent } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import App from './App.jsx';

describe('Calculator UI', () => {
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
});
