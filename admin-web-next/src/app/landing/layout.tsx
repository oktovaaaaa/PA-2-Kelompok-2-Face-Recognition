import type { Metadata } from 'next'
import type { ChildrenType } from '@core/types'
import Providers from '@components/Providers'

export const metadata: Metadata = {
  title: 'VIDENTI - Modern Attendance System',
  description: 'Smart and Secure Attendance Management System for modern businesses.'
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
