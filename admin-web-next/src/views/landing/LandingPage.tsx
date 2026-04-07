'use client'

import React, { useState, useEffect } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { googleLogout } from '@react-oauth/google'
import './landing.css'

// Image path as generated earlier
const HERO_IMAGE = '/attendance_app_hero_1775490992311.png'
const FACE_ID_ICON = 'https://img.icons8.com/fluency/240/facial-recognition.png'
const REALTIME_ICON = 'https://img.icons8.com/fluency/240/clock.png'
const ANALYTICS_ICON = 'https://img.icons8.com/fluency/240/bar-chart.png'
const RIBBON_PERSON_IMAGE = '/mockupvidenti1.png'
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
  const [showTestimonialModal, setShowTestimonialModal] = useState(false)
  const [testimonials, setTestimonials] = useState<any[]>([])
  const [isUploading, setIsUploading] = useState(false)
  const [isScrolled, setIsScrolled] = useState(false)
  const [isMenuOpen, setIsMenuOpen] = useState(false)
  const [windowWidth, setWindowWidth] = useState(0)

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
    rating: 5,
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
        alert('Gagal mengupload foto')
      }
    } catch (err) { alert('Terjadi kesalahan saat upload') }
    setIsUploading(false)
  }

  const handleTestiSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (isUploading) {
      alert('Tunggu hingga foto selesai diupload!')
      return
    }
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/testimonials`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(testiForm)
      })
      if (res.ok) {
        alert('Testimoni berhasil dikirim!')
        setShowTestimonialModal(false)
        fetchTestimonials()
      }
    } catch (err) { alert('Gagal mengirim testimoni') }
  }

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
          <li><a href='#how-it-works'>Cara Kerja</a></li>
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
            <Link href='/login' className='login-btn'>Login Admin</Link>
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
            <li><a href='#how-it-works' onClick={toggleMenu}>Cara Kerja</a></li>
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
                <Link href='/login' className='login-btn' onClick={toggleMenu}>Login Admin</Link>
              </div>
            )}
          </div>
        </div>

        {/* Backdrop for Mobile Sidebar */}
        {isMenuOpen && <div className='menu-overlay' onClick={toggleMenu}></div>}
      </nav>

      {/* Hero Section */}
      <section className='hero' id='home'>
        <div className='hero-content'>
          <p className='hero-subtitle'>Smart Attendance System</p>
          <h1 className='hero-title'>The Best Attendance For You.</h1>
          <p className='hero-description'>
            VIDENTI adalah sistem absensi modern berbasis Face Recognition yang cepat, akurat, dan aman. 
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
          SMART<span>ATTENDANCE</span>
        </div>

        {/* Left Side Content */}
        <div className='ribbon-side-content left'>
          <p>Sistem cerdas yang mempermudah <br /><strong>manajemen waktu Anda.</strong></p>
          <svg className='ribbon-arrow-svg left-arrow' viewBox='0 0 100 100'>
            <path d='M10,10 Q50,10 80,50' fill='none' stroke='var(--secondary-blue)' strokeWidth='2' />
            <path d='M75,35 L80,50 L65,55' fill='none' stroke='var(--secondary-blue)' strokeWidth='2' />
          </svg>
        </div>

        {/* Phone Mockup (Subject) */}
        <img src={RIBBON_PERSON_IMAGE} className='ribbon-person' alt='Ribbon User' />

        {/* Right Side Content */}
        <div className='ribbon-side-content right'>
          <svg className='ribbon-arrow-svg right-arrow' viewBox='0 0 100 100'>
            <path d='M90,10 Q50,10 20,50' fill='none' stroke='var(--secondary-blue)' strokeWidth='2' />
            <path d='M25,35 L20,50 L35,55' fill='none' stroke='var(--secondary-blue)' strokeWidth='2' />
          </svg>
          <p>Keamanan berlapis dengan teknologi <br /><strong>Face Recognition terkini.</strong></p>
        </div>

        <div className='scrolling-divider'>
          <div className='ribbon-track'>
            <span>VIDENTI • VIDENTI • VIDENTI • VIDENTI • VIDENTI • VIDENTI • VIDENTI • VIDENTI • </span>
            <span>VIDENTI • VIDENTI • VIDENTI • VIDENTI • VIDENTI • VIDENTI • VIDENTI • VIDENTI • </span>
          </div>
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
              VIDENTI dirancang untuk memberikan pengalaman terbaik bagi admin maupun karyawan. 
              Dengan integrasi cloud, data Anda selalu aman dan dapat diakses dari mana saja tanpa kendala.
            </p>
            <a href='#contact' className='btn-showcase'>Mulai sekarang →</a>
          </div>
        </div>
      </section>

      {/* Testimonials Section (Replacing Steps) */}
      <section className='testimonials-section' id='testimonials'>
        <div className='section-header'>
          <h2>Apa Kata <span>Mereka?</span></h2>
          <button className='btn-add-testi' onClick={() => setShowTestimonialModal(true)}>+ Beri Testimoni</button>
        </div>

        <div className='testimonials-marquee-wrapper'>
          {/* Row 1: Moves Left */}
          <div className='marquee-row row-left'>
            <div className='marquee-content'>
              {(() => {
                const displayData = testimonials.length > 0 ? testimonials : [
                  { name: 'Budi Santoso', description: 'VIDENTI sangat memudahkan manajemen absensi di pabrik kami. Sangat akurat!', rating: 5 },
                  { name: 'Siti Aminah', description: 'Fitur payroll otomatisnya menghemat waktu HRD kami hingga 70%. Luar biasa!', rating: 5 },
                  { name: 'Andi Wijaya', description: 'Topik pengenalan wajahnya sangat cepat, bahkan dalam kondisi minim cahaya.', rating: 4 },
                  { name: 'Dewi Lestari', description: 'Dashboard admin sangat intuitif dan mudah dipahami oleh staf baru.', rating: 5 }
                ];
                const tripled = [...displayData, ...displayData, ...displayData];
                return tripled.map((testi, idx) => {
                  const originalIndex = idx % displayData.length;
                  const avatarSrc = testi.photo_url 
                    ? `${process.env.NEXT_PUBLIC_API_URL}${testi.photo_url}` 
                    : `https://i.pravatar.cc/150?u=${testi.name}`;

                  return (
                    <div key={idx} className='testimonial-card'>
                      <div className='testi-quote'>“</div>
                      <p className='testi-desc'>{testi.description}</p>
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
                const displayData = testimonials.length > 0 ? testimonials : [
                  { name: 'Joko Widodo', description: 'Implementasi gampang dan tim supportnya sangat responsif membantu.', rating: 5 },
                  { name: 'Rina Marlina', description: 'Karyawan saya senang karena bisa absensi langsung dari HP masing-masing.', rating: 5 },
                  { name: 'Anton Setiawan', description: 'Analitiknya sangat detail, membantu saya memantau produktivitas tim.', rating: 4 },
                  { name: 'Maya Putri', description: 'Harga berlangganannya sangat terjangkau dibanding kompetitor lain.', rating: 5 }
                ];
                const tripled = [...displayData, ...displayData, ...displayData];
                const reversed = [...tripled].reverse();
                
                return reversed.map((testi, idx) => {
                  const L = displayData.length;
                  const originalIndex = (L * 3 - 1 - idx) % L;
                  const avatarSrc = testi.photo_url 
                    ? `${process.env.NEXT_PUBLIC_API_URL}${testi.photo_url}` 
                    : `https://i.pravatar.cc/155?u=${testi.name}`;

                  return (
                    <div key={idx} className='testimonial-card'>
                      <div className='testi-quote'>“</div>
                      <p className='testi-desc'>{testi.description}</p>
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
                  <input type='text' required placeholder='Nama anda...' onChange={e => setTestiForm({...testiForm, name: e.target.value})} />
                </div>
                <div className='input-group'>
                  <label>Rating (1-5)</label>
                  <select onChange={e => setTestiForm({...testiForm, rating: parseInt(e.target.value)})}>
                    <option value='5'>⭐⭐⭐⭐⭐ (5)</option>
                    <option value='4'>⭐⭐⭐⭐ (4)</option>
                    <option value='3'>⭐⭐⭐ (3)</option>
                    <option value='2'>⭐⭐ (2)</option>
                    <option value='1'>⭐ (1)</option>
                  </select>
                </div>
                <div className='input-group'>
                  <label>Pesan Ulasan</label>
                  <textarea required rows={4} placeholder='Tulis ulasan anda...' onChange={e => setTestiForm({...testiForm, description: e.target.value})}></textarea>
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
                <a href='mailto:support@videnti.com' className='social-icon'>
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
                <a href='https://oktovaaaaa.cloud' target='_blank' rel='noopener noreferrer' style={{ fontWeight: '700', color: '#fff' }}>
                  © {new Date().getFullYear()} Oktovaaaaa
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
              <button className='btn-close-form' onClick={() => setShowContactForm(false)}>✕ Close</button>
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
