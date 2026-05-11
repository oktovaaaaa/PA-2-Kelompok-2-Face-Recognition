'use client'

// React Imports
import { useState, useEffect } from 'react'
import type { FormEvent } from 'react'

// Next Imports
import { useRouter } from 'next/navigation'

// MUI Imports
import Snackbar from '@mui/material/Snackbar'
import Alert from '@mui/material/Alert'
import CircularProgress from '@mui/material/CircularProgress'

// Type Imports
import { useGoogleLogin } from '@react-oauth/google'

import type { Mode } from '@core/types'

// Component Imports
import Link from '@components/Link'

// React-OAuth Import

// Service Imports
import { authService } from '@/libs/auth'

const Login = ({ mode }: { mode: Mode }) => {
  // States
  const [isPasswordShown, setIsPasswordShown] = useState(false)
  const [step, setStep] = useState<'login' | 'otp'>('login')
  const [loading, setLoading] = useState(false)
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [otpDigits, setOtpDigits] = useState<string[]>(['', '', '', '', '', ''])
  const [rememberMe, setRememberMe] = useState(true)
  const [resendTimer, setResendTimer] = useState(0)
  const [isResending, setIsResending] = useState(false)

  // Notification States
  const [openSnackbar, setOpenSnackbar] = useState(false)
  const [snackbarMessage, setSnackbarMessage] = useState('')
  const [snackbarSeverity, setSnackbarSeverity] = useState<'success' | 'error' | 'info' | 'warning'>('success')

  // Hooks
  const router = useRouter()

  // Timer Effect
  useEffect(() => {
    let interval: NodeJS.Timeout

    if (resendTimer > 0 && step === 'otp') {
      interval = setInterval(() => {
        setResendTimer((prev) => prev - 1)
      }, 1000)
    }

    
return () => clearInterval(interval)
  }, [resendTimer, step])

  useEffect(() => {
    if (step === 'otp' && resendTimer === 0) {
      setResendTimer(30)
    }
  }, [step])

  const handleGoogleLogin = useGoogleLogin({
    onSuccess: async (tokenResponse) => {
      setLoading(true)

      try {
        // Fetch user profile to get email
        const userRes = await fetch(`https://www.googleapis.com/oauth2/v3/userinfo?access_token=${tokenResponse.access_token}`)
        
        if (!userRes.ok) {
          throw new Error('Gagal mengambil profil dari Google. Silakan coba lagi.')
        }

        const userData = await userRes.json()
        
        if (userData && userData.email) {
          // Trigger backend OTP send for this email
          await authService.sendOTP(userData.email)
          
          setEmail(userData.email)
          handleShowNotification('Akun Google diverifikasi. Kode OTP telah dikirim ke email Anda.', 'success')
          setStep('otp')
        } else {
          throw new Error('Email tidak ditemukan di profil Google Anda.')
        }
      } catch (error: any) {
        console.error('Google Login Error:', error)
        
        let errorMessage = 'Gagal login dengan Google'
        
        if (error.message === 'Failed to fetch') {
          errorMessage = 'Tidak dapat terhubung ke server. Pastikan koneksi internet stabil dan server backend berjalan.'
        } else if (error.message) {
          errorMessage = error.message
        }
        
        handleShowNotification(errorMessage, 'error')
      } finally {
        setLoading(false)
      }
    },
    onError: () => handleShowNotification('Login Google dibatalkan atau terjadi kesalahan', 'error')
  })

  const handleShowNotification = (message: string, severity: 'success' | 'error' | 'info' | 'warning') => {
    setSnackbarMessage(message)
    setSnackbarSeverity(severity)
    setOpenSnackbar(true)
  }

  const handleLoginSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault()

    if (!email || !password) {
      handleShowNotification('Email dan password wajib diisi', 'warning')

      return
    }

    setLoading(true)

    try {
      await authService.loginStep1(email, password)
      handleShowNotification('Kode OTP telah dikirim ke email Anda', 'success')
      setStep('otp')
    } catch (error: any) {
      if (error.message) {
        handleShowNotification(error.message, 'error')
      }
    } finally {
      setLoading(false)
    }
  }

  const handleOtpSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    const fullOtp = otpDigits.join('')

    if (fullOtp.length !== 6) {
      handleShowNotification('Silakan masukkan 6 digit kode OTP', 'warning')

      return
    }

    setLoading(true)

    try {
      await authService.loginStep2(email, fullOtp, rememberMe)
      handleShowNotification('Login berhasil! Mengalihkan...', 'success')
      
      setTimeout(() => {
        router.push('/dashboard')
      }, 1000)
    } catch (error: any) {
      if (error.message) {
        handleShowNotification(error.message, 'error')
      }
    } finally {
      setLoading(false)
    }
  }

  const handleResendOtp = async () => {
    if (resendTimer > 0 || isResending) return

    setIsResending(true)

    try {
      await authService.sendOTP(email)
      handleShowNotification('Kode OTP baru telah dikirim ke email Anda', 'success')
      setResendTimer(30)
    } catch (error: any) {
      handleShowNotification(error.message || 'Gagal mengirim ulang kode OTP', 'error')
    } finally {
      setIsResending(false)
    }
  }

  const handleOtpChange = (index: number, value: string) => {
    if (!/^\d*$/.test(value)) return // Numeric only

    const newDigits = [...otpDigits]

    newDigits[index] = value.slice(-1) // Take the last character
    setOtpDigits(newDigits)

    // Focus next box if value is entered
    if (value && index < 5) {
      const nextInput = document.getElementById(`otp-${index + 1}`)

      nextInput?.focus()
    }
  }

  const handleOtpKeyDown = (index: number, e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Backspace' && !otpDigits[index] && index > 0) {
      const prevInput = document.getElementById(`otp-${index - 1}`)

      prevInput?.focus()
    }
  }

  const handleOtpPaste = (e: React.ClipboardEvent) => {
    e.preventDefault()
    const pastedData = e.clipboardData.getData('text').slice(0, 6).split('')

    if (pastedData.every(char => /^\d$/.test(char))) {
      const newDigits = [...otpDigits]

      pastedData.forEach((char, i) => {
        newDigits[i] = char
      })
      setOtpDigits(newDigits)
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
          
          <h1 className='text-[48px] font-extrabold leading-tight mb-2 z-10'>SELAMAT DATANG</h1>
          <h2 className='text-[24px] font-bold uppercase tracking-[2px] mb-6 z-10'>VIDENTI ADMIN</h2>
          <p className='text-[14px] text-white/80 leading-relaxed max-w-[320px] z-10'>
            Sistem manajemen absensi cerdas berbasis pemindaian wajah. Kelola data karyawan dan laporan kehadiran dengan mudah bersama VIDENTI.
          </p>
        </div>

        {/* FORM PANE (RIGHT) */}
        <div className='form-pane flex-1 p-10 md:p-[80px] flex flex-col justify-center relative bg-white'>
          <Link href='/landing' className='absolute top-8 left-8 md:left-12 flex items-center gap-2 text-[14px] font-bold text-[#64748B] hover:text-[#2563EB] transition-colors'>
            <i className='bx bx-left-arrow-alt text-[20px]' />
            Kembali ke Beranda
          </Link>

          {step === 'login' ? (
            <div className='view-container animate-fade-in'>
              <h2 className='text-[32px] font-extrabold mb-2 text-[#0F172A]'>Masuk VIDENTI</h2>
              <p className='text-[#64748B] text-[14px] mb-8'>Kelola sistem absensi VIDENTI.</p>
              
              <form onSubmit={handleLoginSubmit} className='flex flex-col gap-4'>
                {/* Email Input */}
                <div className='auth-input-wrapper flex items-center bg-[#F1F5F9] rounded-full px-5 border-2 border-transparent transition-all focus-within:bg-white focus-within:border-[#2563EB]'>
                  <i className='bx bx-user text-[20px] text-[#64748B] mr-3' />
                  <input 
                    type='email' 
                    className='w-full border-none bg-transparent py-4 text-[14px] font-semibold outline-none text-[#1E293B]'
                    placeholder='Alamat Email Admin'
                    value={email}
                    onChange={(e) => setEmail(e.target.value.toLowerCase().trim())}
                    required
                  />
                </div>

                {/* Password Input */}
                <div className='auth-input-wrapper flex items-center bg-[#F1F5F9] rounded-full px-5 border-2 border-transparent transition-all focus-within:bg-white focus-within:border-[#2563EB]'>
                  <i className='bx bx-lock-alt text-[20px] text-[#64748B] mr-3' />
                  <input 
                    type={isPasswordShown ? 'text' : 'password'} 
                    className='w-full border-none bg-transparent py-4 text-[14px] font-semibold outline-none text-[#1E293B]'
                    placeholder='Kata Sandi'
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                  />
                  <span 
                    className='text-[#2563EB] text-[11px] font-extrabold uppercase cursor-pointer select-none ml-2'
                    onClick={() => setIsPasswordShown(!isPasswordShown)}
                  >
                    {isPasswordShown ? 'SEMBUNYIKAN' : 'TAMPILKAN'}
                  </span>
                </div>

                <div className='flex justify-between items-center px-1 py-1'>
                  <label className='flex items-center gap-2 text-[13px] text-[#64748B] cursor-pointer'>
                    <input 
                      type='checkbox' 
                      className='w-4 h-4 accent-[#2563EB]' 
                      checked={rememberMe}
                      onChange={(e) => setRememberMe(e.target.checked)}
                    />
                    Ingat saya
                  </label>
                  <Link href='/forgot-password'>
                    <span className='text-[#2563EB] text-[13px] font-bold'>Lupa Sandi?</span>
                  </Link>
                </div>

                <button 
                  type='submit' 
                  disabled={loading}
                  className='w-full py-4 bg-[#0F172A] text-white rounded-full text-[16px] font-extrabold transition-all hover:scale-[1.02] hover:shadow-lg disabled:opacity-70 flex justify-center items-center gap-2 mt-2'
                >
                  {loading ? <CircularProgress size={20} color='inherit' /> : 'Masuk ke Dashboard'}
                </button>
              </form>

              <div className='relative text-center my-6'>
                <hr className='border-[#E2E8F0]' />
                <span className='absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 bg-white px-4 text-[12px] text-[#64748B]'>Atau masuk dengan</span>
              </div>

              <button 
                type='button'
                onClick={() => handleGoogleLogin()}
                className='w-full py-4 bg-white border-2 border-[#E2E8F0] rounded-full text-[14px] font-bold text-[#0F172A] transition-all hover:bg-[#f8fafc] hover:border-[#cbd5e1] flex items-center justify-center gap-3 disabled:opacity-70'
                disabled={loading}
              >
                <i className='bx bxl-google text-[24px] text-[#DB4437]' />
                Masuk dengan Google
              </button>
            </div>
          ) : (
            <div className='view-container animate-fade-in text-center'>
              <div className='mb-6'>
                <i className='bx bx-shield-quarter text-[64px] text-[#2563EB]' />
              </div>
              <h2 className='text-[32px] font-extrabold mb-2 text-[#0F172A]'>Verifikasi</h2>
              <p className='text-[#64748B] text-[14px] mb-8'>
                Masukkan 6 digit kode yang dikirim ke:<br />
                <strong className='text-[#0F172A]'>{email}</strong>
              </p>
              
              <form onSubmit={handleOtpSubmit} className='flex flex-col gap-6'>
                <div className='flex justify-between gap-2 max-w-[400px] mx-auto w-full'>
                  {otpDigits.map((digit, index) => (
                    <input
                      key={index}
                      id={`otp-${index}`}
                      type='text'
                      inputMode='numeric'
                      maxLength={1}
                      className='w-[48px] h-[60px] text-center text-[24px] font-extrabold bg-[#F1F5F9] border-2 border-transparent rounded-xl focus:bg-white focus:border-[#2563EB] outline-none text-[#2563EB] transition-all shadow-sm'
                      value={digit}
                      onChange={(e) => handleOtpChange(index, e.target.value)}
                      onKeyDown={(e) => handleOtpKeyDown(index, e)}
                      onPaste={handleOtpPaste}
                      required
                    />
                  ))}
                </div>

                <button 
                  type='submit' 
                  disabled={loading}
                  className='w-full py-4 bg-[#0F172A] text-white rounded-full text-[16px] font-extrabold transition-all hover:scale-[1.02] hover:shadow-lg disabled:opacity-70 flex justify-center items-center gap-2'
                >
                  {loading ? <CircularProgress size={20} color='inherit' /> : 'Verifikasi Sekarang'}
                </button>
                
                <div className='flex flex-col gap-4 mt-2'>
                  <p className='text-[14px] text-[#64748B]'>
                    Tidak menerima kode?{' '}
                    {resendTimer > 0 ? (
                      <span className='text-[#94A3B8] font-bold'>Kirim ulang dalam {resendTimer}s</span>
                    ) : (
                      <button 
                        type='button' 
                        onClick={handleResendOtp}
                        disabled={isResending}
                        className='text-[#2563EB] font-bold hover:underline disabled:opacity-50'
                      >
                        Kirim Ulang
                      </button>
                    )}
                  </p>

                  <button 
                    type='button'
                    onClick={() => setStep('login')}
                    className='w-full py-4 bg-[#F1F5F9] border-2 border-[#E2E8F0] rounded-full text-[14px] font-bold text-[#475569] hover:bg-[#E2E8F0] transition-all flex items-center justify-center gap-2'
                  >
                    <i className='bx bx-left-arrow-alt text-[20px]' />
                    Ganti Email / Kembali
                  </button>
                </div>
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

export default Login
