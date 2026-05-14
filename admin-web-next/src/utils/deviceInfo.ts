export const getBrowserInfo = () => {
  const ua = navigator.userAgent
  let browser = 'Unknown Browser'
  let os = 'Unknown OS'

  // Browser detection
  if (ua.includes('Firefox')) browser = 'Firefox'
  else if (ua.includes('SamsungBrowser')) browser = 'Samsung Browser'
  else if (ua.includes('Opera') || ua.includes('OPR')) browser = 'Opera'
  else if (ua.includes('Trident')) browser = 'Internet Explorer'
  else if (ua.includes('Edge')) browser = 'Edge'
  else if (ua.includes('Chrome')) browser = 'Chrome'
  else if (ua.includes('Safari')) browser = 'Safari'

  // OS detection
  if (ua.includes('Win')) os = 'Windows'
  else if (ua.includes('Mac')) os = 'macOS'
  else if (ua.includes('X11')) os = 'UNIX'
  else if (ua.includes('Linux')) os = 'Linux'
  else if (ua.includes('Android')) os = 'Android'
  else if (ua.includes('iPhone')) os = 'iOS'

  return `${browser} (${os})`
}
