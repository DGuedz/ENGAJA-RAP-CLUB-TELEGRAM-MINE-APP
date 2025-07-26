```javascript
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        // Brand colors
        primary: {
          50: '#fef2f2',
          100: '#fee2e2',
          200: '#fecaca',
          300: '#fca5a5',
          400: '#f87171',
          500: '#ef4444',
          600: '#dc2626',
          700: '#b91c1c',
          800: '#991b1b',
          900: '#7f1d1d',
          950: '#450a0a',
        },
        secondary: {
          50: '#f8fafc',
          100: '#f1f5f9',
          200: '#e2e8f0',
          300: '#cbd5e1',
          400: '#94a3b8',
          500: '#64748b',
          600: '#475569',
          700: '#334155',
          800: '#1e293b',
          900: '#0f172a',
          950: '#020617',
        },
        accent: {
          50: '#fdf4ff',
          100: '#fae8ff',
          200: '#f3d4fe',
          300: '#e9b3fd',
          400: '#d983fa',
          500: '#c651f5',
          600: '#a333e8',
          700: '#8726cc',
          800: '#7021a7',
          900: '#5c1d87',
          950: '#3b0764',
        },
        // Telegram theme colors
        telegram: {
          bg: '#17212b',
          secondary: '#232e3c',
          text: '#ffffff',
          hint: '#708499',
          link: '#5288c1',
          button: '#5288c1',
        },
        // TON Network colors
        ton: {
          blue: '#0098ea',
          darkBlue: '#0077c7',
        },
        // Music platform colors
        beat: {
          red: '#ff1744',
          orange: '#ff6f00',
          yellow: '#ffc107',
          green: '#4caf50',
          purple: '#9c27b0',
        }
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        display: ['Space Grotesk', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'Consolas', 'monospace'],
      },
      animation: {
        'fade-in': 'fadeIn 0.5s ease-in-out',
        'slide-up': 'slideUp 0.3s ease-out',
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'beat': 'beat 1s ease-in-out infinite alternate',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { transform: 'translateY(100%)' },
          '100%': { transform: 'translateY(0)' },
        },
        beat: {
          '0%': { transform: 'scale(1)' },
          '100%': { transform: 'scale(1.05)' },
        },
      },
      boxShadow: {
        'glow': '0 0 20px rgba(196, 81, 245, 0.3)',
        'telegram': '0 2px 10px rgba(0, 0, 0, 0.1)',
      },
    },
  },
  plugins: [],
}
```
