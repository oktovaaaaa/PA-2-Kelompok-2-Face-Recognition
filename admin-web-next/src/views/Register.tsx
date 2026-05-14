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
import type { Mode } from '@core/types'

// Component Imports
import Link from '@components/Link'

// Service Imports
import { authService } from '@/libs/auth'

const Register = ({ mode }: { mode: Mode }) => {
  // States
  const [isPasswordShown, setIsPasswordShown] = useState(false)
  const [step, setStep] = useState<'register' | 'otp'>('register')
  const [loading, setLoading] = useState(false)
  
  // Form Data
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    password: '',
    companyName: '',
    otpCode: ''
  })
  
  const [otpDigits, setOtpDigits] = useState<string[]>(['', '', '', '', '', ''])
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

  const handleShowNotification = (message: string, severity: 'success' | 'error' | 'info' | 'warning') => {
    setSnackbarMessage(message)
    setSnackbarSeverity(severity)
    setOpenSnackbar(true)
  }

  const handleRegisterSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault()

    if (!formData.email || !formData.password || !formData.name || !formData.companyName) {
      handleShowNotification('Semua data wajib diisi', 'warning')
      
return
    }

    setLoading(true)

    try {
      await authService.sendOTP(formData.email, true)
      handleShowNotification('Kode verifikasi telah dikirim ke email Anda', 'success')
      setStep('otp')
      setResendTimer(30)
    } catch (error: any) {
      handleShowNotification(error.message || 'Gagal mengirim OTP', 'error')
    } finally {
      setLoading(false)
    }
  }

  const handleOtpSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    const fullOtp = otpDigits.join('')

    if (fullOtp.length !== 6) {
      handleShowNotification('Silakan masukkan 6 digit kode verifikasi', 'warning')
      
return
    }

    setLoading(true)

    try {
      await authService.register(
        formData.name,
        formData.email,
        formData.password,
        formData.companyName,
        fullOtp
      )
      handleShowNotification('Registrasi berhasil! Silakan masuk.', 'success')
      
      setTimeout(() => {
        router.push('/login')
      }, 2000)
    } catch (error: any) {
      handleShowNotification(error.message || 'Registrasi gagal', 'error')
    } finally {
      setLoading(false)
    }
  }

  const handleResendOtp = async () => {
    if (resendTimer > 0 || isResending) return

    setIsResending(true)

    try {
      await authService.sendOTP(formData.email, true)
      handleShowNotification('Kode verifikasi baru telah dikirim', 'success')
      setResendTimer(30)
    } catch (error: any) {
      handleShowNotification(error.message || 'Gagal mengirim ulang kode', 'error')
    } finally {
      setIsResending(false)
    }
  }

  const handleOtpChange = (index: number, value: string) => {
    if (!/^\d*$/.test(value)) return
    const newDigits = [...otpDigits]

    newDigits[index] = value.slice(-1)
    setOtpDigits(newDigits)

    if (value && index < 5) {
      document.getElementById(`otp-${index + 1}`)?.focus()
    }
  }

  return (
    <div className='min-h-screen grid place-items-center bg-[#F1F5F9] p-6 font-outfit'>
      <div className='login-container w-full max-w-[1000px] min-h-[600px] bg-white rounded-[32px] flex overflow-hidden shadow-2xl relative z-10'>
        
        {/* WELCOME PANE (LEFT) */}
        <div className='welcome-pane flex-1 hidden md:flex flex-col justify-center p-[60px] relative overflow-hidden bg-gradient-to-br from-[#00C6FF] to-[#0072FF] text-white'>
          <div className='absolute bg-white/10 rounded-full w-[400px] h-[400px] -bottom-[100px] -left-[100px] z-1' />
          <h1 className='text-[48px] font-extrabold leading-tight mb-2 z-10'>GABUNG VIDENTI</h1>
          <h2 className='text-[24px] font-bold uppercase tracking-[2px] mb-6 z-10'>KELOLA INSTANSI ANDA</h2>
          <p className='text-[14px] text-white/80 leading-relaxed max-w-[320px] z-10'>
            Mulai kelola kehadiran karyawan dengan teknologi AI Face Recognition tercanggih. Efisien, Akurat, dan Transparan.
          </p>
        </div>

        {/* FORM PANE (RIGHT) */}
        <div className='form-pane flex-1 p-10 md:p-[60px] flex flex-col justify-center relative bg-white'>
          <Link href='/landing' className='absolute top-8 left-8 md:left-12 flex items-center gap-2 text-[14px] font-bold text-[#64748B] hover:text-[#2563EB] transition-colors'>
            <i className='bx bx-left-arrow-alt text-[20px]' />
            Kembali
          </Link>

          {step === 'register' ? (
            <div className='view-container animate-fade-in'>
              <h2 className='text-[28px] font-extrabold mb-1 text-[#0F172A]'>Daftar Akun Admin</h2>
              <p className='text-[#64748B] text-[13px] mb-6'>Buat akun untuk instansi/perusahaan Anda.</p>
              
              <form onSubmit={handleRegisterSubmit} className='flex flex-col gap-3'>
                <div className='auth-input-wrapper flex items-center bg-[#F1F5F9] rounded-full px-5 border-2 border-transparent transition-all focus-within:bg-white focus-within:border-[#2563EB]'>
                  <i className='bx bx-user text-[18px] text-[#64748B] mr-3' />
                  <input 
                    type='text' 
                    className='w-full border-none bg-transparent py-3 text-[13px] font-semibold outline-none text-[#1E293B]'
                    placeholder='Nama Lengkap'
                    value={formData.name}
                    onChange={(e) => setFormData({...formData, name: e.target.value})}
                    required
                  />
                </div>

                <div className='auth-input-wrapper flex items-center bg-[#F1F5F9] rounded-full px-5 border-2 border-transparent transition-all focus-within:bg-white focus-within:border-[#2563EB]'>
                  <i className='bx bx-envelope text-[18px] text-[#64748B] mr-3' />
                  <input 
                    type='email' 
                    className='w-full border-none bg-transparent py-3 text-[13px] font-semibold outline-none text-[#1E293B]'
                    placeholder='Email Kerja'
                    value={formData.email}
                    onChange={(e) => setFormData({...formData, email: e.target.value.toLowerCase().trim()})}
                    required
                  />
                </div>

                <div className='auth-input-wrapper flex items-center bg-[#F1F5F9] rounded-full px-5 border-2 border-transparent transition-all focus-within:bg-white focus-within:border-[#2563EB]'>
                  <i className='bx bx-building text-[18px] text-[#64748B] mr-3' />
                  <input 
                    type='text' 
                    className='w-full border-none bg-transparent py-3 text-[13px] font-semibold outline-none text-[#1E293B]'
                    placeholder='Nama Instansi / Perusahaan'
                    value={formData.companyName}
                    onChange={(e) => setFormData({...formData, companyName: e.target.value})}
                    required
                  />
                </div>

                <div className='auth-input-wrapper flex items-center bg-[#F1F5F9] rounded-full px-5 border-2 border-transparent transition-all focus-within:bg-white focus-within:border-[#2563EB]'>
                  <i className='bx bx-lock-alt text-[18px] text-[#64748B] mr-3' />
                  <input 
                    type={isPasswordShown ? 'text' : 'password'} 
                    className='w-full border-none bg-transparent py-3 text-[13px] font-semibold outline-none text-[#1E293B]'
                    placeholder='Kata Sandi'
                    value={formData.password}
                    onChange={(e) => setFormData({...formData, password: e.target.value})}
                    required
                  />
                  <span 
                    className='text-[#2563EB] text-[10px] font-extrabold cursor-pointer'
                    onClick={() => setIsPasswordShown(!isPasswordShown)}
                  >
                    {isPasswordShown ? 'HIDE' : 'SHOW'}
                  </span>
                </div>

                <button 
                  type='submit' 
                  disabled={loading}
                  className='w-full py-3.5 bg-[#0F172A] text-white rounded-full text-[15px] font-extrabold transition-all hover:scale-[1.02] disabled:opacity-70 mt-4'
                >
                  {loading ? <CircularProgress size={20} color='inherit' /> : 'Daftar Sekarang'}
                </button>
              </form>

              <p className='text-center text-[13px] text-[#64748B] mt-6'>
                Sudah punya akun? <Link href='/login' className='text-[#2563EB] font-bold'>Masuk di sini</Link>
              </p>
            </div>
          ) : (
            <div className='view-container animate-fade-in text-center'>
              <h2 className='text-[28px] font-extrabold mb-1 text-[#0F172A]'>Verifikasi</h2>
              <p className='text-[#64748B] text-[13px] mb-8'>Masukkan kode OTP yang dikirim ke {formData.email}</p>
              
              <form onSubmit={handleOtpSubmit} className='flex flex-col gap-6'>
                <div className='flex justify-between gap-2 max-w-[350px] mx-auto'>
                  {otpDigits.map((digit, index) => (
                    <input
                      key={index}
                      id={`otp-${index}`}
                      type='text'
                      maxLength={1}
                      className='w-12 h-14 text-center text-xl font-bold bg-[#F1F5F9] rounded-xl border-2 border-transparent focus:border-[#2563EB] outline-none'
                      value={digit}
                      onChange={(e) => handleOtpChange(index, e.target.value)}
                      required
                    />
                  ))}
                </div>

                <button type='submit' disabled={loading} className='w-full py-3.5 bg-[#0F172A] text-white rounded-full font-bold'>
                  {loading ? 'Memproses...' : 'Konfirmasi Registrasi'}
                </button>
                
                <p className='text-[13px] text-[#64748B]'>
                  Belum terima kode?{' '}
                  {resendTimer > 0 ? (
                    <span className='font-bold'>Tunggu {resendTimer}s</span>
                  ) : (
                    <button type='button' onClick={handleResendOtp} className='text-[#2563EB] font-bold'>Kirim Ulang</button>
                  )}
                </p>
              </form>
            </div>
          )}
        </div>
      </div>

      <Snackbar open={openSnackbar} autoHideDuration={6000} onClose={() => setOpenSnackbar(false)} anchorOrigin={{ vertical: 'top', horizontal: 'center' }}>
        <Alert severity={snackbarSeverity} variant='filled'>{snackbarMessage}</Alert>
      </Snackbar>
    </div>
  )
}

export default Register
