// MUI Imports
import Chip from '@mui/material/Chip'
import { useTheme } from '@mui/material/styles'

// Third-party Imports
import PerfectScrollbar from 'react-perfect-scrollbar'

// Type Imports
import type { VerticalMenuContextProps } from '@menu/components/vertical-menu/Menu'

// Component Imports
import { Menu, SubMenu, MenuItem, MenuSection } from '@menu/vertical-menu'

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
          Ringkasan Dashboard
        </MenuItem>
        <MenuItem href='/analitik-absensi' icon={<i className='ri-bar-chart-box-line' />}>
          Analitik Absensi
        </MenuItem>

        <MenuSection label='Manajemen SDM'>
          <MenuItem href='/persetujuan' icon={<i className='ri-user-received-line' />}>
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
          <MenuItem href='/pelanggaran' icon={<i className='ri-alarm-warning-line' />}>
            Data Pelanggaran
          </MenuItem>
        </MenuSection>

        <MenuSection label='Aplikasi & Halaman'>
          <MenuItem href='/account-settings' icon={<i className='ri-user-settings-line' />}>
            Pengaturan Akun
          </MenuItem>
          <MenuItem href='/operasional' icon={<i className='ri-settings-4-line' />}>
            Pengaturan Operasional
          </MenuItem>
          <MenuItem href='/template-dashboard' icon={<i className='ri-layout-grid-line' />}>
            Template Dashboard
          </MenuItem>
          <MenuItem href='/card-basic' icon={<i className='ri-bar-chart-box-line' />}>
            Kartu Statistik
          </MenuItem>
        </MenuSection>

        <MenuSection label='Formulir & Tabel'>
          <MenuItem href='/form-layouts' icon={<i className='ri-layout-4-line' />}>
            Layout Formulir
          </MenuItem>
        </MenuSection>

        <MenuSection label='Misc'>
          <MenuItem href='/404' icon={<i className='ri-question-line' />}>
            Halaman 404
          </MenuItem>
        </MenuSection>
      </Menu>
    </ScrollWrapper>
  )
}

export default VerticalMenu
