```typescript
import React from 'react'
import ReactDOM from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { TonConnectUIProvider } from '@tonconnect/ui-react'
import { Toaster } from 'sonner'

import App from './App'
import './styles/globals.css'
import { ErrorBoundary } from './components/ErrorBoundary'
import { TelegramProvider } from './contexts/TelegramContext'

// Create Query Client
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 3,
      staleTime: 1000 * 60 * 5, // 5 minutes
      cacheTime: 1000 * 60 * 10, // 10 minutes
    },
  },
})

// TON Connect Manifest URL
const manifestUrl = new URL('/tonconnect-manifest.json', window.location.href).toString()

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <ErrorBoundary>
      <BrowserRouter>
        <QueryClientProvider client={queryClient}>
          <TonConnectUIProvider manifestUrl={manifestUrl}>
            <TelegramProvider>
              <App />
              <Toaster 
                position="top-center"
                theme="dark"
                richColors
                closeButton
                duration={4000}
              />
            </TelegramProvider>
          </TonConnectUIProvider>
        </QueryClientProvider>
      </BrowserRouter>
    </ErrorBoundary>
  </React.StrictMode>
)
```
