// React Imports
import { useState, useEffect } from 'react'

// MUI Imports
import Chip from '@mui/material/Chip'
import { useTheme } from '@mui/material/styles'

// Third-party Imports
import PerfectScrollbar from 'react-perfect-scrollbar'

// Type Imports
import type { VerticalMenuContextProps } from '@menu/components/vertical-menu/Menu'

// Component Imports
import { Menu, SubMenu, MenuItem, MenuSection } from '@menu/vertical-menu'

// Service Imports
import { employeeService } from '@/libs/employeeService'

// Hook Imports
import useVerticalNav from '@menu/hooks/useVerticalNav'

// Styled Component Imports
import StyledVerticalNavExpandIcon from '@menu/styles/vertical/StyledVerticalNavExpandIcon'

// Style Imports
import menuItemStyles from '@core/styles/vertical/menuItemStyles'
import menuSectionStyles from '@core/styles/vertical/menuSectionStyles'

type RenderExpandIconProps = {
  open?: boolean
  transitionDuration?: VerticalMenuContextProps['transitionDuration']
}

const RenderExpandIcon = ({ open, transitionDuration }: RenderExpandIconProps) => (
  <StyledVerticalNavExpandIcon open={open} transitionDuration={transitionDuration}>
    <i className='ri-arrow-right-s-line' />
  </StyledVerticalNavExpandIcon>
)

const VerticalMenu = ({ scrollMenu }: { scrollMenu: (container: any, isPerfectScrollbar: boolean) => void }) => {
  // Hooks
  const theme = useTheme()
  const { isBreakpointReached, transitionDuration } = useVerticalNav()

  const ScrollWrapper = isBreakpointReached ? 'div' : PerfectScrollbar

  const [role, setRole] = useState<string | null>(null)
  const [pendingCount, setPendingCount] = useState<number>(0)

  useEffect(() => {
    setRole(localStorage.getItem('role'))

    const fetchPendingCount = async () => {
      try {
        const data = await employeeService.getPendingEmployees()
        setPendingCount(data.length)
      } catch (error) {
        console.error('Error fetching pending count:', error)
      }
    }

    fetchPendingCount()
    
    // Refresh count every 30 seconds for real-time feel
    const interval = setInterval(fetchPendingCount, 30000)
    
    return () => clearInterval(interval)
  }, [])

  const isSuperAdmin = role === 'SUPER_ADMIN'

  return (
    // eslint-disable-next-line lines-around-comment
    /* Custom scrollbar instead of browser scroll, remove if you want browser scroll only */
    <ScrollWrapper
      {...(isBreakpointReached
        ? {
            className: 'bs-full overflow-y-auto overflow-x-hidden',
            onScroll: container => scrollMenu(container, false)
          }
        : {
            options: { wheelPropagation: false, suppressScrollX: true },
            onScrollY: container => scrollMenu(container, true)
          })}
    >
      {/* Incase you also want to scroll NavHeader to scroll with Vertical Menu, remove NavHeader from above and paste it below this comment */}
      {/* Vertical Menu */}
      <Menu
        menuItemStyles={menuItemStyles(theme)}
        renderExpandIcon={({ open }) => <RenderExpandIcon open={open} transitionDuration={transitionDuration} />}
        renderExpandedMenuItemIcon={{ icon: <i className='ri-circle-line' /> }}
        menuSectionStyles={menuSectionStyles(theme)}
      >

        {/* Dashboard Section */}
        <MenuItem href='/dashboard' icon={<i className='ri-home-smile-line' />}>
          Beranda
        </MenuItem>

        {!isSuperAdmin ? (
          <>
            <MenuSection label='Manajemen SDM'>
              <MenuItem 
                href='/persetujuan' 
                icon={<i className='ri-user-received-line' />}
                suffix={pendingCount > 0 ? (
                  <Chip 
                    label={pendingCount} 
                    size='small' 
                    color='error' 
                    sx={{ 
                      height: 22, 
                      width: 22, 
                      minWidth: 22, 
                      p: 0, 
                      '& .MuiChip-label': { px: 0 }, 
                      fontSize: '0.75rem', 
                      fontWeight: 'bold',
                      borderRadius: '50%' 
                    }} 
                  />
                ) : null}
              >
                Persetujuan Karyawan
              </MenuItem>
              <MenuItem href='/karyawan' icon={<i className='ri-user-line' />}>
                Data Karyawan
              </MenuItem>
              <MenuItem href='/jabatan' icon={<i className='ri-briefcase-line' />}>
                Manajemen Jabatan
              </MenuItem>
              <MenuItem href='/cuti' icon={<i className='ri-calendar-event-line' />}>
                Cuti & Izin
              </MenuItem>
              <MenuItem href='/libur' icon={<i className='ri-calendar-todo-line' />}>
                Hari Libur
              </MenuItem>
            </MenuSection>

            <MenuSection label='Laporan & Payroll'>
              <MenuItem href='/absensi' icon={<i className='ri-file-list-3-line' />}>
                Laporan Absensi
              </MenuItem>
              <MenuItem href='/payroll' icon={<i className='ri-money-dollar-circle-line' />}>
                Laporan Payroll
              </MenuItem>
              <MenuItem href='/pelanggaran-bonus' icon={<i className='ri-medal-line' />}>
                Bonus & Sanksi
              </MenuItem>
            </MenuSection>

            <MenuSection label='Aplikasi & Halaman'>
              <MenuItem href='/account-settings' icon={<i className='ri-user-settings-line' />}>
                Pengaturan Akun
              </MenuItem>
              <MenuItem href='/operasional' icon={<i className='ri-settings-4-line' />}>
                Pengaturan Operasional
              </MenuItem>
            </MenuSection>
          </>
        ) : (
          <MenuSection label='Manajemen Sistem'>
             <MenuItem href='/pengguna' icon={<i className='ri-community-line' />}>
               Daftar Seluruh Pengguna
             </MenuItem>
             <MenuItem href='/testimoni' icon={<i className='ri-chat-smile-3-line' />}>
               Kelola Testimoni
             </MenuItem>
          </MenuSection>
        )}
      </Menu>
    </ScrollWrapper>
  )
}

export default VerticalMenu
