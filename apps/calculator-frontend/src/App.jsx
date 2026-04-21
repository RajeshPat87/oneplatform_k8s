import { useState } from 'react';

const BACKEND = import.meta.env.VITE_BACKEND_URL || '/api/backend';
const AI = import.meta.env.VITE_AI_URL || '/api/ai';

async function postJSON(url, body) {
  const r = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
  });
  if (!r.ok) throw new Error(`HTTP ${r.status}`);
  return r.json();
}

export default function App() {
  const [display, setDisplay] = useState('0');
  const [nl, setNl] = useState('');
  const [nlResult, setNlResult] = useState(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  const press = (t) => setDisplay((d) => (d === '0' ? t : d + t));
  const clear = () => setDisplay('0');

  const evaluate = async () => {
    setError('');
    setBusy(true);
    try {
      const res = await postJSON(`${BACKEND}/evaluate`, { expression: display });
      setDisplay(String(res.result));
    } catch (e) {
      setError(e.message);
    } finally {
      setBusy(false);
    }
  };

  const solveNL = async () => {
    setError('');
    setBusy(true);
    try {
      const res = await postJSON(`${AI}/solve`, { question: nl });
      setNlResult(res);
    } catch (e) {
      setError(e.message);
    } finally {
      setBusy(false);
    }
  };

  const keys = ['7', '8', '9', '/', '4', '5', '6', '*', '1', '2', '3', '-', '0', '.', '+', '('];

  return (
    <main style={{ fontFamily: 'system-ui', maxWidth: 520, margin: '40px auto', padding: 16 }}>
      <h1>OnePlatform Calculator</h1>
      <section aria-label="standard-calculator">
        <div data-testid="display" style={{ padding: 12, background: '#111', color: '#0f0', fontSize: 28, textAlign: 'right', borderRadius: 8 }}>
          {display}
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: 8, marginTop: 12 }}>
          {keys.map((k) => (
            <button key={k} onClick={() => press(k)}>{k}</button>
          ))}
          <button onClick={() => press(')')}>)</button>
          <button onClick={clear}>C</button>
          <button onClick={evaluate} disabled={busy}>=</button>
        </div>
      </section>
      <section aria-label="natural-language" style={{ marginTop: 24 }}>
        <h2>Natural Language Math</h2>
        <textarea
          value={nl}
          onChange={(e) => setNl(e.target.value)}
          placeholder="If I have 5 apples and buy 3 more, what is the square root of the total?"
          rows={3}
          style={{ width: '100%' }}
        />
        <button onClick={solveNL} disabled={busy || !nl.trim()}>Solve with AI</button>
        {nlResult && (
          <pre data-testid="nl-result" style={{ background: '#f4f4f4', padding: 12, marginTop: 12 }}>
{JSON.stringify(nlResult, null, 2)}
          </pre>
        )}
      </section>
      {error && <p role="alert" style={{ color: 'crimson' }}>{error}</p>}
    </main>
  );
}
