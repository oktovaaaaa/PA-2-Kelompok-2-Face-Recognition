import type { Metadata } from 'next'

import type { ChildrenType } from '@core/types'

export const metadata: Metadata = {
  title: 'Gaji Karyawan'
}

const PayrollLayout = ({ children }: ChildrenType) => {
  return <>{children}</>
}

export default PayrollLayout
