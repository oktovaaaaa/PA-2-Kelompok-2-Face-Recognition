// Next Imports
import Link from 'next/link'

// MUI Imports
import IconButton from '@mui/material/IconButton'

// Third-party Imports
import classnames from 'classnames'

// Component Imports
import NavToggle from './NavToggle'
import NavSearch from '@components/layout/shared/search'
import ModeDropdown from '@components/layout/shared/ModeDropdown'
import UserDropdown from '@components/layout/shared/UserDropdown'
import NotificationDropdown from '@components/layout/shared/NotificationDropdown'

// Util Imports
import { verticalLayoutClasses } from '@layouts/utils/layoutClasses'

const NavbarContent = () => {
  return (
    <div className={classnames(verticalLayoutClasses.navbarContent, 'flex items-center justify-between gap-4 is-full')}>
      <div className='flex items-center gap-2 sm:gap-4'>
        <NavToggle />
        <NavSearch />
        <Link 
          href='/landing' 
          className='ml-4 px-4 py-1.5 rounded-full bg-primary/10 text-primary hover:bg-primary/20 transition-colors text-sm font-medium hidden md:block'
          style={{ textDecoration: 'none' }}
        >
          Landing Page
        </Link>
      </div>
      <div className='flex items-center'>
        <ModeDropdown />
        <NotificationDropdown />
        <UserDropdown />
      </div>
    </div>
  )
}

export default NavbarContent
