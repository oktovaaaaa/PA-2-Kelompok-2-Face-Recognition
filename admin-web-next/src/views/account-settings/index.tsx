'use client'

// React Imports
import { useState } from 'react'
import type { SyntheticEvent, ReactElement } from 'react'

// MUI Imports
import Grid from '@mui/material/Grid'
import Tab from '@mui/material/Tab'
import Box from '@mui/material/Box'
import Typography from '@mui/material/Typography'
import TabContext from '@mui/lab/TabContext'
import TabList from '@mui/lab/TabList'
import TabPanel from '@mui/lab/TabPanel'

const AccountSettings = ({ tabContentList }: { tabContentList: { [key: string]: ReactElement } }) => {
  // States
  const [activeTab, setActiveTab] = useState('account')

  const handleChange = (event: SyntheticEvent, value: string) => {
    setActiveTab(value)
  }

  return (
    <Box>
      {/* Page Header */}
      <Box sx={{ mb: 6 }}>
        <Typography variant='h4' fontWeight='800' color='primary' gutterBottom>
          Pengaturan Akun
        </Typography>
        <Typography variant='body2' color='text.secondary'>
          Atur informasi pribadi, kata sandi, dan detail instansi Anda dalam satu tempat.
        </Typography>
      </Box>

      <TabContext value={activeTab}>
      <Grid container spacing={6}>
        <Grid item xs={12}>
          <TabList onChange={handleChange} variant='scrollable'>
            <Tab label='Akun Pribadi' icon={<i className='ri-user-3-line' />} iconPosition='start' value='account' />
            <Tab
              label='Keamanan'
              icon={<i className='ri-lock-line' />}
              iconPosition='start'
              value='security'
            />
            <Tab label='Profil Instansi' icon={<i className='ri-business-center-line' />} iconPosition='start' value='company' />
          </TabList>
        </Grid>
        <Grid item xs={12}>
          <TabPanel value={activeTab} className='p-0'>
            {tabContentList[activeTab]}
          </TabPanel>
        </Grid>
      </Grid>
    </TabContext>
    </Box>
  )
}

export default AccountSettings
