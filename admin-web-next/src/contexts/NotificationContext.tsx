// src/contexts/NotificationContext.tsx
'use client'

import type { ReactNode } from 'react';
import React, { createContext, useContext, useState } from 'react'

import Snackbar from '@mui/material/Snackbar'
import type { AlertColor } from '@mui/material/Alert';
import Alert from '@mui/material/Alert'

interface NotificationContextType {
  showNotification: (message: string, severity?: AlertColor) => void
}

const NotificationContext = createContext<NotificationContextType | undefined>(undefined)

export const useNotification = () => {
  const context = useContext(NotificationContext)

  if (!context) {
    throw new Error('useNotification must be used within a NotificationProvider')
  }

  
return context
}

export const NotificationProvider = ({ children }: { children: ReactNode }) => {
  const [open, setOpen] = useState(false)
  const [message, setMessage] = useState('')
  const [severity, setSeverity] = useState<AlertColor>('success')

  const showNotification = (msg: string, sev: AlertColor = 'success') => {
    setMessage(msg)
    setSeverity(sev)
    setOpen(true)
  }

  const handleClose = (event?: React.SyntheticEvent | Event, reason?: string) => {
    if (reason === 'clickaway') {
      return
    }

    setOpen(false)
  }

  return (
    <NotificationContext.Provider value={{ showNotification }}>
      {children}
      <Snackbar 
        open={open} 
        autoHideDuration={4000} 
        onClose={handleClose}
        anchorOrigin={{ vertical: 'top', horizontal: 'right' }}
      >
        <Alert 
          onClose={handleClose} 
          severity={severity} 
          variant="filled" 
          sx={{ width: '100%', boxShadow: 'var(--mui-customShadows-md)' }}
          iconMapping={{
            success: <i className="ri-checkbox-circle-line" />,
            error: <i className="ri-error-warning-line" />,
            warning: <i className="ri-alert-line" />,
            info: <i className="ri-information-line" />
          }}
        >
          {message}
        </Alert>
      </Snackbar>
    </NotificationContext.Provider>
  )
}
