```typescript
import React, { createContext, useContext, useEffect, useState, ReactNode } from 'react'
import { useTelegram } from '../hooks/useTelegram'

interface TelegramContextValue {
  // Telegram WebApp instance
  webApp: typeof window.Telegram?.WebApp | null
  
  // User data
  user: {
    id: number
    is_bot: boolean
    first_name: string
    last_name?: string
    username?: string
    language_code?: string
    is_premium?: boolean
    allows_write_to_pm?: boolean
    photo_url?: string
  } | null
  
  // App state
  isReady: boolean
  colorScheme: 'light' | 'dark'
  themeParams: typeof window.Telegram?.WebApp.themeParams | null
  
  // Navigation methods
  showMainButton: (text: string, callback: () => void) => void
  hideMainButton: () => void
  showBackButton: (callback: () => void) => void
  hideBackButton: () => void
  
  // Feedback methods
  hapticFeedback: {
    impact: (style?: 'light' | 'medium' | 'heavy') => void
    notification: (type: 'error' | 'success' | 'warning') => void
    selection: () => void
  }
  
  // UI methods
  showAlert: (message: string) => Promise<void>
  showConfirm: (message: string) => Promise<boolean>
  
  // Data methods
  sendData: (data: any) => void
  
  // External methods
  openLink: (url: string) => void
  requestWriteAccess: () => Promise<boolean>
  close: () => void
  
  // App-specific state
  bstrBalance: number
  setBstrBalance: (balance: number) => void
  userLevel: number
  setUserLevel: (level: number) => void
  unreadNotifications: number
  setUnreadNotifications: (count: number) => void
}

const TelegramContext = createContext<TelegramContextValue | null>(null)

interface TelegramProviderProps {
  children: ReactNode
}

export const TelegramProvider: React.FC<TelegramProviderProps> = ({ children }) => {
  const telegramHook = useTelegram()
  
  // App-specific state
  const [bstrBalance, setBstrBalance] = useState<number>(0)
  const [userLevel, setUserLevel] = useState<number>(1)
  const [unreadNotifications, setUnreadNotifications] = useState<number>(0)

  // Initialize app data when user is available
  useEffect(() => {
    if (telegramHook.user && telegramHook.isReady) {
      // Load user data from backend/localStorage
      loadUserData()
      
      // Setup periodic data refresh
      const interval = setInterval(loadUserData, 30000) // Every 30 seconds
      
      return () => clearInterval(interval)
    }
  }, [telegramHook.user, telegramHook.isReady])

  const loadUserData = async () => {
    try {
      // In a real app, this would fetch from your backend
      const savedBalance = localStorage.getItem('engaja-bstr-balance')
      const savedLevel = localStorage.getItem('engaja-user-level')
      const savedNotifications = localStorage.getItem('engaja-notifications')
      
      if (savedBalance) setBstrBalance(parseFloat(savedBalance))
      if (savedLevel) setUserLevel(parseInt(savedLevel))
      if (savedNotifications) setUnreadNotifications(parseInt(savedNotifications))
      
      // Mock API call for demo purposes
      if (telegramHook.user) {
        // Simulate loading user balance from blockchain
        const mockBalance = Math.floor(Math.random() * 1000) + 500
        setBstrBalance(mockBalance)
        localStorage.setItem('engaja-bstr-balance', mockBalance.toString())
        
        // Simulate user level based on activity
        const mockLevel = Math.floor(mockBalance / 100) + 1
        setUserLevel(mockLevel)
        localStorage.setItem('engaja-user-level', mockLevel.toString())
      }
    } catch (error) {
      console.error('Failed to load user data:', error)
    }
  }

  // Enhanced BSTR balance setter with localStorage persistence
  const handleSetBstrBalance = (balance: number) => {
    setBstrBalance(balance)
    localStorage.setItem('engaja-bstr-balance', balance.toString())
    
    // Update user level based on balance
    const newLevel = Math.floor(balance / 100) + 1
    if (newLevel !== userLevel) {
      setUserLevel(newLevel)
      localStorage.setItem('engaja-user-level', newLevel.toString())
      
      // Show level up notification
      if (newLevel > userLevel) {
        telegramHook.hapticFeedback.notification('success')
        telegramHook.showAlert(`🎉 Parabéns! Você subiu para o nível ${newLevel}!`)
      }
    }
  }

  // Enhanced user level setter
  const handleSetUserLevel = (level: number) => {
    const oldLevel = userLevel
    setUserLevel(level)
    localStorage.setItem('engaja-user-level', level.toString())
    
    // Haptic feedback for level changes
    if (level > oldLevel) {
      telegramHook.hapticFeedback.notification('success')
    }
  }

  // Enhanced notifications setter
  const handleSetUnreadNotifications = (count: number) => {
    setUnreadNotifications(count)
    localStorage.setItem('engaja-notifications', count.toString())
    
    // Update Telegram badge (if supported)
    if (telegramHook.webApp && count > 0) {
      // Note: This is a conceptual implementation
      // Actual badge updating depends on Telegram WebApp API updates
      try {
        document.title = count > 0 ? `(${count}) Engaja Rap Club` : 'Engaja Rap Club'
      } catch (error) {
        console.warn('Failed to update notification badge:', error)
      }
    }
  }

  // Enhanced haptic feedback with app-specific patterns
  const enhancedHapticFeedback = {
    impact: (style: 'light' | 'medium' | 'heavy' = 'light') => {
      telegramHook.hapticFeedback.impact(style)
    },
    notification: (type: 'error' | 'success' | 'warning') => {
      telegramHook.hapticFeedback.notification(type)
    },
    selection: () => {
      telegramHook.hapticFeedback.selection()
    },
    // App-specific patterns
    earnedBSTR: () => {
      telegramHook.hapticFeedback.notification('success')
      setTimeout(() => telegramHook.hapticFeedback.impact('light'), 100)
    },
    levelUp: () => {
      telegramHook.hapticFeedback.notification('success')
      setTimeout(() => telegramHook.hapticFeedback.impact('medium'), 100)
      setTimeout(() => telegramHook.hapticFeedback.impact('light'), 200)
    },
    musicLiked: () => {
      telegramHook.hapticFeedback.impact('light')
    },
    campaignCompleted: () => {
      telegramHook.hapticFeedback.notification('success')
      setTimeout(() => telegramHook.hapticFeedback.impact('heavy'), 100)
    }
  }

  const contextValue: TelegramContextValue = {
    // Telegram WebApp data
    webApp: telegramHook.webApp,
    user: telegramHook.user,
    isReady: telegramHook.isReady,
    colorScheme: telegramHook.colorScheme,
    themeParams: telegramHook.themeParams,
    
    // Navigation methods
    showMainButton: telegramHook.showMainButton,
    hideMainButton: telegramHook.hideMainButton,
    showBackButton: telegramHook.showBackButton,
    hideBackButton: telegramHook.hideBackButton,
    
    // Enhanced feedback methods
    hapticFeedback: enhancedHapticFeedback,
    
    // UI methods
    showAlert: telegramHook.showAlert,
    showConfirm: telegramHook.showConfirm,
    
    // Data methods
    sendData: telegramHook.sendData,
    
    // External methods
    openLink: telegramHook.openLink,
    requestWriteAccess: telegramHook.requestWriteAccess,
    close: telegramHook.close,
    
    // App-specific state
    bstrBalance,
    setBstrBalance: handleSetBstrBalance,
    userLevel,
    setUserLevel: handleSetUserLevel,
    unreadNotifications,
    setUnreadNotifications: handleSetUnreadNotifications
  }

  return (
    <TelegramContext.Provider value={contextValue}>
      {children}
    </TelegramContext.Provider>
  )
}

// Custom hook to use Telegram context
export const useTelegramContext = (): TelegramContextValue => {
  const context = useContext(TelegramContext)
  
  if (!context) {
    throw new Error('useTelegramContext must be used within a TelegramProvider')
  }
  
  return context
}

// Utility hook for BSTR operations
export const useBSTR = () => {
  const { bstrBalance, setBstrBalance, hapticFeedback, showAlert, user } = useTelegramContext()
  
  const earnBSTR = (amount: number, source: string) => {
    const newBalance = bstrBalance + amount
    setBstrBalance(newBalance)
    hapticFeedback.notification('success')
    
    // Show earning notification
    showAlert(`🎵 +${amount} BSTR earned from ${source}!`)
    
    // Log earning for analytics (in real app, send to backend)
    console.log('BSTR Earned:', {
      userId: user?.id,
      amount,
      source,
      newBalance,
      timestamp: new Date().toISOString()
    })
  }
  
  const spendBSTR = (amount: number, purpose: string): boolean => {
    if (bstrBalance >= amount) {
      const newBalance = bstrBalance - amount
      setBstrBalance(newBalance)
      hapticFeedback.impact('medium')
      
      // Log spending for analytics
      console.log('BSTR Spent:', {
        userId: user?.id,
        amount,
        purpose,
        newBalance,
        timestamp: new Date().toISOString()
      })
      
      return true
    } else {
      hapticFeedback.notification('error')
      showAlert(`❌ Insufficient BSTR balance. You need ${amount} BSTR but only have ${bstrBalance}.`)
      return false
    }
  }
  
  return {
    balance: bstrBalance,
    earnBSTR,
    spendBSTR,
    canAfford: (amount: number) => bstrBalance >= amount
  }
}

// Utility hook for user level operations
export const useUserLevel = () => {
  const { userLevel, setUserLevel, bstrBalance, hapticFeedback, showAlert } = useTelegramContext()
  
  const getLevelProgress = () => {
    const currentLevelThreshold = userLevel * 100
    const nextLevelThreshold = (userLevel + 1) * 100
    const progress = ((bstrBalance - currentLevelThreshold) / (nextLevelThreshold - currentLevelThreshold)) * 100
    
    return Math.max(0, Math.min(100, progress))
  }
  
  const getLevelPerks = (level: number) => {
    const perks = []
    
    if (level >= 2) perks.push('🎵 Premium music access')
    if (level >= 3) perks.push('💰 2x BSTR multiplier')
    if (level >= 5) perks.push('🎤 Artist collaboration opportunities')
    if (level >= 10) perks.push('👑 VIP community access')
    if (level >= 20) perks.push('🚀 Early feature access')
    
    return perks
  }
  
  return {
    level: userLevel,
    progress: getLevelProgress(),
    perks: getLevelPerks(userLevel),
    nextLevelPerks: getLevelPerks(userLevel + 1),
    tokensToNextLevel: Math.max(0, (userLevel + 1) * 100 - bstrBalance)
  }
}

export default TelegramContext
```
