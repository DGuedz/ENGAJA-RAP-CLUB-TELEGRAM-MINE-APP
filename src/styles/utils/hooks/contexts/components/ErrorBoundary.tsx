```typescript
import React, { Component, ErrorInfo, ReactNode } from 'react'
import { useTelegramContext } from '../contexts/TelegramContext'

interface ErrorBoundaryState {
  hasError: boolean
  error: Error | null
  errorInfo: ErrorInfo | null
}

interface ErrorBoundaryProps {
  children: ReactNode
  fallback?: ReactNode
  onError?: (error: Error, errorInfo: ErrorInfo) => void
}

class ErrorBoundaryClass extends Component<ErrorBoundaryProps, ErrorBoundaryState> {
  constructor(props: ErrorBoundaryProps) {
    super(props)
    
    this.state = {
      hasError: false,
      error: null,
      errorInfo: null
    }
  }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    // Update state so the next render will show the fallback UI
    return {
      hasError: true,
      error,
      errorInfo: null
    }
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    // Update state with error details
    this.setState({
      error,
      errorInfo
    })

    // Call custom error handler if provided
    this.props.onError?.(error, errorInfo)

    // Log error to console in development
    if (process.env.NODE_ENV === 'development') {
      console.error('ErrorBoundary caught an error:', error, errorInfo)
    }

    // In production, you would send this to your error reporting service
    // Example: Sentry, LogRocket, etc.
    this.logErrorToService(error, errorInfo)
  }

  private logErrorToService = (error: Error, errorInfo: ErrorInfo) => {
    try {
      // Get user info from Telegram if available
      const telegramUser = (window as any).Telegram?.WebApp?.initDataUnsafe?.user

      const errorReport = {
        message: error.message,
        stack: error.stack,
        componentStack: errorInfo.componentStack,
        timestamp: new Date().toISOString(),
        userAgent: navigator.userAgent,
        url: window.location.href,
        userId: telegramUser?.id || 'anonymous',
        username: telegramUser?.username || 'unknown',
        version: '1.0.0', // Replace with actual app version
        environment: process.env.NODE_ENV || 'unknown'
      }

      // Log to localStorage for debugging
      const existingLogs = JSON.parse(localStorage.getItem('engaja-error-logs') || '[]')
      existingLogs.push(errorReport)
      
      // Keep only last 10 error logs
      if (existingLogs.length > 10) {
        existingLogs.splice(0, existingLogs.length - 10)
      }
      
      localStorage.setItem('engaja-error-logs', JSON.stringify(existingLogs))

      // In a real app, send this to your backend/error tracking service
      console.error('Error logged:', errorReport)
      
      // Example: Send to backend
      // fetch('/api/errors', {
      //   method: 'POST',
      //   headers: { 'Content-Type': 'application/json' },
      //   body: JSON.stringify(errorReport)
      // }).catch(console.error)
      
    } catch (loggingError) {
      console.error('Failed to log error:', loggingError)
    }
  }

  private handleRetry = () => {
    this.setState({
      hasError: false,
      error: null,
      errorInfo: null
    })
  }

  private handleReload = () => {
    window.location.reload()
  }

  private handleReportBug = () => {
    const { error, errorInfo } = this.state
    
    if (!error) return

    const bugReport = `
🐛 **Bug Report - Engaja Rap Club**

**Error:** ${error.message}

**Stack Trace:**
\`\`\`
${error.stack}
\`\`\`

**Component Stack:**
\`\`\`
${errorInfo?.componentStack}
\`\`\`

**Browser:** ${navigator.userAgent}
**URL:** ${window.location.href}
**Timestamp:** ${new Date().toISOString()}
**User ID:** ${(window as any).Telegram?.WebApp?.initDataUnsafe?.user?.id || 'N/A'}
    `.trim()

    // Copy to clipboard
    navigator.clipboard?.writeText(bugReport).then(() => {
      alert('Bug report copied to clipboard! Please paste it in our support channel.')
    }).catch(() => {
      // Fallback: show the bug report in an alert
      alert(`Please copy this bug report and send it to our support:\n\n${bugReport}`)
    })
  }

  render() {
    if (this.state.hasError) {
      // Custom fallback UI
      if (this.props.fallback) {
        return this.props.fallback
      }

      // Default error UI
      return (
        <div className="min-h-screen bg-gray-900 text-white flex items-center justify-center p-4">
          <div className="max-w-md w-full bg-gray-800 rounded-xl p-6 shadow-2xl border border-gray-700">
            {/* Error Icon */}
            <div className="flex justify-center mb-6">
              <div className="w-16 h-16 bg-red-500/20 rounded-full flex items-center justify-center">
                <svg 
                  className="w-8 h-8 text-red-500" 
                  fill="none" 
                  stroke="currentColor" 
                  viewBox="0 0 24 24"
                >
                  <path 
                    strokeLinecap="round" 
                    strokeLinejoin="round" 
                    strokeWidth={2} 
                    d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" 
                  />
                </svg>
              </div>
            </div>

            {/* Error Title */}
            <h1 className="text-xl font-bold text-center mb-4 text-gradient-primary">
              🎵 Oops! Something went wrong
            </h1>

            {/* Error Message */}
            <p className="text-gray-300 text-center mb-6">
              Don't worry, the beat goes on! We've encountered a small hiccup in the Engaja Rap Club.
            </p>

            {/* Error Details (Development Only) */}
            {process.env.NODE_ENV === 'development' && this.state.error && (
              <div className="mb-6 p-3 bg-gray-900 rounded-lg border border-gray-600">
                <details>
                  <summary className="text-sm text-gray-400 cursor-pointer hover:text-gray-300 mb-2">
                    🔍 Error Details (Dev Mode)
                  </summary>
                  <div className="text-xs text-red-400 font-mono break-words">
                    <div className="mb-2">
                      <strong>Error:</strong> {this.state.error.message}
                    </div>
                    {this.state.error.stack && (
                      <div className="mb-2">
                        <strong>Stack:</strong>
                        <pre className="mt-1 whitespace-pre-wrap text-xs">
                          {this.state.error.stack}
                        </pre>
                      </div>
                    )}
                    {this.state.errorInfo?.componentStack && (
                      <div>
                        <strong>Component Stack:</strong>
                        <pre className="mt-1 whitespace-pre-wrap text-xs">
                          {this.state.errorInfo.componentStack}
                        </pre>
                      </div>
                    )}
                  </div>
                </details>
              </div>
            )}

            {/* Action Buttons */}
            <div className="space-y-3">
              <button
                onClick={this.handleRetry}
                className="w-full btn-primary text-center py-3 px-4 rounded-lg font-medium transition-all duration-200 hover:scale-105 active:scale-95"
              >
                🔄 Try Again
              </button>
              
              <button
                onClick={this.handleReload}
                className="w-full btn-secondary text-center py-3 px-4 rounded-lg font-medium transition-all duration-200 hover:scale-105 active:scale-95"
              >
                🔃 Reload App
              </button>
              
              <button
                onClick={this.handleReportBug}
                className="w-full btn-ghost text-center py-3 px-4 rounded-lg font-medium transition-all duration-200 hover:scale-105 active:scale-95"
              >
                🐛 Report Bug
              </button>
            </div>

            {/* Support Info */}
            <div className="mt-6 text-center">
              <p className="text-xs text-gray-500">
                Need help? Join our{' '}
                <a 
                  href="https://t.me/engajarapclub" 
                  className="text-primary-400 hover:text-primary-300 transition-colors"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  Telegram Support
                </a>
              </p>
            </div>
          </div>
        </div>
      )
    }

    return this.props.children
  }
}

// Functional wrapper component with hooks
interface ErrorBoundaryWrapperProps extends Omit<ErrorBoundaryProps, 'onError'> {
  onError?: (error: Error, errorInfo: ErrorInfo) => void
}

const ErrorBoundary: React.FC<ErrorBoundaryWrapperProps> = ({ 
  children, 
  fallback, 
  onError: customOnError 
}) => {
  // We can't use hooks directly in the class component, so we create a wrapper
  const handleError = (error: Error, errorInfo: ErrorInfo) => {
    // Try to access Telegram context for haptic feedback
    try {
      const webApp = (window as any).Telegram?.WebApp
      if (webApp?.HapticFeedback) {
        webApp.HapticFeedback.notificationOccurred('error')
      }
    } catch (e) {
      // Ignore if Telegram WebApp is not available
    }

    // Call custom error handler
    customOnError?.(error, errorInfo)
  }

  return (
    <ErrorBoundaryClass onError={handleError} fallback={fallback}>
      {children}
    </ErrorBoundaryClass>
  )
}

export default ErrorBoundary

// Hook for accessing error logs (useful for debugging)
export const useErrorLogs = () => {
  const [errorLogs, setErrorLogs] = React.useState<any[]>([])

  React.useEffect(() => {
    try {
      const logs = JSON.parse(localStorage.getItem('engaja-error-logs') || '[]')
      setErrorLogs(logs)
    } catch (error) {
      console.error('Failed to load error logs:', error)
    }
  }, [])

  const clearErrorLogs = () => {
    localStorage.removeItem('engaja-error-logs')
    setErrorLogs([])
  }

  return {
    errorLogs,
    clearErrorLogs,
    hasErrors: errorLogs.length > 0
  }
}

// Utility function to manually report errors
export const reportError = (error: Error, context?: string) => {
  try {
    const telegramUser = (window as any).Telegram?.WebApp?.initDataUnsafe?.user

    const errorReport = {
      message: error.message,
      stack: error.stack,
      context: context || 'Manual Report',
      timestamp: new Date().toISOString(),
      userAgent: navigator.userAgent,
      url: window.location.href,
      userId: telegramUser?.id || 'anonymous',
      username: telegramUser?.username || 'unknown',
      version: '1.0.0'
    }

    // Log to localStorage
    const existingLogs = JSON.parse(localStorage.getItem('engaja-error-logs') || '[]')
    existingLogs.push(errorReport)
    localStorage.setItem('engaja-error-logs', JSON.stringify(existingLogs))

    console.error('Manual error report:', errorReport)
    
    // Haptic feedback
    const webApp = (window as any).Telegram?.WebApp
    if (webApp?.HapticFeedback) {
      webApp.HapticFeedback.notificationOccurred('error')
    }
  } catch (reportingError) {
    console.error('Failed to report error:', reportingError)
  }
}
```
