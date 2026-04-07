import type { Metadata } from 'next'
import type { ChildrenType } from '@core/types'
import Providers from '@components/Providers'

export const metadata: Metadata = {
  title: 'Beranda',
  description: 'Smart and Secure Attendance Management System for modern businesses.',
  icons: {
    icon: '/images/videnti.png',
    apple: '/images/videnti.png'
  }
}

const LandingLayout = ({ children }: ChildrenType) => {
  return (
    <Providers direction='ltr'>
      <div className='landing-layout'>
        {children}
      </div>
    </Providers>
  )
}

export default LandingLayout
