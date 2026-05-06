'use client'

import React from 'react'

import Grid from '@mui/material/Grid'
import Typography from '@mui/material/Typography'

import NotificationList from '@views/notifications/NotificationList'

export default function NotificationsPage() {
  return (
    <Grid container spacing={6}>
      <Grid item xs={12} className="flex justify-between items-center">
        <Typography variant="h4" fontWeight="600" color="primary">Notifikasi Saya</Typography>
      </Grid>

      <Grid item xs={12}>
        <NotificationList />
      </Grid>
    </Grid>
  )
}
