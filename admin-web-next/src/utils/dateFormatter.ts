import { format } from 'date-fns'
import { id } from 'date-fns/locale'

/**
 * Formats a date string to Indonesian full date format: Kamis 1 Juni 2026
 * @param dateStr ISO date string or date-like string
 * @returns formatted date string
 */
export const formatFullDate = (dateStr: string | Date): string => {
  if (!dateStr) return '-'

  try {
    const date = typeof dateStr === 'string' ? new Date(dateStr) : dateStr

    if (isNaN(date.getTime())) return String(dateStr)
    
    // format 'EEEE d MMMM yyyy' produces 'Kamis 1 Juni 2026'
    return format(date, 'EEEE d MMMM yyyy', { locale: id })
  } catch (error) {
    return String(dateStr)
  }
}

/**
 * Formats a date string to Indonesian date format: 1 Juni 2026
 */
export const formatDate = (dateStr: string | Date): string => {
  if (!dateStr) return '-'

  try {
    const date = typeof dateStr === 'string' ? new Date(dateStr) : dateStr

    if (isNaN(date.getTime())) return String(dateStr)
    
    return format(date, 'd MMMM yyyy', { locale: id })
  } catch (error) {
    return String(dateStr)
  }
}

/**
 * Detects YYYY-MM-DD patterns in a string and replaces them with full Indonesian format
 * Useful for legacy data or concatenated strings from backend.
 */
export const formatDateInString = (text: string): string => {
  if (!text) return ''
  
  // Regex for YYYY-MM-DD
  const dateRegex = /\b\d{4}-\d{2}-\d{2}\b/g
  
  return text.replace(dateRegex, (match) => {
    try {
      const date = new Date(match)

      if (isNaN(date.getTime())) return match
      
return format(date, 'EEEE d MMMM yyyy', { locale: id })
    } catch {
      return match
    }
  })
}
