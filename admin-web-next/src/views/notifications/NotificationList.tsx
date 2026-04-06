'use client'

import React, { useState, useEffect } from 'react'
import Card from '@mui/material/Card'
import CardHeader from '@mui/material/CardHeader'
import CardContent from '@mui/material/CardContent'
import Typography from '@mui/material/Typography'
import Button from '@mui/material/Button'
import Divider from '@mui/material/Divider'
import List from '@mui/material/List'
import ListItem from '@mui/material/ListItem'
import ListItemAvatar from '@mui/material/ListItemAvatar'
import ListItemText from '@mui/material/ListItemText'
import Avatar from '@mui/material/Avatar'
import IconButton from '@mui/material/IconButton'
import Tooltip from '@mui/material/Tooltip'
import CircularProgress from '@mui/material/CircularProgress'
import Box from '@mui/material/Box'

import { formatDistanceToNow } from 'date-fns'
import { id as idLocale } from 'date-fns/locale'
import { useRouter } from 'next/navigation'
import classnames from 'classnames'

import { settingService, Notification } from '@/libs/settingService'

const NotificationList = () => {
  const [notifications, setNotifications] = useState<Notification[]>([])
  const [loading, setLoading] = useState(true)
  const [unreadCount, setUnreadCount] = useState(0)
  const router = useRouter()

  const fetchNotifs = async () => {
    try {
      const data = await settingService.getNotifications()
      setNotifications(data.notifications || [])
      setUnreadCount(data.unread_count || 0)
    } catch (err) {
      console.error(err)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchNotifs()
  }, [])

  const handleMarkAsRead = async (id: string, type: string, refId: string) => {
    try {
      await settingService.markNotificationRead(id)
      fetchNotifs()
      
      // Potential navigation logic
      if (type === 'LEAVE_REQUEST') {
          router.push('/cuti')
      } else if (type === 'PAYROLL_PAID') {
          router.push('/payroll')
      }
    } catch (err) {
      console.error(err)
    }
  }

  const handleMarkAllRead = async () => {
    try {
      await settingService.markAllNotificationsRead()
      fetchNotifs()
    } catch (err) {
       console.error(err)
    }
  }

  const getIcon = (type: string) => {
    switch (type) {
      case 'LEAVE_REQUEST':
        return { icon: 'ri-file-info-line', color: 'warning.main', bg: 'warning.light' }
      case 'LEAVE_APPROVED':
        return { icon: 'ri-checkbox-circle-fill', color: 'success.main', bg: 'success.light' }
      case 'LEAVE_REJECTED':
        return { icon: 'ri-close-circle-fill', color: 'error.main', bg: 'error.light' }
      case 'PAYROLL_PAID':
        return { icon: 'ri-money-dollar-box-line', color: 'primary.main', bg: 'primary.light' }
      case 'EMPLOYEE_REGISTERED':
        return { icon: 'ri-user-add-line', color: 'info.main', bg: 'info.light' }
      case 'POSITION_UPDATE':
        return { icon: 'ri-briefcase-line', color: 'secondary.main', bg: 'secondary.light' }
      default:
        return { icon: 'ri-notification-3-line', color: 'info.main', bg: 'info.light' }
    }
  }

  if (loading) {
    return (
      <Card className="flex items-center justify-center p-12">
        <CircularProgress size={40} />
      </Card>
    )
  }

  return (
    <Card>
      <CardHeader 
        title="Daftar Notifikasi" 
        subtitle={`${unreadCount} pesan belum dibaca`}
        action={
          unreadCount > 0 && (
            <Button variant="outlined" size="small" onClick={handleMarkAllRead}>
              Tandai Semua Dibaca
            </Button>
          )
        }
      />
      <Divider />
      <CardContent className="p-0">
        {notifications.length === 0 ? (
          <Box className="flex flex-col items-center justify-center p-12 opacity-50 gap-4">
             <i className="ri-notification-off-fill text-6xl" />
             <Typography>Tidak ada notifikasi untuk ditampilkan.</Typography>
          </Box>
        ) : (
          <List className="p-0">
            {notifications.map((notif, index) => {
              const { icon, color, bg } = getIcon(notif.type)
              return (
                <React.Fragment key={notif.id}>
                  <ListItem 
                    className={classnames('hover:bg-actionHover p-6 cursor-pointer border-b transition-all', {
                      'bg-primary-light/5': !notif.is_read
                    })}
                    onClick={() => handleMarkAsRead(notif.id, notif.type, notif.ref_id)}
                    secondaryAction={
                      !notif.is_read && (
                        <Box sx={{ width: 10, h: 10, bgcolor: 'primary.main', borderRadius: '50%' }} />
                      )
                    }
                  >
                    <ListItemAvatar>
                      <Avatar sx={{ bgcolor: bg, color: color }}>
                        <i className={icon} />
                      </Avatar>
                    </ListItemAvatar>
                    <ListItemText 
                      primary={
                        <Box className="flex flex-col gap-0.5">
                           <Typography variant="h6" className={notif.is_read ? '' : 'font-bold'}>
                             {notif.title}
                           </Typography>
                           <Typography variant="body2" color="text.secondary" className="line-clamp-2">
                             {notif.body}
                           </Typography>
                        </Box>
                      }
                      secondary={
                        <Typography variant="caption" color="text.disabled" className="flex items-center gap-1 mt-2 font-semibold uppercase tracking-wider">
                           <i className="ri-time-line text-xs" />
                           {formatDistanceToNow(new Date(notif.created_at), { addSuffix: true, locale: idLocale })}
                        </Typography>
                      }
                    />
                  </ListItem>
                </React.Fragment>
              )
            })}
          </List>
        )}
      </CardContent>
    </Card>
  )
}

export default NotificationList
