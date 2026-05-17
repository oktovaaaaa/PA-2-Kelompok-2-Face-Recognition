'use client'

import React, { useState, useEffect, useRef } from 'react'

import Link from '@components/Link'
import { useRouter } from 'next/navigation'

import { googleLogout } from '@react-oauth/google'

import { useNotification } from '@/contexts/NotificationContext'
import './landing.css'

// Image path as generated earlier
const HERO_IMAGE = '/videntiprofile.png'
const FACE_ID_ICON = '/images/landing/face_recognition.png'
const REALTIME_ICON = '/images/landing/real_time.png'
const ANALYTICS_ICON = '/images/landing/chart.png'
const MOBILE_ICON = '/images/landing/mobile.png'
const PAYROLL_ICON = '/images/landing/gaji.png'
const DASHBOARD_ICON = '/images/landing/dashboard_web.png'
const RIBBON_PERSON_IMAGE = '/mockupvidenti1.png'
const ABOUT_IMAGE_MAIN = '/vidientiprofile2.png'
const ABOUT_IMAGE_SUB = '/videntiprofile3.png'

const LandingPage = () => {
  const router = useRouter()
  const [activeFeatureIndex, setActiveFeatureIndex] = useState(5)
  const [isInteracting, setIsInteracting] = useState(false)
  const [hasTransition, setHasTransition] = useState(true)
  const [isLoggedIn, setIsLoggedIn] = useState(false)
  const [userEmail, setUserEmail] = useState('')
  const [showContactForm, setShowContactForm] = useState(false)
  const [showTestimonialModal, setShowTestimonialModal] = useState(false)
  const [testimonials, setTestimonials] = useState<any[]>([])
  const [isUploading, setIsUploading] = useState(false)
  const [isScrolled, setIsScrolled] = useState(false)
  const [isMenuOpen, setIsMenuOpen] = useState(false)
  const [windowWidth, setWindowWidth] = useState(0)
  const { showNotification } = useNotification()

  const mockupRef = useRef<HTMLDivElement>(null)
  const [isMockupActive, setIsMockupActive] = useState(false)
  const [ribbonImageIndex, setRibbonImageIndex] = useState(1)

  useEffect(() => {
    const interval = setInterval(() => {
      setRibbonImageIndex(prev => (prev === 12 ? 1 : prev + 1))
    }, 4000)
    return () => clearInterval(interval)
  }, [])

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (mockupRef.current && !mockupRef.current.contains(event.target as Node)) {
        setIsMockupActive(false)
      }
    }
    if (isMockupActive) {
      document.addEventListener('mousedown', handleClickOutside)
    }
    return () => {
      document.removeEventListener('mousedown', handleClickOutside)
    }
  }, [isMockupActive])

  const toggleMenu = () => setIsMenuOpen(!isMenuOpen)

  useEffect(() => {
    setWindowWidth(window.innerWidth)
    const handleResize = () => setWindowWidth(window.innerWidth)
    const handleScroll = () => setIsScrolled(window.scrollY > 50)
    
    window.addEventListener('resize', handleResize)
    window.addEventListener('scroll', handleScroll)

    
return () => {
      window.removeEventListener('resize', handleResize)
      window.removeEventListener('scroll', handleScroll)
    }
  }, [])

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

  const [testiForm, setTestiForm] = useState({
    name: '',
    rating: 0,
    description: '',
    photo_url: ''
  })

  const fetchTestimonials = async () => {
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/testimonials`)

      if (res.ok) {
        const data = await res.json()

        setTestimonials(data.data || [])
      }
    } catch (err) { console.error(err) }
  }

  useEffect(() => {
    fetchTestimonials()
  }, [])

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    if (!e.target.files?.[0]) return
    setIsUploading(true)
    const formData = new FormData()

    formData.append('file', e.target.files[0])

    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/testimonials/upload`, {
        method: 'POST',
        body: formData
      })

      if (res.ok) {
        const data = await res.json()

        setTestiForm({ ...testiForm, photo_url: data.data.url })
      } else {
        showNotification('Gagal mengupload foto', 'error')
      }
    } catch (err) { showNotification('Terjadi kesalahan saat upload', 'error') }

    setIsUploading(false)
  }

  const handleTestiSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    if (isUploading) {
      showNotification('Tunggu hingga foto selesai diupload!', 'warning')
      
return
    }

    if (testiForm.rating === 0) {
      showNotification('Silakan pilih rating minimal 1 bintang!', 'warning')
      
return
    }

    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/testimonials`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(testiForm)
      })

      if (res.ok) {
        showNotification('Testimoni berhasil dikirim!', 'success')
        setShowTestimonialModal(false)
        setTestiForm({
          name: '',
          rating: 0,
          description: '',
          photo_url: ''
        })
        fetchTestimonials()
      }
    } catch (err) { showNotification('Gagal mengirim testimoni', 'error') }
  }

  // Raw features array stays same...
  const rawFeatures = [
    { title: 'Auto Payroll', desc: 'Penghitungan gaji otomatis berdasarkan data absensi real-time.', icon: PAYROLL_ICON },
    { title: 'Face Recognition', desc: 'Teknologi pengenalan wajah tercanggih untuk mencegah kecurangan.', icon: FACE_ID_ICON },
    { title: 'Real-time Tracking', desc: 'Pantau kehadiran secara langsung dari dashboard administratif.', icon: REALTIME_ICON },
    { title: 'Advanced Analytics', desc: 'Laporan absensi otomatis yang mendalam untuk membantu keputusan.', icon: ANALYTICS_ICON },
    { title: 'Mobile Access', desc: 'Akses dashboard dan lapor kehadiran langsung dari smartphone.', icon: MOBILE_ICON },
    { title: 'Admin Dashboard', desc: 'Kelola seluruh data kehadiran, laporan, dan pengaturan karyawan secara tersentralisasi.', icon: DASHBOARD_ICON }
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

    const message = `Halo Admin VIDENTI,
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

    if (token) { setIsLoggedIn(true) }
  }, [])

  const handleLogout = () => {
    googleLogout()
    localStorage.removeItem('token')
    localStorage.removeItem('user_id')
    localStorage.removeItem('user_name')
    localStorage.removeItem('role')
    localStorage.removeItem('company_id')
    setIsLoggedIn(false)
    setUserEmail('')
    router.push('/landing')
  }

  // Scroll Reveal Logic
  useEffect(() => {
    const revealElements = document.querySelectorAll('.reveal');
    
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('active');
        } else {
          // Remove active when leaving to allow re-animation (Exit effect)
          entry.target.classList.remove('active');
        }
      });
    }, { 
      threshold: 0.1, // Trigger when 10% visible
      rootMargin: '0px 0px -50px 0px' // Offset to trigger slightly before bottom of screen
    });

    revealElements.forEach(el => observer.observe(el));
    
    return () => {
      revealElements.forEach(el => observer.unobserve(el));
      observer.disconnect();
    };
  }, [showContactForm, showTestimonialModal, activeFeatureIndex, isLoggedIn, isMockupActive, isScrolled, isMenuOpen, testimonials]); // Re-run on any state changes to prevent React DOM clashing

  return (
    <div className='landing-container'>
      {/* Navbar */}
      <nav className={`navbar ${isScrolled ? 'navbar--scrolled' : ''}`}>
        <Link href='/' className='navbar-logo'>
          <img src='/images/videnti.png' alt='Logo' width={48} height={48} />
          <span>VIDENTI</span>
        </Link>
        
        {/* Desktop Links */}
        <ul className='navbar-links'>
          <li><a href='#home'>Beranda</a></li>
          <li><a href='#features'>Fitur</a></li>
          <li><a href='#testimonials'>Testimoni</a></li>
          <li><a href='#about'>Tentang Kami</a></li>
          <li><a href='#contact'>Kontak</a></li>
        </ul>

        {/* Desktop Auth */}
        <div className='navbar-auth'>
          {isLoggedIn ? (
            <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
              <Link href='/dashboard' className='login-btn' style={{ background: 'linear-gradient(135deg, #2563EB 0%, #3B82F6 100%)', color: '#fff', border: 'none' }}>
                Kembali ke Dashboard
              </Link>
              <button onClick={handleLogout} className='login-btn' style={{ background: 'rgba(255,255,255,0.1)', border: '1px solid rgba(255,255,255,0.2)' }}>
                Log Out
              </button>
            </div>
          ) : (
            <Link href='/login' className='login-btn'>Login</Link>
          )}
        </div>

        {/* Hamburger Menu Toggle (Mobile) */}
        <button className={`menu-toggle ${isMenuOpen ? 'active' : ''}`} onClick={toggleMenu} aria-label='Toggle Menu'>
          <span className='hamburger-line'></span>
          <span className='hamburger-line'></span>
          <span className='hamburger-line'></span>
        </button>

        {/* Mobile Sidebar */}
        <div className={`mobile-sidebar ${isMenuOpen ? 'active' : ''}`}>
          <div className='sidebar-header'>
            <span className='sidebar-logo'>Menu</span>
            <button className='close-menu' onClick={toggleMenu}>✕</button>
          </div>
          <ul className='sidebar-links'>
            <li><a href='#home' onClick={toggleMenu}>Beranda</a></li>
            <li><a href='#features' onClick={toggleMenu}>Fitur</a></li>
            <li><a href='#about' onClick={toggleMenu}>Tentang Kami</a></li>
            <li><a href='#contact' onClick={toggleMenu}>Kontak</a></li>
          </ul>
          <div className='sidebar-auth'>
            {isLoggedIn ? (
              <div className='sidebar-auth-buttons'>
                <Link href='/dashboard' className='login-btn' onClick={toggleMenu} style={{ background: '#2563EB', color: '#fff' }}>
                  Kembali ke Dashboard
                </Link>
                <button onClick={() => { handleLogout(); toggleMenu(); }} className='login-btn logout'>Log Out</button>
              </div>
            ) : (
              <div className='sidebar-auth-buttons' style={{ marginTop: '0' }}>
                <Link href='/login' className='login-btn' onClick={toggleMenu}>Login</Link>
              </div>
            )}
          </div>
        </div>

        {/* Backdrop for Mobile Sidebar */}
        {isMenuOpen && <div className='menu-overlay' onClick={toggleMenu}></div>}
      </nav>

      {/* Hero Section */}
      <section className='hero' id='home'>
        <div className='hero-content reveal reveal-up'>
          <p className='hero-subtitle'>Sistem Absensi Multi-Platform & Manajemen Perusahaan Tersentralisasi</p>
          <h1 className='hero-title'>Sistem Absensi Mobile & Dashboard Web <span style={{ color: '#f97316' }}>Tersentralisasi.</span></h1>
          <p className='hero-description'>
            Karyawan melakukan absensi berbasis Face Recognition & Geolocation secara praktis melalui aplikasi mobile. Administrator dapat mengelola data kehadiran, sistem penggajian otomatis, sanksi, serta bonus karyawan secara fleksibel melalui aplikasi mobile maupun dashboard web tersentralisasi.
          </p>
          <div className='hero-cta'>
            <Link href='/login' className='btn-primary'>Mulai Sekarang</Link>
          </div>
        </div>
        
        <div className='hero-image-container reveal reveal-left'>
          <img src={HERO_IMAGE} alt='Attendance App' className='hero-image' />
        </div>
      </section>

      {/* About Company Section (Collage & Stats) */}
      <section className='about-company' id='about-company'>
        <div className='about-container'>
          <div className='about-collage reveal reveal-left'>
            <div className='collage-main-wrapper'>
              <img src={ABOUT_IMAGE_MAIN} alt='Our Expert' className='collage-main-img' />
            </div>
            <div className='collage-sub-wrapper'>
              <img src={ABOUT_IMAGE_SUB} alt='Modern Working' className='collage-sub-img' />
            </div>
            <div className='about-badge reveal reveal-scale delay-2'>
              <div className='badge-number'>{testimonials.length} +</div>
              <div className='badge-text'>Klien Terpercaya</div>
            </div>
          </div>
          
          <div className='about-info reveal reveal-right'>
            <div className='about-label'>
              <span className='dot-purple'></span> Tentang Perusahaan
            </div>
            <h2 className='about-title'>Kami Adalah Agen Absensi Wajah & Geolokasi Online Terbaik</h2>
            <p className='about-desc'>
              Kami berdedikasi untuk mentransformasi cara perusahaan mengelola kehadiran karyawan. 
              Dengan teknologi mutakhir dan tim ahli yang berpengalaman, kami memberikan solusi 
              paling handal untuk efisiensi bisnis Anda.
            </p>
            
            <div className='about-features-list'>
              <div className='about-feature-item reveal reveal-up delay-1'>
                <div className='item-icon-box purple-bg'>
                  <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#3b82f6" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path>
                    <circle cx="12" cy="10" r="3"></circle>
                  </svg>
                </div>
                <div className='item-text'>
                  <h4>Geolokasi</h4>
                  <p>Absensi hanya dapat dilakukan pada lokasi yang telah ditentukan secara presisi.</p>
                </div>
              </div>
              <div className='about-feature-item reveal reveal-up delay-2'>
                <div className='item-icon-box purple-bg'>
                  <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#3b82f6" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                    <circle cx="12" cy="12" r="10"></circle>
                    <polyline points="12 6 12 12 16 14"></polyline>
                  </svg>
                </div>
                <div className='item-text'>
                  <h4>Monitoring 24 Jam</h4>
                  <p>Memantau seluruh aktivitas kehadiran karyawan secara real-time selama 24 jam.</p>
                </div>
              </div>
              <div className='about-feature-item reveal reveal-up delay-3'>
                <div className='item-icon-box purple-bg'>
                  <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#3b82f6" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M8 3H5a2 2 0 0 0-2 2v3m18 0V5a2 2 0 0 0-2-2h-3m0 18h3a2 2 0 0 0 2-2v-3M3 16v3a2 2 0 0 0 2 2h3"></path>
                    <path d="M8 14s1.5 2 4 2 4-2 4-2"></path>
                    <line x1="9" y1="9" x2="9.01" y2="9"></line>
                    <line x1="15" y1="9" x2="15.01" y2="9"></line>
                  </svg>
                </div>
                <div className='item-text'>
                  <h4>Face ID Recognition</h4>
                  <p>Menggunakan teknologi pengenalan wajah tercanggih untuk verifikasi saat absensi.</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div className='stats-bar'>
          <div className='stat-item reveal reveal-scale delay-1'>
            <h3>0</h3>
            <p>Pengguna Aktif</p>
          </div>
          <div className='stat-item reveal reveal-scale delay-2'>
            <h3>{testimonials.length} +</h3>
            <p>Ulasan Positif</p>
          </div>
        </div>
      </section>

      {/* Features Section (Layanan Unggulan Kami) */}
      <section className='features-container' id='features'>
        <div className='section-header'>
          <h2>Layanan <span>Unggulan</span> Kami.</h2>
        </div>
        
        <div className='carousel-wrapper'>
          <button className='carousel-arrow arrow-left' onClick={handlePrev}>‹</button>
          
          <div 
            className='carousel-track' 
            style={{ 
              transform: windowWidth > 0 && windowWidth <= 1024 
                ? `translateX(calc(50% - 140px - ${activeFeatureIndex * 328}px))`
                : `translateX(calc(50% - 160px - ${activeFeatureIndex * 368}px))`,
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

      {/* Scrolling Ribbon Divider Wrapper */}
      <div className='ribbon-wrapper' id='features'>
        {/* Background Watermark Text - Starbucks Style */}
        <div className='ribbon-bg-text'>
          ABSENSI<span>CERDAS</span>
        </div>

        {/* Left Side Content */}
        <div className='ribbon-side-content left'>
          <p>Sistem cerdas yang mempermudah <br /><strong>manajemen waktu Anda.</strong></p>
          <svg className='ribbon-arrow-svg left-arrow' viewBox='0 0 100 100'>
            <path d='M10,10 Q50,10 80,50' fill='none' stroke='var(--secondary-blue)' strokeWidth='2' />
            <path d='M75,35 L80,50 L65,55' fill='none' stroke='var(--secondary-blue)' strokeWidth='2' />
          </svg>
        </div>

        {/* CSS Samsung S22 Ultra Phone Mockup in Ribbon */}
        <div className='ribbon-samsung-phone'>
          <div className='samsung-phone-body'>
            {/* Top punch-hole camera */}
            <div className='samsung-camera'></div>

            {/* Screen Content - Rotating Slideshow videnti1 to videnti12 */}
            <div className='samsung-screen-container'>
              <img 
                src={`/images/mockup/videnti${ribbonImageIndex}.jpeg`} 
                className='samsung-screen-image' 
                alt={`Videnti Slide ${ribbonImageIndex}`} 
                key={ribbonImageIndex} 
              />
            </div>
          </div>
        </div>

        {/* Right Side Content */}
        <div className='ribbon-side-content right'>
          <svg className='ribbon-arrow-svg right-arrow' viewBox='0 0 100 100'>
            <path d='M90,10 Q50,10 20,50' fill='none' stroke='var(--secondary-blue)' strokeWidth='2' />
            <path d='M25,35 L20,50 L35,55' fill='none' stroke='var(--secondary-blue)' strokeWidth='2' />
          </svg>
          <p>Keamanan berlapis dengan teknologi <br /><strong>Face Recognition & Geolokasi.</strong></p>
        </div>

        <div className='scrolling-divider'>
          <div className='ribbon-track'>
            <span>VIDENTI • VIDENTI • VIDENTI • VIDENTI • VIDENTI • VIDENTI • VIDENTI • VIDENTI • </span>
            <span>VIDENTI • VIDENTI • VIDENTI • VIDENTI • VIDENTI • VIDENTI • VIDENTI • VIDENTI • </span>
          </div>
        </div>
      </div>

      {/* Epic Mockup Grid Section */}
      <section className='epic-mockup-section'>
        <div className='epic-blend-top'></div>
        
        <div className='epic-content reveal reveal-up'>
          <h2>Dashboard Web <span style={{ color: '#f97316' }}>Tersentralisasi</span></h2>
          <p>
            Satu platform terintegrasi untuk mengelola absensi, payroll otomatis, denda sanksi, hingga bonus karyawan secara real-time.
          </p>
        </div>
        
        <div 
          ref={mockupRef}
          className={`epic-image-container ${isMockupActive ? 'active' : ''}`}
          onClick={(e) => {
            e.stopPropagation();
            setIsMockupActive(!isMockupActive);
          }}
          style={{ cursor: 'pointer' }}
        >
          <img 
            src='/videnti_epic_mockups.png' 
            alt='VIDENTI Mockup Collection' 
            className={`epic-image ${isMockupActive ? 'clicked-active' : ''}`} 
          />
        </div>

        <div className='epic-blend-bottom'></div>
      </section>

      {/* Showcase Section (Bukan Sekedar Absensi Biasa) */}
      <section className='showcase' id='about'>
        <div className='showcase-card-container reveal reveal-up'>
          <div className='showcase-collage-area reveal reveal-left delay-1'>
            <img 
              src='/videnti5.png' 
              alt='App Collage' 
              className='collage-image'
            />
          </div>
          <div className='showcase-overlay-box reveal reveal-right delay-2'>
            <h2 className='showcase-title'>Aplikasi Mobile Interaktif Bos & Karyawan</h2>
            <div className='divider-yellow'></div>
            <p className='showcase-desc'>
              <strong>Karyawan</strong> dapat melakukan absensi Face Recognition & Geolokasi yang super presisi, serta memantau slip gaji langsung dalam genggaman. 
              Sementara <strong>Bos (Admin)</strong> dapat memantau produktivitas tim, mengelola payroll otomatis, memberikan sanksi, serta menyetujui bonus secara fleksibel melalui antarmuka mobile yang sangat modern dan dinamis.
            </p>
            <Link href='/login' className='btn-showcase'>Mulai Sekarang</Link>
          </div>
        </div>
      </section>

      {/* Testimonials Section (Replacing Steps) */}
      <section className='testimonials-section' id='testimonials'>
        <div className='section-header reveal reveal-up'>
          <h2>Apa Kata <span>Mereka?</span></h2>
          <button className='btn-add-testi' onClick={() => setShowTestimonialModal(true)}>Beri Ulasan Kami</button>
        </div>

        <div className='testimonials-marquee-wrapper'>
          {/* Row 1: Moves Left */}
          <div className='marquee-row row-left'>
            <div className='marquee-content'>
              {(() => {
                const displayData = testimonials;
                const tripled = [...displayData, ...displayData, ...displayData];

                
return tripled.map((testi, idx) => {
                  const originalIndex = idx % displayData.length;

                  const avatarSrc = testi.photo_url 
                    ? `${process.env.NEXT_PUBLIC_API_URL?.split('/api')[0]}${testi.photo_url}`
                    : `/images/avatars/${(displayData.slice(0, originalIndex).filter((t: any) => !t.photo_url).length % 8) + 1}.png`;

                  return (
                    <div key={idx} className='testimonial-card'>
                      <div className='testi-user'>
                        <img 
                          src={avatarSrc} 
                          className='testi-avatar' 
                          alt={testi.name} 
                        />
                        <div className='testi-meta'>
                          <h4>{testi.name}</h4>
                          <div className='testi-stars'>
                            {Array.from({ length: testi.rating }).map((_, i) => <span key={i}>⭐</span>)}
                          </div>
                        </div>
                      </div>
                      <p className='testi-desc'>{testi.description}</p>
                    </div>
                  );
                });
              })()}
            </div>
          </div>

          {/* Row 2: Moves Right */}
          <div className='marquee-row row-right'>
            <div className='marquee-content'>
              {(() => {
                const displayData = testimonials;
                const tripled = [...displayData, ...displayData, ...displayData];
                const reversed = [...tripled].reverse();
                
                return reversed.map((testi, idx) => {
                  const L = displayData.length;
                  const originalIndex = (L * 3 - 1 - idx) % L;

                  const avatarSrc = testi.photo_url 
                    ? `${process.env.NEXT_PUBLIC_API_URL?.split('/api')[0]}${testi.photo_url}`
                    : `/images/avatars/${(displayData.slice(0, originalIndex).filter((t: any) => !t.photo_url).length % 8) + 1}.png`;

                  return (
                    <div key={idx} className='testimonial-card'>
                      <div className='testi-user'>
                        <img 
                          src={avatarSrc} 
                          className='testi-avatar' 
                          alt={testi.name} 
                        />
                        <div className='testi-meta'>
                          <h4>{testi.name}</h4>
                          <div className='testi-stars'>
                            {Array.from({ length: testi.rating }).map((_, i) => <span key={i}>⭐</span>)}
                          </div>
                        </div>
                      </div>
                      <p className='testi-desc'>{testi.description}</p>
                    </div>
                  );
                });
              })()}
            </div>
          </div>
        </div>

        {/* Testimonial Submission Modal */}
        {showTestimonialModal && (
          <div className='modal-overlay'>
            <div className='testi-modal'>
              <div className='modal-header'>
                <h3>Kirim Testimoni</h3>
                <button onClick={() => setShowTestimonialModal(false)}>✕</button>
              </div>
              <form onSubmit={handleTestiSubmit}>
                <div className='input-group'>
                  <label>Nama Lengkap</label>
                  <input type='text' required placeholder='Nama anda...' value={testiForm.name} onChange={e => setTestiForm({...testiForm, name: e.target.value})} />
                </div>
                <div className='input-group'>
                  <label>Rating Kepuasan Anda *</label>
                  <div className='star-rating-input'>
                    {[1, 2, 3, 4, 5].map((star) => (
                      <button
                        key={star}
                        type='button'
                        className={`star-btn ${star <= testiForm.rating ? 'active' : ''}`}
                        onClick={() => setTestiForm({ ...testiForm, rating: star })}
                      >
                        ★
                      </button>
                    ))}
                  </div>
                  {testiForm.rating > 0 && <span className='rating-label-hint'>{testiForm.rating} Bintang</span>}
                </div>
                <div className='input-group'>
                  <label>Pesan Ulasan</label>
                  <textarea required rows={4} placeholder='Tulis ulasan anda...' value={testiForm.description} onChange={e => setTestiForm({...testiForm, description: e.target.value})}></textarea>
                </div>
                <div className='input-group'>
                  <label>Upload Foto Profil {isUploading && '(Sabar sedang mengupload...)'}</label>
                  <input type='file' accept='image/*' onChange={handleFileUpload} />
                  {testiForm.photo_url && !isUploading && (
                    <p style={{ color: '#9fe811', fontSize: '0.8rem', marginTop: '0.5rem' }}>✓ Foto berhasil diunggah!</p>
                  )}
                </div>
                <button 
                  type='submit' 
                  className='btn-submit-testi' 
                  disabled={isUploading}
                  style={{ opacity: isUploading ? 0.5 : 1 }}
                >
                  {isUploading ? 'Menunggu Upload...' : 'Kirim Sekarang'}
                </button>
              </form>
            </div>
          </div>
        )}
      </section>



      {/* New Astra-Style Footer Section */}
      <section className='astra-footer' id='contact'>
        {!showContactForm ? (
          <div className='footer-main-content'>
            <div className='footer-visual reveal reveal-scale'>
              <img src='/images/videnti.png' alt='VIDENTI Logo' className='footer-logo-img' />
            </div>
            <div className='footer-text-content'>
              <h2 className='footer-headline reveal reveal-up'>Terhubung dengan Kami</h2>
              <p className='footer-subheadline reveal reveal-up delay-1'>
                Jadilah bagian dari komunitas kami yang bersemangat dan saling terhubung dalam visi masa depan yang berkelanjutan.
              </p>
              
              <div className='footer-social-row reveal reveal-up delay-2'>
                <a href='https://www.instagram.com/oktovaaaaa' target='_blank' rel='noopener noreferrer' className='social-icon'>
                  <img src='https://img.icons8.com/color/48/instagram-new.png' alt='Instagram' />
                </a>
                <a href='https://wa.me/62881080811110' target='_blank' rel='noopener noreferrer' className='social-icon'>
                  <img src='https://img.icons8.com/color/48/whatsapp.png' alt='WhatsApp' />
                </a>
                <a href='mailto:videntiiii@gmail.com' className='social-icon'>
                  <img src='https://img.icons8.com/color/48/gmail-new.png' alt='Email' />
                </a>
                <a href='https://www.oktovaaaaa.id/' target='_blank' rel='noopener noreferrer' className='social-icon'>
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
                <a href='https://oktovaaaaa.cloud' target='_blank' rel='noopener noreferrer' style={{ fontWeight: '700', color: '#fff' }}>
                  © {new Date().getFullYear()} PA 2 Kelompok 2
                </a>
                <span>•</span>
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
                <img src='/images/videnti.png' alt='Logo' width={48} height={48} />
                <span className='form-brand-name'>VIDENTI</span>
              </div>
              <button className='btn-close-form' onClick={() => setShowContactForm(false)}>✕ Tutup</button>
            </div>
            
            <div className='form-layout-grid'>
              <div className='form-info-side'>
                <h2 className='form-title'>Butuh Bantuan? Silahkan Hubungi Tim</h2>
                <div className='form-highlight-text'>VIDENTI</div>
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
