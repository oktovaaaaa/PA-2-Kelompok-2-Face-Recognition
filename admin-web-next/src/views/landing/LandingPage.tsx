'use client'

import React, { useState, useEffect } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { GoogleLogin, googleLogout, CredentialResponse } from '@react-oauth/google'
import './landing.css'

// Image path as generated earlier
const HERO_IMAGE = '/attendance_app_hero_1775490992311.png'
const FACE_ID_ICON = 'https://img.icons8.com/fluency/240/facial-recognition.png'
const REALTIME_ICON = 'https://img.icons8.com/fluency/240/clock.png'
const ANALYTICS_ICON = 'https://img.icons8.com/fluency/240/bar-chart.png'
const RIBBON_PERSON_IMAGE = '/person_holding_phone_transparent_ribbon_1775492707836.png'
const FOOTER_BOY_IMAGE = '/indonesian_kid_flag_astra_style_illustrator_1775493190869.png'
const ABOUT_IMAGE_MAIN = '/professional_man_holding_card_about_1775493818834.png'
const ABOUT_IMAGE_SUB = '/woman_laptop_office_about_small_1775493849199.png'

const LandingPage = () => {
  const router = useRouter()
  const [activeFeatureIndex, setActiveFeatureIndex] = useState(5)
  const [isInteracting, setIsInteracting] = useState(false)
  const [hasTransition, setHasTransition] = useState(true)
  const [isLoggedIn, setIsLoggedIn] = useState(false)
  const [userEmail, setUserEmail] = useState('')
  const [showContactForm, setShowContactForm] = useState(false)

  const [formData, setFormData] = useState({
    nama: '',
    kategori: 'Umum',
    email: '',
    telepon: '',
    pekerjaan: '',
    perusahaan: '',
    kota: '',
    negara: 'Indonesia',
    subyek: '',
    pesan: ''
  })

  // Raw features array stays same...
  const rawFeatures = [
    { title: 'Auto Payroll', desc: 'Penghitungan gaji otomatis berdasarkan data absensi real-time.', icon: 'https://img.icons8.com/fluency/240/money-transfer.png' },
    { title: 'Face Recognition', desc: 'Teknologi pengenalan wajah tercanggih untuk mencegah kecurangan.', icon: FACE_ID_ICON },
    { title: 'Real-time Tracking', desc: 'Pantau kehadiran secara langsung dari dashboard administratif.', icon: REALTIME_ICON },
    { title: 'Advanced Analytics', desc: 'Laporan absensi otomatis yang mendalam untuk membantu keputusan.', icon: ANALYTICS_ICON },
    { title: 'Mobile Access', desc: 'Akses dashboard dan lapor kehadiran langsung dari smartphone.', icon: 'https://img.icons8.com/fluency/240/smartphone.png' }
  ]

  // Triple set for loop
  const features = [...rawFeatures, ...rawFeatures, ...rawFeatures]

  useEffect(() => {
    if (isInteracting) return
    const timer = setInterval(() => {
      setHasTransition(true)
      setActiveFeatureIndex(prev => prev + 1)
    }, 2500)
    return () => clearInterval(timer)
  }, [isInteracting])

  useEffect(() => {
    if (activeFeatureIndex >= 10) {
      const timeout = setTimeout(() => { setHasTransition(false); setActiveFeatureIndex(prev => prev - 5) }, 500)
      return () => clearTimeout(timeout)
    }
    if (activeFeatureIndex < 5) {
      const timeout = setTimeout(() => { setHasTransition(false); setActiveFeatureIndex(prev => prev + 5) }, 500)
      return () => clearTimeout(timeout)
    }
  }, [activeFeatureIndex])

  const handleManualInteraction = () => {
    setIsInteracting(true)
    const timeoutId = (window as any).interactionTimeout
    if (timeoutId) clearTimeout(timeoutId)
    ;(window as any).interactionTimeout = setTimeout(() => setIsInteracting(false), 10000)
  }

  const handleNext = () => { handleManualInteraction(); setHasTransition(true); setActiveFeatureIndex(prev => prev + 1) }
  const handlePrev = () => { handleManualInteraction(); setHasTransition(true); setActiveFeatureIndex(prev => prev - 1) }
  const handleCardClick = (index: number) => { handleManualInteraction(); setHasTransition(true); setActiveFeatureIndex(index) }

  const handleWhatsAppSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    const message = `Halo Admin FaceAttend,
Saya ingin menghubungi Anda dengan detail berikut:
*Nama:* ${formData.nama}
*Kategori:* ${formData.kategori}
*Email:* ${formData.email}
*Telepon:* ${formData.telepon}
*Pekerjaan:* ${formData.pekerjaan}
*Perusahaan:* ${formData.perusahaan}
*Kota:* ${formData.kota}
*Negara:* ${formData.negara}
*Subyek:* ${formData.subyek}
*Pesan:* ${formData.pesan}`

    const waUrl = `https://wa.me/62881080811110?text=${encodeURIComponent(message)}`
    window.open(waUrl, '_blank')
  }

  const handleFormChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    setFormData({ ...formData, [e.target.name]: e.target.value })
  }

  useEffect(() => {
    const token = localStorage.getItem('token')
    const email = localStorage.getItem('user_email')
    if (token && email) { setIsLoggedIn(true); setUserEmail(email) }
  }, [])

  const handleLoginSuccess = async (response: CredentialResponse) => {
    if (!response.credential) return

    try {
      // Decode JWT to get email locally first (optional)
      const base64Url = response.credential.split('.')[1]
      const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/')
      const jsonPayload = decodeURIComponent(
        atob(base64)
          .split('')
          .map(function (c) {
            return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2)
          })
          .join('')
      )
      const payload = JSON.parse(jsonPayload)
      const email = payload.email

      // Backend call to verify admin
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/auth/google-login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ token: response.credential })
      })

      if (res.ok) {
        const data = await res.json()
        localStorage.setItem('token', data.token)
        localStorage.setItem('user_email', email)
        setIsLoggedIn(true)
        setUserEmail(email)
        alert('Login Successful! Welcome Admin.')
      } else {
        const errorData = await res.json()
        alert(errorData.message || 'Login failed. Only admin accounts are allowed.')
      }
    } catch (error) {
      console.error('Login error:', error)
      alert('An error occurred during login.')
    }
  }

  const handleLogout = () => {
    googleLogout()
    localStorage.removeItem('token')
    localStorage.removeItem('user_email')
    setIsLoggedIn(false)
    setUserEmail('')
    router.push('/landing')
  }

  return (
    <div className='landing-container'>
      {/* Navbar */}
      <nav className='navbar'>
        <Link href='/' className='navbar-logo'>
          <img src='https://img.icons8.com/fluency/48/face-id.png' alt='Logo' />
          <span>FaceAttend</span>
        </Link>
        <ul className='navbar-links'>
          <li><a href='#home'>Beranda</a></li>
          <li><a href='#features'>Fitur</a></li>
          <li><a href='#how-it-works'>Cara Kerja</a></li>
          <li><a href='#about'>Tentang Kami</a></li>
          <li><a href='#contact'>Kontak</a></li>
        </ul>
        <div className='navbar-auth'>
          {isLoggedIn ? (
            <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
              <Link href='/dashboard' className='login-btn' style={{ background: 'transparent' }}>Dashboard</Link>
              <button onClick={handleLogout} className='login-btn'>Log Out</button>
            </div>
          ) : (
            <div className='google-login-wrapper'>
              <GoogleLogin
                onSuccess={handleLoginSuccess}
                onError={() => alert('Login Failed')}
                theme='filled_blue'
                shape='pill'
                text='signin'
              />
            </div>
          )}
        </div>
      </nav>

      {/* Hero Section */}
      <section className='hero' id='home'>
        <div className='hero-content'>
          <p className='hero-subtitle'>Smart Attendance System</p>
          <h1 className='hero-title'>The Best Attendance For You.</h1>
          <p className='hero-description'>
            FaceAttend adalah sistem absensi modern berbasis Face Recognition yang cepat, akurat, dan aman. 
            Kelola data kehadiran karyawan Anda dengan efisiensi tinggi tanpa ribet.
          </p>
          <div className='hero-cta'>
            <a href='#features' className='btn-primary'>Mulai Sekarang →</a>
          </div>
        </div>
        
        <div className='hero-image-container'>
          <img src={HERO_IMAGE} alt='Attendance App' className='hero-image' />
        </div>
      </section>

      {/* About Company Section (Collage & Stats) */}
      <section className='about-company' id='about-company'>
        <div className='about-container'>
          <div className='about-collage'>
            <div className='collage-main-wrapper'>
              <img src={ABOUT_IMAGE_MAIN} alt='Our Expert' className='collage-main-img' />
            </div>
            <div className='collage-sub-wrapper'>
              <img src={ABOUT_IMAGE_SUB} alt='Modern Working' className='collage-sub-img' />
            </div>
            <div className='about-badge'>
              <div className='badge-number'>1,485 +</div>
              <div className='badge-text'>Trusted Clients</div>
            </div>
          </div>
          
          <div className='about-info'>
            <div className='about-label'>
              <span className='dot-purple'></span> About Company
            </div>
            <h2 className='about-title'>We Are The Best Online Face Attendance Agency</h2>
            <p className='about-desc'>
              Kami berdedikasi untuk mentransformasi cara perusahaan mengelola kehadiran karyawan. 
              Dengan teknologi mutakhir dan tim ahli yang berpengalaman, kami memberikan solusi 
              paling handal untuk efisiensi bisnis Anda.
            </p>
            
            <div className='about-features-list'>
              <div className='about-feature-item'>
                <div className='item-icon-box purple-bg'>
                  <img src='https://img.icons8.com/color/48/conference-call.png' alt='Partner' />
                </div>
                <div className='item-text'>
                  <h4>Trusted Partner</h4>
                  <p>Mitra terpercaya bagi ratusan perusahaan besar di Indonesia.</p>
                </div>
              </div>
              <div className='about-feature-item'>
                <div className='item-icon-box outline-bg'>
                  <img src='https://img.icons8.com/color/48/fast-forward.png' alt='Fast' />
                </div>
                <div className='item-text'>
                  <h4>Fastpace Platform</h4>
                  <p>Platform super cepat dengan infrastruktur cloud modern.</p>
                </div>
              </div>
              <div className='about-feature-item'>
                <div className='item-icon-box outline-bg'>
                  <img src='https://img.icons8.com/color/48/guarantee.png' alt='Reliability' />
                </div>
                <div className='item-text'>
                  <h4>Tested Reliability</h4>
                  <p>Keandalan yang telah teruji dalam menangani ribuan data setiap hari.</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div className='stats-bar'>
          <div className='stat-item'>
            <h3>25 +</h3>
            <p>Years Of Experience</p>
          </div>
          <div className='stat-item'>
            <h3>3,452 +</h3>
            <p>Total Transaction</p>
          </div>
          <div className='stat-item'>
            <h3>751 +</h3>
            <p>Active User</p>
          </div>
          <div className='stat-item'>
            <h3>592 +</h3>
            <p>Positive Reviews</p>
          </div>
        </div>
      </section>

      {/* Features Section (Layanan Unggulan Kami) */}
      <section className='features-container' id='features'>
        <div className='section-header'>
          <h2>Layanan <span>Unggulan Kami.</span></h2>
        </div>
        
        <div className='carousel-wrapper'>
          <button className='carousel-arrow arrow-left' onClick={handlePrev}>‹</button>
          
          <div 
            className='carousel-track' 
            style={{ 
              transform: `translateX(calc(50% - 160px - ${activeFeatureIndex * 368}px))`,
              transition: hasTransition ? 'all 0.5s ease' : 'none'
            }}
          >
            {features.map((feature, index) => (
              <div 
                key={index} 
                className={`feature-card ${index === activeFeatureIndex ? 'active' : ''}`}
                onClick={() => handleCardClick(index)}
              >
                <div className='feature-icon-wrapper'>
                  <img src={feature.icon} alt={feature.title} className='feature-icon' />
                </div>
                <h3 className='feature-title'>{feature.title}</h3>
                <p className='feature-desc'>{feature.desc}</p>
              </div>
            ))}
          </div>

          <button className='carousel-arrow arrow-right' onClick={handleNext}>›</button>
        </div>
      </section>

      {/* Scrolling Ribbon Divider */}
      <div className='scrolling-divider'>
        <img src={RIBBON_PERSON_IMAGE} className='ribbon-person' alt='Ribbon User' />
        <div className='ribbon-track'>
          <span>FACREC • FACREC • FACREC • FACREC • FACREC • FACREC • FACREC • FACREC • </span>
          <span>FACREC • FACREC • FACREC • FACREC • FACREC • FACREC • FACREC • FACREC • </span>
        </div>
      </div>

      {/* Showcase Section (Bukan Sekedar Absensi Biasa) */}
      <section className='showcase' id='about'>
        <div className='showcase-card-container'>
          <div className='showcase-collage-area'>
            <img 
              src='/attendance_app_collage_1775491357614.png' 
              alt='App Collage' 
              className='collage-image'
            />
          </div>
          <div className='showcase-overlay-box'>
            <h2 className='showcase-title'>Bukan Sekedar Absensi Biasa.</h2>
            <div className='divider-yellow'></div>
            <p className='showcase-desc'>
              FaceAttend dirancang untuk memberikan pengalaman terbaik bagi admin maupun karyawan. 
              Dengan integrasi cloud, data Anda selalu aman dan dapat diakses dari mana saja tanpa kendala.
            </p>
            <a href='#contact' className='btn-showcase'>Mulai sekarang →</a>
          </div>
        </div>
      </section>

      {/* Steps Section */}
      <section className='steps-container' id='how-it-works'>
        <div className='section-header'>
          <h2>Coba sekarang <span>juga.</span></h2>
        </div>
        <div className='steps-grid'>
          <div className='step-card'>
            <img src='https://images.unsplash.com/photo-1516321318423-f06f85e504b3?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80' className='step-image' alt='Scan' />
            <div className='step-content'>
              <span className='step-number'>01</span>
              <h3 className='step-title'>Scanning</h3>
            </div>
          </div>
          <div className='step-card' style={{ border: '2px solid var(--secondary-blue)' }}>
            <img src='https://images.unsplash.com/photo-1551288049-bbbda536339a?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80' className='step-image' alt='Analyzing' />
            <div className='step-content'>
              <span className='step-number'>02</span>
              <h3 className='step-title'>Analyzing</h3>
            </div>
          </div>
          <div className='step-card'>
            <img src='https://images.unsplash.com/photo-1460925895917-afdab827c52f?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80' className='step-image' alt='Reporting' />
            <div className='step-content'>
              <span className='step-number'>03</span>
              <h3 className='step-title'>Reporting</h3>
            </div>
          </div>
        </div>
      </section>

      {/* New Astra-Style Footer Section */}
      <section className='astra-footer' id='contact'>
        {!showContactForm ? (
          <div className='footer-main-content'>
            <div className='footer-visual'>
              <img src={FOOTER_BOY_IMAGE} alt='Indonesian Pride' className='footer-boy-img' />
            </div>
            <div className='footer-text-content'>
              <h2 className='footer-headline'>Terhubung dengan Kami</h2>
              <p className='footer-subheadline'>
                Jadilah bagian dari komunitas kami yang bersemangat dan saling terhubung dalam visi masa depan yang berkelanjutan.
              </p>
              
              <div className='footer-social-row'>
                <a href='#' className='social-icon'>
                  <img src='https://img.icons8.com/color/48/instagram-new.png' alt='Instagram' />
                </a>
                <a href='https://wa.me/62881080811110' className='social-icon'>
                  <img src='https://img.icons8.com/color/48/whatsapp.png' alt='WhatsApp' />
                </a>
                <a href='mailto:support@faceattend.com' className='social-icon'>
                  <img src='https://img.icons8.com/color/48/gmail-new.png' alt='Email' />
                </a>
                <a href='#' className='social-icon'>
                  <img src='https://img.icons8.com/color/48/web.png' alt='Portfolio' />
                </a>
                <a href='#' className='social-icon'>
                  <img src='https://img.icons8.com/color/48/linkedin.png' alt='LinkedIn' />
                </a>
                <button className='btn-contact-trigger' onClick={() => setShowContactForm(true)}>
                  Kontak Kami <span className='arrow-right'>›</span>
                </button>
              </div>
              
              <div className='footer-bottom-links'>
                <a href='#'>Pemberitahuan Privasi</a>
                <span>•</span>
                <a href='#'>Ketentuan Layanan</a>
              </div>
            </div>
          </div>
        ) : (
          <div className='contact-form-container'>
            <div className='form-header-row'>
              <div className='form-logo-box'>
                <img src='https://img.icons8.com/fluency/48/face-id.png' alt='Logo' />
                <span className='form-brand-name'>FaceAttend</span>
              </div>
              <button className='btn-close-form' onClick={() => setShowContactForm(false)}>✕ Close</button>
            </div>
            
            <div className='form-layout-grid'>
              <div className='form-info-side'>
                <h2 className='form-title'>Butuh Bantuan? Silahkan Hubungi Tim</h2>
                <div className='form-highlight-text'>FaceAttend</div>
              </div>
              
              <form className='form-inputs-side' onSubmit={handleWhatsAppSubmit}>
                <div className='input-row'>
                  <div className='input-group'>
                    <label>Nama Anda *</label>
                    <input type='text' name='nama' placeholder='Tuliskan nama Anda' required onChange={handleFormChange} />
                  </div>
                  <div className='input-group'>
                    <label>Kategori *</label>
                    <select name='kategori' onChange={handleFormChange}>
                      <option value='Umum'>Umum</option>
                      <option value='Bisnis'>Bisnis</option>
                      <option value='Kemitraan'>Kemitraan</option>
                    </select>
                  </div>
                </div>
                
                <div className='input-row'>
                  <div className='input-group'>
                    <label>Email *</label>
                    <input type='email' name='email' placeholder='Tuliskan email Anda' required onChange={handleFormChange} />
                  </div>
                  <div className='input-group'>
                    <label>Telepon *</label>
                    <input type='text' name='telepon' placeholder='Tuliskan telepon Anda' required onChange={handleFormChange} />
                  </div>
                </div>

                <div className='input-row'>
                  <div className='input-group'>
                    <label>Pekerjaan *</label>
                    <input type='text' name='pekerjaan' placeholder='Tuliskan pekerjaan Anda' required onChange={handleFormChange} />
                  </div>
                  <div className='input-group'>
                    <label>Perusahaan *</label>
                    <input type='text' name='perusahaan' placeholder='Tuliskan nama perusahaan Anda' required onChange={handleFormChange} />
                  </div>
                </div>

                <div className='input-row'>
                  <div className='input-group'>
                    <label>Kota *</label>
                    <input type='text' name='kota' placeholder='Tuliskan kota tinggal Anda' required onChange={handleFormChange} />
                  </div>
                  <div className='input-group'>
                    <label>Negara *</label>
                    <input type='text' name='negara' placeholder='Indonesia' defaultValue='Indonesia' onChange={handleFormChange} />
                  </div>
                </div>

                <div className='input-group full-width'>
                  <label>Subyek *</label>
                  <input type='text' name='subyek' placeholder='Tuliskan subyek pesan Anda' required onChange={handleFormChange} />
                </div>

                <div className='input-group full-width'>
                  <label>Pesan *</label>
                  <textarea name='pesan' placeholder='Tulis pesan Anda' required rows={4} onChange={handleFormChange}></textarea>
                </div>

                <div className='form-actions'>
                  <button type='reset' className='btn-reset'>Hapus isian</button>
                  <button type='submit' className='btn-submit'>Kirim Pesan</button>
                </div>
              </form>
            </div>
          </div>
        )}
      </section>
    </div>
  )
}

export default LandingPage
