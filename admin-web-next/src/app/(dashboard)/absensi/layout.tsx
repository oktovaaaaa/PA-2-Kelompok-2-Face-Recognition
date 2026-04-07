import type { Metadata } from 'next'
import type { ChildrenType } from '@core/types'

export const metadata: Metadata = {
  title: 'Laporan Absensi'
}

const AbsensiLayout = ({ children }: ChildrenType) => {
  return <>{children}</>
}

export default AbsensiLayout
