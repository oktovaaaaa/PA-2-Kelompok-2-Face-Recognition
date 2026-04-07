// src/components/ComingSoon.tsx
import Grid from '@mui/material/Grid'
import Card from '@mui/material/Card'
import CardHeader from '@mui/material/CardHeader'
import CardContent from '@mui/material/CardContent'
import Typography from '@mui/material/Typography'

const ComingSoon = ({ title }: { title: string }) => {
  return (
    <Grid container spacing={6}>
      <Grid item xs={12}>
        <Card>
          <CardHeader title={title} />
          <CardContent>
            <Typography variant='body1'>
              Halaman ini sedang dalam pengembangan untuk menggantikan template bawaan. 
              Data akan segera dihubungkan dengan sistem VIDENTI Anda.
            </Typography>
            <div className='flex items-center justify-center p-12'>
              <i className='ri-tools-line text-6xl text-primary opacity-20' />
            </div>
          </CardContent>
        </Card>
      </Grid>
    </Grid>
  )
}

export default ComingSoon
