// React Imports
import { useState, useEffect } from 'react'

// MUI Imports
import Grid from '@mui/material/Grid'

// Component Imports
import AccountDetails from './AccountDetails'
import AccountDelete from './AccountDelete'

const Account = () => {
  const [role, setRole] = useState<string | null>(null)

  useEffect(() => {
    setRole(localStorage.getItem('role'))
  }, [])

  return (
    <Grid container spacing={6}>
      <Grid item xs={12}>
        <AccountDetails />
      </Grid>
      
      {/* Tombol hapus akun disembunyikan khusus untuk Super Admin */}
      {role !== 'SUPER_ADMIN' && (
        <Grid item xs={12}>
          <AccountDelete />
        </Grid>
      )}
    </Grid>
  )
}

export default Account
