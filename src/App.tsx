```typescript
import React, { useEffect } from 'react'
import { Routes, Route, Navigate } from 'react-router-dom'
import { AnimatePresence } from 'framer-motion'
import { Helmet } from 'react-helmet-async'

// Layout Components
import { Header } from './components/layout/Header'
import { Footer } from './components/layout/Footer'
import { Sidebar } from './components/layout/Sidebar'

// Page Components
import { HomePage } from './pages/HomePage'
import { ExplorePage } from './pages/ExplorePage'
import { ArtistPage } from './pages/ArtistPage'
import { ProfilePage } from './pages/ProfilePage'
import { StakingPage } from './pages/StakingPage'
import { MarketplacePage } from './pages/MarketplacePage'
import { NotFoundPage } from './pages/NotFoundPage'

// Hooks
import { useTelegram } from './hooks/useTelegram'
import { useTh
```
