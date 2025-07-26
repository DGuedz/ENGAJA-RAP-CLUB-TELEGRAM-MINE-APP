```typescript
import { useEffect, useState } from 'react'
import { useTelegram } from './useTelegram'

export type Theme = 'light' | 'dark' | 'auto'

interface UseThemeReturn {
  theme: Theme
  isDark: boolean
  isLight: boolean
  setTheme: (theme: Theme) => void
  toggleTheme: () => void
  systemTheme: 'light' | 'dark'
}

const THEME_STORAGE_KEY = 'engaja-theme-preference'

export const useTheme = (): UseThemeReturn => {
  const { webApp, colorScheme } = useTelegram()
  const [theme, setThemeState] = useState<Theme>('auto')
  const [systemTheme, setSystemTheme] = useState<'light' | 'dark'>('dark')

  // Get system theme preference
  useEffect(() => {
    const getSystemTheme = (): 'light' | 'dark' => {
      // Priority 1: Telegram WebApp color scheme
      if (colorScheme) {
        return colorScheme
      }

      // Priority 2: System preference
      if (typeof window !== 'undefined' && window.matchMedia) {
        return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
      }

      // Priority 3: Default to dark (Engaja Rap Club brand)
      return 'dark'
    }

    const currentSystemTheme = getSystemTheme()
    setSystemTheme(currentSystemTheme)

    // Listen for system theme changes
    if (typeof window !== 'undefined' && window.matchMedia) {
      const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)')
      
      const handleChange = (e: MediaQueryListEvent) => {
        const newSystemTheme = e.matches ? 'dark' : 'light'
        setSystemTheme(newSystemTheme)
        
        // Update Telegram WebApp theme if available
        if (webApp) {
          const headerColor = newSystemTheme === 'dark' ? '#111827' : '#ffffff'
          const backgroundColor = newSystemTheme === 'dark' ? '#111827' : '#ffffff'
          
          webApp.setHeaderColor(headerColor)
          webApp.setBackgroundColor(backgroundColor)
        }
      }

      if (mediaQuery.addEventListener) {
        mediaQuery.addEventListener('change', handleChange)
        return () => mediaQuery.removeEventListener('change', handleChange)
      } else {
        // Fallback for older browsers
        mediaQuery.addListener(handleChange)
        return () => mediaQuery.removeListener(handleChange)
      }
    }
  }, [colorScheme, webApp])

  // Load saved theme preference
  useEffect(() => {
    try {
      const savedTheme = localStorage.getItem(THEME_STORAGE_KEY) as Theme
      if (savedTheme && ['light', 'dark', 'auto'].includes(savedTheme)) {
        setThemeState(savedTheme)
      }
    } catch (error) {
      console.warn('Failed to load theme preference:', error)
    }
  }, [])

  // Resolve actual theme (light/dark) based on preference
  const resolvedTheme = theme === 'auto' ? systemTheme : theme
  const isDark = resolvedTheme === 'dark'
  const isLight = resolvedTheme === 'light'

  // Apply theme to document
  useEffect(() => {
    try {
      const root = document.documentElement
      
      // Remove existing theme classes
      root.classList.remove('light', 'dark')
      
      // Add new theme class
      root.classList.add(resolvedTheme)
      
      // Set CSS custom properties for theme
      if (isDark) {
        root.style.setProperty('--bg-primary', '#111827')
        root.style.setProperty('--bg-secondary', '#1f2937')
        root.style.setProperty('--text-primary', '#f9fafb')
        root.style.setProperty('--text-secondary', '#d1d5db')
        root.style.setProperty('--border-color', '#374151')
      } else {
        root.style.setProperty('--bg-primary', '#ffffff')
        root.style.setProperty('--bg-secondary', '#f9fafb')
        root.style.setProperty('--text-primary', '#111827')
        root.style.setProperty('--text-secondary', '#6b7280')
        root.style.setProperty('--border-color', '#e5e7eb')
      }

      // Update meta theme-color for mobile browsers
      const metaThemeColor = document.querySelector('meta[name="theme-color"]')
      if (metaThemeColor) {
        metaThemeColor.setAttribute('content', isDark ? '#111827' : '#ffffff')
      }

      // Update Telegram WebApp theme if available
      if (webApp) {
        const headerColor = isDark ? '#111827' : '#ffffff'
        const backgroundColor = isDark ? '#111827' : '#ffffff'
        
        webApp.setHeaderColor(headerColor)
        webApp.setBackgroundColor(backgroundColor)
      }
    } catch (error) {
      console.warn('Failed to apply theme:', error)
    }
  }, [resolvedTheme, isDark, webApp])

  const setTheme = (newTheme: Theme) => {
    try {
      setThemeState(newTheme)
      localStorage.setItem(THEME_STORAGE_KEY, newTheme)
      
      // Haptic feedback for theme change
      if (webApp?.HapticFeedback) {
        webApp.HapticFeedback.selectionChanged()
      }
    } catch (error) {
      console.warn('Failed to save theme preference:', error)
      setThemeState(newTheme) // Still update state even if storage fails
    }
  }

  const toggleTheme = () => {
    const newTheme = isDark ? 'light' : 'dark'
    setTheme(newTheme)
  }

  return {
    theme,
    isDark,
    isLight,
    setTheme,
    toggleTheme,
    systemTheme
  }
}

// Utility function to get theme-aware colors
export const getThemeColors = (isDark: boolean) => ({
  background: {
    primary: isDark ? '#111827' : '#ffffff',
    secondary: isDark ? '#1f2937' : '#f9fafb',
    tertiary: isDark ? '#374151' : '#f3f4f6'
  },
  text: {
    primary: isDark ? '#f9fafb' : '#111827',
    secondary: isDark ? '#d1d5db' : '#6b7280',
    tertiary: isDark ? '#9ca3af' : '#9ca3af'
  },
  border: {
    primary: isDark ? '#374151' : '#e5e7eb',
    secondary: isDark ? '#4b5563' : '#d1d5db'
  },
  accent: {
    primary: '#ef4444', // Engaja Rap Club red
    secondary: '#c651f5', // Engaja Rap Club purple
    ton: '#0098ea' // TON Network blue
  }
})

// Hook to get theme-aware CSS variables
export const useThemeColors = () => {
  const { isDark } = useTheme()
  return getThemeColors(isDark)
}

// Utility to create theme-aware class names
export const themeClass = (lightClass: string, darkClass: string, isDark: boolean) => {
  return isDark ? darkClass : lightClass
}
```
