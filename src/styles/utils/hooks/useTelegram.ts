```typescript
import { useEffect, useState } from 'react'

declare global {
  interface Window {
    Telegram?: {
      WebApp: {
        ready: () => void
        expand: () => void
        close: () => void
        MainButton: {
          text: string
          color: string
          textColor: string
          isVisible: boolean
          isProgressVisible: boolean
          isActive: boolean
          setText: (text: string) => void
          onClick: (callback: () => void) => void
          offClick: (callback: () => void) => void
          show: () => void
          hide: () => void
          enable: () => void
          disable: () => void
          showProgress: (leaveActive?: boolean) => void
          hideProgress: () => void
        }
        BackButton: {
          isVisible: boolean
          onClick: (callback: () => void) => void
          offClick: (callback: () => void) => void
          show: () => void
          hide: () => void
        }
        HapticFeedback: {
          impactOccurred: (style: 'light' | 'medium' | 'heavy' | 'rigid' | 'soft') => void
          notificationOccurred: (type: 'error' | 'success' | 'warning') => void
          selectionChanged: () => void
        }
        setHeaderColor: (color: string) => void
        setBackgroundColor: (color: string) => void
        enableClosingConfirmation: () => void
        disableClosingConfirmation: () => void
        initData: string
        initDataUnsafe: {
          query_id?: string
          user?: {
            id: number
            is_bot: boolean
            first_name: string
            last_name?: string
            username?: string
            language_code?: string
            is_premium?: boolean
            allows_write_to_pm?: boolean
            photo_url?: string
          }
          auth_date: number
          hash: string
          start_param?: string
          chat_type?: string
          chat_instance?: string
        }
        version: string
        platform: string
        colorScheme: 'light' | 'dark'
        themeParams: {
          link_color?: string
          button_color?: string
          button_text_color?: string
          secondary_bg_color?: string
          hint_color?: string
          bg_color?: string
          text_color?: string
        }
        isExpanded: boolean
        viewportHeight: number
        viewportStableHeight: number
        isClosingConfirmationEnabled: boolean
        headerColor: string
        backgroundColor: string
        isVersionAtLeast: (version: string) => boolean
        sendData: (data: string) => void
        switchInlineQuery: (query: string, choose_chat_types?: string[]) => void
        openLink: (url: string, options?: { try_instant_view?: boolean }) => void
        openTelegramLink: (url: string) => void
        openInvoice: (url: string, callback?: (status: string) => void) => void
        showPopup: (params: {
          title?: string
          message: string
          buttons?: Array<{
            id?: string
            type?: 'default' | 'ok' | 'close' | 'cancel' | 'destructive'
            text: string
          }>
        }, callback?: (buttonId: string) => void) => void
        showAlert: (message: string, callback?: () => void) => void
        showConfirm: (message: string, callback?: (confirmed: boolean) => void) => void
        showScanQrPopup: (params: {
          text?: string
        }, callback?: (text: string) => boolean) => void
        closeScanQrPopup: () => void
        readTextFromClipboard: (callback?: (text: string) => void) => void
        requestWriteAccess: (callback?: (granted: boolean) => void) => void
        requestContact: (callback?: (granted: boolean) => void) => void
        isVersionAtLeast: (version: string) => boolean
      }
    }
  }
}

interface TelegramUser {
  id: number
  is_bot: boolean
  first_name: string
  last_name?: string
  username?: string
  language_code?: string
  is_premium?: boolean
  allows_write_to_pm?: boolean
  photo_url?: string
}

interface UseTelegramReturn {
  webApp: typeof window.Telegram?.WebApp | null
  user: TelegramUser | null
  initDataUnsafe: typeof window.Telegram?.WebApp.initDataUnsafe | null
  isReady: boolean
  colorScheme: 'light' | 'dark'
  themeParams: typeof window.Telegram?.WebApp.themeParams | null
  showMainButton: (text: string, callback: () => void) => void
  hideMainButton: () => void
  showBackButton: (callback: () => void) => void
  hideBackButton: () => void
  hapticFeedback: {
    impact: (style?: 'light' | 'medium' | 'heavy') => void
    notification: (type: 'error' | 'success' | 'warning') => void
    selection: () => void
  }
  showAlert: (message: string) => Promise<void>
  showConfirm: (message: string) => Promise<boolean>
  sendData: (data: any) => void
  openLink: (url: string) => void
  requestWriteAccess: () => Promise<boolean>
  close: () => void
}

export const useTelegram = (): UseTelegramReturn => {
  const [isReady, setIsReady] = useState(false)
  const [webApp, setWebApp] = useState<typeof window.Telegram?.WebApp | null>(null)

  useEffect(() => {
    // Check if we're in Telegram WebApp environment
    if (typeof window !== 'undefined' && window.Telegram?.WebApp) {
      const tg = window.Telegram.WebApp
      setWebApp(tg)
      
      // Initialize Telegram WebApp
      tg.ready()
      tg.expand()
      
      // Set theme colors for Engaja Rap Club
      tg.setHeaderColor('#111827') // Dark theme
      tg.setBackgroundColor('#111827')
      
      setIsReady(true)
    } else {
      // Development mode - create mock WebApp
      console.warn('Telegram WebApp not available - running in development mode')
      setIsReady(true)
    }
  }, [])

  const showMainButton = (text: string, callback: () => void) => {
    if (webApp?.MainButton) {
      webApp.MainButton.setText(text)
      webApp.MainButton.onClick(callback)
      webApp.MainButton.show()
      webApp.MainButton.enable()
    }
  }

  const hideMainButton = () => {
    webApp?.MainButton.hide()
  }

  const showBackButton = (callback: () => void) => {
    if (webApp?.BackButton) {
      webApp.BackButton.onClick(callback)
      webApp.BackButton.show()
    }
  }

  const hideBackButton = () => {
    webApp?.BackButton.hide()
  }

  const hapticFeedback = {
    impact: (style: 'light' | 'medium' | 'heavy' = 'light') => {
      webApp?.HapticFeedback.impactOccurred(style)
    },
    notification: (type: 'error' | 'success' | 'warning') => {
      webApp?.HapticFeedback.notificationOccurred(type)
    },
    selection: () => {
      webApp?.HapticFeedback.selectionChanged()
    }
  }

  const showAlert = (message: string): Promise<void> => {
    return new Promise((resolve) => {
      if (webApp?.showAlert) {
        webApp.showAlert(message, () => resolve())
      } else {
        alert(message)
        resolve()
      }
    })
  }

  const showConfirm = (message: string): Promise<boolean> => {
    return new Promise((resolve) => {
      if (webApp?.showConfirm) {
        webApp.showConfirm(message, (confirmed) => resolve(confirmed))
      } else {
        resolve(confirm(message))
      }
    })
  }

  const sendData = (data: any) => {
    if (webApp?.sendData) {
      webApp.sendData(JSON.stringify(data))
    }
  }

  const openLink = (url: string) => {
    if (webApp?.openLink) {
      webApp.openLink(url)
    } else {
      window.open(url, '_blank')
    }
  }

  const requestWriteAccess = (): Promise<boolean> => {
    return new Promise((resolve) => {
      if (webApp?.requestWriteAccess) {
        webApp.requestWriteAccess((granted) => resolve(granted))
      } else {
        resolve(false)
      }
    })
  }

  const close = () => {
    webApp?.close()
  }

  return {
    webApp,
    user: webApp?.initDataUnsafe?.user || null,
    initDataUnsafe: webApp?.initDataUnsafe || null,
    isReady,
    colorScheme: webApp?.colorScheme || 'dark',
    themeParams: webApp?.themeParams || null,
    showMainButton,
    hideMainButton,
    showBackButton,
    hideBackButton,
    hapticFeedback,
    showAlert,
    showConfirm,
    sendData,
    openLink,
    requestWriteAccess,
    close
  }
}
```
