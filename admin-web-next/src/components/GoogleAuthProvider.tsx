'use client'

import { GoogleOAuthProvider } from '@react-oauth/google'
import type { ReactNode } from 'react'

const clientId = '1026596721441-5bdhkp5bnp5ju0oj3plmo38pe9idjtak.apps.googleusercontent.com'

const GoogleAuthProvider = ({ children }: { children: ReactNode }) => {
  return (
    <GoogleOAuthProvider clientId={clientId}>
      {children}
    </GoogleOAuthProvider>
  )
}

export default GoogleAuthProvider
