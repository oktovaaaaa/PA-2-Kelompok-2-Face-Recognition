import { Outfit } from 'next/font/google'

// Type Imports
import type { ChildrenType } from '@core/types'

// Style Imports
import '@/app/globals.css'

// Generated Icon CSS Imports
import '@assets/iconify-icons/generated-icons.css'

// Component Imports
import Providers from '@components/Providers'

const outfit = Outfit({ subsets: ['latin'], weight: ['300', '400', '500', '600', '700', '800', '900'] })

export const metadata = {
  title: {
    template: 'VIDENTI - %s',
    default: 'VIDENTI'
  },
  description: 'Smart Attendance Management System',
  icons: {
    icon: '/images/videnti.png',
    apple: '/images/videnti.png'
  }
}

const RootLayout = ({ children }: ChildrenType) => {
  // Vars
  const direction = 'ltr'

  return (
    <html id='__next' dir={direction}>
      <head>
        <link rel='icon' href='/images/videnti.png?v=2' />
        <link rel='icon' type='image/png' sizes='32x32' href='/images/videnti.png?v=2' />
        <link rel='apple-touch-icon' href='/images/videnti.png' />
        <link href='https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css' rel='stylesheet' />
      </head>
      <body className={`${outfit.className} flex is-full min-bs-full flex-auto flex-col`}>
        <Providers direction={direction}>{children}</Providers>
      </body>
    </html>
  )
}

export default RootLayout
