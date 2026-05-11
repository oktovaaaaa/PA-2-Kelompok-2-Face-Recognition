'use client'

// React Imports
import { useState } from 'react'
import type { FormEvent } from 'react'

// Next Imports
import { useRouter } from 'next/navigation'

// MUI Imports
import Snackbar from '@mui/material/Snackbar'
import Alert from '@mui/material/Alert'
import CircularProgress from '@mui/material/CircularProgress'

// Type Imports
import type { Mode } from '@core/types'

// Component Imports
import DirectionalIcon from '@components/DirectionalIcon'
import Link from '@components/Link'
import OTPInput from '@components/OTPInput'

// Service Imports
import { authService } from '@/libs/auth'

const ForgotPassword = ({ mode }: { mode: Mode }) => {

  // States
  const [step, setStep] = useState<'request' | 'reset'>('request')
  const [loading, setLoading] = useState(false)
  const [isPasswordShown, setIsPasswordShown] = useState(false)
  
  // Form States
  const [email, setEmail] = useState('')
  const [otpCode, setOtpCode] = useState('')
  const [newPassword, setNewPassword] = useState('')

  // Notification States
  const [openSnackbar, setOpenSnackbar] = useState(false)
  const [snackbarMessage, setSnackbarMessage] = useState('')
  const [snackbarSeverity, setSnackbarSeverity] = useState<'success' | 'error' | 'info' | 'warning'>('success')

  // Hooks
  const router = useRouter()

  const handleShowNotification = (message: string, severity: 'success' | 'error' | 'info' | 'warning') => {
    setSnackbarMessage(message)
    setSnackbarSeverity(severity)
    setOpenSnackbar(true)
  }

  const handleRequestOTP = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault()

    if (!email) {
      handleShowNotification('Email wajib diisi', 'warning')

      return
    }

    setLoading(true)

    try {
      await authService.requestResetOTP(email)
      handleShowNotification('Kode OTP telah dikirim ke email Anda', 'success')
      setStep('reset')
    } catch (error: any) {
      handleShowNotification(error.message, 'error')
    } finally {
      setLoading(false)
    }
  }

  const handleResetPassword = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault()

    if (!otpCode || !newPassword) {
      handleShowNotification('Semua field wajib diisi', 'warning')

      return
    }

    setLoading(true)

    try {
      await authService.resetPassword(email, otpCode, newPassword)
      handleShowNotification('Kata sandi berhasil diperbarui! Silakan login.', 'success')
      
      setTimeout(() => {
        router.push('/login')
      }, 2000)
    } catch (error: any) {
      handleShowNotification(error.message, 'error')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className='min-h-screen grid place-items-center bg-[#F1F5F9] p-6 font-outfit'>
      <div className='login-container w-full max-w-[1000px] h-[600px] bg-white rounded-[32px] flex overflow-hidden shadow-2xl relative z-10'>
        
        {/* WELCOME PANE (LEFT) */}
        <div className='welcome-pane flex-1 hidden md:flex flex-col justify-center p-[60px] relative overflow-hidden bg-gradient-to-br from-[#00C6FF] to-[#0072FF] text-white'>
          {/* Decorative Circles */}
          <div className='absolute bg-white/10 rounded-full w-[400px] h-[400px] -bottom-[100px] -left-[100px] z-1' />
          <div className='absolute bg-white/10 rounded-full w-[250px] h-[250px] -top-[50px] -right-[50px] z-1' />
          <div className='absolute bg-white/5 rounded-full w-[150px] h-[150px] bottom-[100px] right-[50px] z-1' />
          
          <h1 className='text-[40px] font-extrabold leading-tight mb-2 z-10'>PULIHKAN</h1>
          <h2 className='text-[20px] font-bold uppercase tracking-[2px] mb-6 z-10'>KONTROL AKSES</h2>
          <p className='text-[14px] text-white/80 leading-relaxed max-w-[320px] z-10'>
            Keamanan akun adalah prioritas kami. Gunakan sistem verifikasi OTP untuk memulihkan akses ke dashboard Admin Anda dengan aman.
          </p>
        </div>

        {/* FORM PANE (RIGHT) */}
        <div className='form-pane flex-1 p-10 md:p-[80px] flex flex-col justify-center relative bg-white'>
          {step === 'request' ? (
            <div className='view-container animate-fade-in'>
              <div className='mb-6'>
                <Link href='/login' className='flex items-center gap-2 text-[#64748B] hover:text-[#2563EB] transition-colors'>
                  <DirectionalIcon ltrIconClass='bx bx-left-arrow-alt' rtlIconClass='bx bx-right-arrow-alt' className='text-[24px]' />
                  <span className='text-[14px] font-bold'>Kembali ke Login</span>
                </Link>
              </div>
              <h2 className='text-[32px] font-extrabold mb-1 text-[#0F172A]'>Lupa Kata Sandi</h2>
              <p className='text-[#64748B] text-[14px] mb-8'>Masukkan alamat email Anda untuk memulihkan akses akun.</p>
              
              <form onSubmit={handleRequestOTP} className='flex flex-col gap-5'>
                {/* Email Input */}
                <div className='auth-input-wrapper flex items-center bg-[#F1F5F9] rounded-full px-5 border-2 border-transparent transition-all focus-within:bg-white focus-within:border-[#2563EB]'>
                  <i className='bx bx-envelope text-[20px] text-[#64748B] mr-3' />
                  <input 
                    type='email' 
                    className='w-full border-none bg-transparent py-4 text-[14px] font-semibold outline-none text-[#1E293B]'
                    placeholder='Alamat Email Admin'
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                  />
                </div>

                <button 
                  type='submit' 
                  disabled={loading}
                  className='w-full py-4 bg-[#0F172A] text-white rounded-full text-[16px] font-extrabold transition-all hover:scale-[1.02] hover:shadow-lg disabled:opacity-70 flex justify-center items-center gap-2 mt-2'
                >
                  {loading ? <CircularProgress size={20} color='inherit' /> : 'Kirim Kode Verifikasi'}
                </button>
              </form>
            </div>
          ) : (
            <div className='view-container animate-fade-in'>
              <h2 className='text-[32px] font-extrabold mb-1 text-[#0F172A]'>Atur Ulang Sandi</h2>
              <p className='text-[#64748B] text-[14px] mb-8'>Gunakan kode OTP yang diterima dan buat sandi baru.</p>
              
              <form onSubmit={handleResetPassword} className='flex flex-col gap-4'>
                {/* OTP Input */}
                <div className='flex flex-col gap-2 mb-2'>
                  <label className='text-[12px] font-bold text-[#64748B] ml-1 uppercase tracking-wider'>Masukkan 6 Digit OTP</label>
                  <OTPInput 
                    value={otpCode}
                    onChange={setOtpCode}
                    disabled={loading}
                  />
                </div>

                {/* New Password Input */}
                <div className='auth-input-wrapper flex items-center bg-[#F1F5F9] rounded-full px-5 border-2 border-transparent transition-all focus-within:bg-white focus-within:border-[#2563EB]'>
                  <i className='bx bx-lock-alt text-[20px] text-[#64748B] mr-3' />
                  <input 
                    type={isPasswordShown ? 'text' : 'password'} 
                    className='w-full border-none bg-transparent py-4 text-[14px] font-semibold outline-none text-[#1E293B]'
                    placeholder='Kata Sandi Baru'
                    value={newPassword}
                    onChange={(e) => setNewPassword(e.target.value)}
                    required
                  />
                  <span 
                    className='text-[#2563EB] text-[11px] font-extrabold uppercase cursor-pointer select-none ml-2'
                    onClick={() => setIsPasswordShown(!isPasswordShown)}
                  >
                    {isPasswordShown ? 'SEMBUNYIKAN' : 'TAMPILKAN'}
                  </span>
                </div>

                <button 
                  type='submit' 
                  disabled={loading}
                  className='w-full py-4 bg-[#0F172A] text-white rounded-full text-[16px] font-extrabold transition-all hover:scale-[1.02] hover:shadow-lg disabled:opacity-70 flex justify-center items-center gap-2 mt-4'
                >
                  {loading ? <CircularProgress size={20} color='inherit' /> : 'Perbarui Kata Sandi'}
                </button>
                
                <button 
                  type='button'
                  onClick={() => setStep('request')}
                  className='text-[14px] font-bold text-[#64748B] hover:text-[#0F172A] text-center w-full'
                >
                  Ganti Email / Kembali
                </button>
              </form>
            </div>
          )}
        </div>
      </div>

      {/* Notifications */}
      <Snackbar 
        open={openSnackbar} 
        autoHideDuration={6000} 
        onClose={() => setOpenSnackbar(false)}
        anchorOrigin={{ vertical: 'top', horizontal: 'center' }}
      >
        <Alert onClose={() => setOpenSnackbar(false)} severity={snackbarSeverity} variant='filled' sx={{ width: '100%', borderRadius: '100px' }}>
          {snackbarMessage}
        </Alert>
      </Snackbar>

      <style jsx global>{`
        @keyframes fadeIn {
          from { opacity: 0; transform: translateY(10px); }
          to { opacity: 1; transform: translateY(0); }
        }
        .animate-fade-in {
          animation: fadeIn 0.4s ease-out forwards;
        }
      `}</style>
    </div>
  )
}

export default ForgotPassword
