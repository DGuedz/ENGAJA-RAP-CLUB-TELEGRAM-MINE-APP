```typescript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { resolve } from 'path'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [
    react({
      // Enable React Fast Refresh
      fastRefresh: true,
    })
  ],
  
  // Path resolution
  resolve: {
    alias: {
      '@': resolve(__dirname, './src'),
      '@/components': resolve(__dirname, './src/components'),
      '@/hooks': resolve(__dirname, './src/hooks'),
      '@/utils': resolve(__dirname, './src/utils'),
      '@/types': resolve(__dirname, './src/types'),
      '@/styles': resolve(__dirname, './src/styles'),
      '@/assets': resolve(__dirname, './src/assets'),
    },
  },

  // Development server
  server: {
    host: true,
    port: 3000,
    strictPort: true,
    hmr: {
      port: 3001,
    },
  },

  // Build configuration
  build: {
    outDir: 'dist',
    sourcemap: true,
    minify: 'terser',
    target: 'esnext',
    rollupOptions: {
      output: {
        manualChunks: {
          'react-vendor': ['react', 'react-dom'],
          'ton-vendor': ['@tonconnect/ui-react', '@twa-dev/sdk'],
          'ui-vendor': ['framer-motion', 'lucide-react'],
        },
      },
    },
  },

  // Environment variables
  define: {
    global: 'globalThis',
  },

  // Optimize dependencies
  optimizeDeps: {
    include: [
      'react',
      'react-dom',
      '@tonconnect/ui-react',
      '@twa-dev/sdk',
      'framer-motion',
      'zustand',
      'react-router-dom',
      'axios',
      'lucide-react',
    ],
  },

  // Preview server (for production builds)
  preview: {
    port: 3000,
    host: true,
  },
})
```
