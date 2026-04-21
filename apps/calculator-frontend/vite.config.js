import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: { host: '0.0.0.0', port: 8080 },
  preview: { host: '0.0.0.0', port: 8080 },
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./src/setupTests.js'],
    coverage: { provider: 'v8', reporter: ['text', 'lcov'], thresholds: { lines: 80, functions: 80, branches: 70 } }
  }
});
