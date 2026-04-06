'use client'

// React Imports
import { useRef, useState, useEffect } from 'react'
import type { MouseEvent } from 'react'

// Next Imports
import { useRouter } from 'next/navigation'

// MUI Imports
import { styled } from '@mui/material/styles'
import Badge from '@mui/material/Badge'
import IconButton from '@mui/material/IconButton'
import Popper from '@mui/material/Popper'
import Fade from '@mui/material/Fade'
import Paper from '@mui/material/Paper'
import ClickAwayListener from '@mui/material/ClickAwayListener'
import MenuList from '@mui/material/MenuList'
import Typography from '@mui/material/Typography'
import Divider from '@mui/material/Divider'
import MenuItem from '@mui/material/MenuItem'
import Button from '@mui/material/Button'
import Avatar from '@mui/material/Avatar'

// Third-party Imports
import classnames from 'classnames'
import { formatDistanceToNow } from 'date-fns'
import { id } from 'date-fns/locale'

// Lib Imports
import { settingService, Notification } from '@/libs/settingService'

// Styled component for badge content
const BadgeContentSpan = styled('span')({
  width: 8,
  height: 8,
  borderRadius: '50%',
  cursor: 'pointer',
  backgroundColor: 'var(--mui-palette-error-main)',
  boxShadow: '0 0 0 2px var(--mui-palette-background-paper)'
})

const NotificationDropdown = () => {
  // States
  const [open, setOpen] = useState(false)
  const [notifications, setNotifications] = useState<Notification[]>([])
  const [unreadCount, setUnreadCount] = useState(0)

  // Refs
  const anchorRef = useRef<HTMLButtonElement>(null)

  // Hooks
  const router = useRouter()

  const fetchNotifications = async () => {
    try {
      const data = await settingService.getNotifications()
      setNotifications(data.notifications || [])
      setUnreadCount(data.unread_count || 0)
    } catch (error) {
      console.error('Error fetching notifications:', error)
    }
  }

  useEffect(() => {
    fetchNotifications()
    // Polling every 30 seconds
    const interval = setInterval(fetchNotifications, 30000)
    return () => clearInterval(interval)
  }, [])

  const handleDropdownOpen = () => {
    !open ? setOpen(true) : setOpen(false)
    if (!open) fetchNotifications()
  }

  const handleDropdownClose = (event?: MouseEvent<HTMLLIElement> | (MouseEvent | TouchEvent)) => {
    if (anchorRef.current && anchorRef.current.contains(event?.target as HTMLElement)) {
      return
    }
    setOpen(false)
  }

  const handleMarkAsRead = async (id: string, refId: string, type: string) => {
    try {
      await settingService.markNotificationRead(id)
      fetchNotifications()
      
      // Navigation based on type
      if (type === 'LEAVE_REQUEST') {
        router.push('/cuti')
      } else if (type === 'PAYROLL_PAID') {
        router.push('/payroll')
      } else if (type === 'EMPLOYEE_REGISTERED') {
        router.push('/karyawan') // Admin can approve/reject here
      }
      
      setOpen(false)
    } catch (error) {
      console.error('Error marking as read:', error)
    }
  }

  const handleMarkAllRead = async () => {
    try {
      await settingService.markAllNotificationsRead()
      fetchNotifications()
    } catch (error) {
      console.error('Error marking all as read:', error)
    }
  }

  const getNotifIcon = (type: string) => {
    switch (type) {
      case 'LEAVE_REQUEST':
        return { icon: 'ri-information-line', color: 'warning.main', bg: 'warning.light' }
      case 'LEAVE_APPROVED':
        return { icon: 'ri-checkbox-circle-line', color: 'success.main', bg: 'success.light' }
      case 'LEAVE_REJECTED':
        return { icon: 'ri-close-circle-line', color: 'error.main', bg: 'error.light' }
      case 'PAYROLL_PAID':
        return { icon: 'ri-money-dollar-circle-line', color: 'primary.main', bg: 'primary.light' }
      case 'EMPLOYEE_REGISTERED':
        return { icon: 'ri-user-add-line', color: 'info.main', bg: 'info.light' }
      case 'POSITION_UPDATE':
        return { icon: 'ri-briefcase-line', color: 'secondary.main', bg: 'secondary.light' }
      default:
        return { icon: 'ri-notification-2-line', color: 'secondary.main', bg: 'secondary.light' }
    }
  }

  return (
    <>
      <IconButton ref={anchorRef} onClick={handleDropdownOpen} className='text-textPrimary'>
        <Badge
          overlap='circular'
          badgeContent={unreadCount > 0 ? <BadgeContentSpan /> : null}
          anchorOrigin={{ vertical: 'top', horizontal: 'right' }}
        >
          <i className='ri-notification-2-line' />
        </Badge>
      </IconButton>
      <Popper
        open={open}
        transition
        disablePortal
        placement='bottom-end'
        anchorEl={anchorRef.current}
        className='min-is-[380px] !mbs-4 z-[1]'
      >
        {({ TransitionProps, placement }) => (
          <Fade
            {...TransitionProps}
            style={{
              transformOrigin: placement === 'bottom-end' ? 'right top' : 'left top'
            }}
          >
            <Paper className='shadow-lg border'>
              <ClickAwayListener onClickAway={e => handleDropdownClose(e as MouseEvent | TouchEvent)}>
                <div className='flex flex-col'>
                  <div className='flex items-center justify-between plb-3 pli-4'>
                    <Typography variant='h6' className='font-semibold'>Notifikasi</Typography>
                    {unreadCount > 0 && (
                      <Button size='small' onClick={handleMarkAllRead}>Tandai semua dibaca</Button>
                    )}
                  </div>
                  <Divider />
                  <MenuList className='max-bs-[400px] overflow-y-auto'>
                    {notifications.length === 0 ? (
                      <div className='flex flex-col items-center justify-center p-8 gap-2 opacity-50'>
                        <i className='ri-notification-off-line text-4xl' />
                        <Typography variant='body2'>Belum ada notifikasi</Typography>
                      </div>
                    ) : (
                      notifications.map((notif) => {
                        const { icon, color, bg } = getNotifIcon(notif.type)
                        return (
                          <MenuItem 
                            key={notif.id} 
                            onClick={() => handleMarkAsRead(notif.id, notif.ref_id, notif.type)}
                            className={classnames('gap-4 p-4 items-start', { 'bg-actionHover': !notif.is_read })}
                          >
                            <Avatar color={color as any} sx={{ bgcolor: bg, color: color }} variant='rounded'>
                               <i className={icon} />
                            </Avatar>
                            <div className='flex flex-col flex-1 gap-1'>
                              <div className='flex justify-between items-center'>
                                <Typography variant='subtitle2' className={classnames('font-medium', { 'font-bold': !notif.is_read })}>
                                  {notif.title}
                                </Typography>
                                {!notif.is_read && <div className='w-2 h-2 bg-primary rounded-full' />}
                              </div>
                              <Typography variant='body2' color='text.secondary' className='line-clamp-2 text-xs'>
                                {notif.body}
                              </Typography>
                              <Typography variant='caption' color='text.disabled' className='mt-1'>
                                {formatDistanceToNow(new Date(notif.created_at), { addSuffix: true, locale: id })}
                              </Typography>
                            </div>
                          </MenuItem>
                        )
                      })
                    )}
                  </MenuList>
                  <Divider />
                  <div className='p-2'>
                    <Button fullWidth onClick={() => { setOpen(false); router.push('/notifications') }}>
                      Lihat Semua Notifikasi
                    </Button>
                  </div>
                </div>
              </ClickAwayListener>
            </Paper>
          </Fade>
        )}
      </Popper>
    </>
  )
}

export default NotificationDropdown
