'use client'

// React Imports
import { useState, useEffect } from 'react'
import type { SyntheticEvent, ReactElement } from 'react'

// Next Imports
import { useRouter, useSearchParams } from 'next/navigation'

// MUI Imports
import Grid from '@mui/material/Grid'
import Tab from '@mui/material/Tab'
import Box from '@mui/material/Box'
import Typography from '@mui/material/Typography'
import TabContext from '@mui/lab/TabContext'
import TabList from '@mui/lab/TabList'
import TabPanel from '@mui/lab/TabPanel'

const AccountSettings = ({ tabContentList }: { tabContentList: { [key: string]: ReactElement } }) => {
  // Hooks
  const router = useRouter()
  const searchParams = useSearchParams()
  
  // States
  const [activeTab, setActiveTab] = useState(searchParams.get('tab') || 'account')
  const [role, setRole] = useState<string | null>(null)

  useEffect(() => {
    const savedRole = localStorage.getItem('role')
    setRole(savedRole)
  }, [])

  // Sync state with URL when searchParams change
  useEffect(() => {
    const currentTab = searchParams.get('tab')
    if (currentTab && currentTab !== activeTab) {
      setActiveTab(currentTab)
    }
  }, [searchParams, activeTab])

  const handleChange = (event: SyntheticEvent, value: string) => {
    setActiveTab(value)
    router.push(`/account-settings?tab=${value}`)
  }

  return (
    <Box>
      {/* Page Header */}
      <Box sx={{ mb: 6 }}>
        <Typography variant='h4' fontWeight='800' color='primary' className='tracking-tight' gutterBottom>
          Pengaturan Akun
        </Typography>
        <Typography variant='body2' color='text.secondary' className='font-medium'>
          Kelola informasi profil, keamanan kata sandi, dan prevensi akun Anda dalam satu panel kendali.
        </Typography>
      </Box>

      <TabContext value={activeTab}>
        <Grid container spacing={6}>
          <Grid item xs={12}>
            <TabList 
              onChange={handleChange} 
              variant='scrollable'
              sx={{
                borderBottom: (theme) => `1px solid ${theme.palette.divider}`,
                '& .MuiTabs-indicator': { height: 3, borderRadius: '3px 3px 0 0' }
              }}
            >
              <Tab 
                label='Informasi Profil' 
                icon={<i className='ri-user-settings-line text-lg' />} 
                iconPosition='start' 
                value='account' 
                className='font-bold min-h-[60px]'
              />
              <Tab
                label='Keamanan'
                icon={<i className='ri-shield-keyhole-line text-lg' />}
                iconPosition='start'
                value='security'
                className='font-bold min-h-[60px]'
              />
              {role !== 'SUPER_ADMIN' && (
                <Tab 
                  label='Detail Instansi' 
                  icon={<i className='ri-building-line text-lg' />} 
                  iconPosition='start' 
                  value='company' 
                  className='font-bold min-h-[60px]'
                />
              )}
            </TabList>
          </Grid>
          <Grid item xs={12}>
            <TabPanel value={activeTab} className='p-0 animate-fade-in'>
              {tabContentList[activeTab]}
            </TabPanel>
          </Grid>
        </Grid>
      </TabContext>
    </Box>
  )
}

export default AccountSettings
