// src/app/(dashboard)/dashboard/page.tsx
export const metadata = { title: 'Dashboard' }
import Grid from '@mui/material/Grid'

// New Premium Dashboard Component
import MainAdminDashboard from '@views/dashboard/MainAdminDashboard'

const DashboardAnalytics = () => {
  return (
    <Grid container spacing={6}>
      <Grid item xs={12}>
        <MainAdminDashboard />
      </Grid>
    </Grid>
  )
}

export default DashboardAnalytics
