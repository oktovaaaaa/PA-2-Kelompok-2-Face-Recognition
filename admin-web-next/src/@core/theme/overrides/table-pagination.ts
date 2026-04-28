// MUI Imports
import type { Theme } from '@mui/material/styles'

const tablePagination: Theme['components'] = {
  MuiTablePagination: {
    defaultProps: {
      labelRowsPerPage: 'Baris per halaman:',
      labelDisplayedRows: ({ from, to, count }) => `${from}-${to} dari ${count !== -1 ? count : `lebih dari ${to}`}`
    },
    styleOverrides: {
      toolbar: ({ theme }) => ({
        paddingInlineEnd: `${theme.spacing(3)} !important`
      }),
      select: ({ theme }) => ({
        ...theme.typography.body1,
        paddingInlineStart: 0,
        '& ~ i, & ~ svg': {
          fontSize: 20,
          right: '2px !important',
          color: 'var(--mui-palette-action-active)'
        }
      }),
      selectLabel: ({ theme }) => ({
        ...theme.typography.body1,
        color: 'var(--mui-palette-text-secondary)'
      }),
      input: ({ theme }) => ({
        marginInlineEnd: theme.spacing(6)
      }),
      displayedRows: ({ theme }) => ({
        ...theme.typography.body1
      }),
      actions: ({ theme }) => ({
        marginInlineStart: theme.spacing(6),
        '& .Mui-disabled': {
          color: 'var(--mui-palette-action-active)'
        },
        '& .MuiIconButton-root:last-of-type': {
          marginInlineStart: theme.spacing(2)
        }
      })
    }
  }
}

export default tablePagination
