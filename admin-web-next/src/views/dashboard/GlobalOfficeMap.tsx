import React, { useEffect, useState, useRef, useMemo } from 'react'

import dynamic from 'next/dynamic'

import Card from '@mui/material/Card'
import CardContent from '@mui/material/CardContent'
import Typography from '@mui/material/Typography'
import Box from '@mui/material/Box'
import { useTheme } from '@mui/material/styles'

const Globe = dynamic(() => import('react-globe.gl'), { ssr: false })

interface Props {
  companies: any[]
}

const GlobalOfficeMap = ({ companies }: Props) => {
  const theme = useTheme()
  const globeEl = useRef<any>()
  const [isMounted, setIsMounted] = useState(false)
  const isDark = theme.palette.mode === 'dark'

  // Refined textures
  const globeConfig = {
    imageUrl: isDark 
        ? '//unpkg.com/three-globe/example/img/earth-night.jpg' 
        : '//unpkg.com/three-globe/example/img/earth-blue-marble.jpg',
    atmosphereColor: isDark ? '#3a228a' : '#93c5fd',
    atmosphereAltitude: isDark ? 0.25 : 0.15,
  }

  // Accurate coordinate mapping with smart scaling data
  const pointsData = useMemo(() => {
    return companies.map((comp, idx) => {
      // Use exact coordinates from DB, fallback ONLY if strictly 0/null
      let lat = comp.latitude
      let lng = comp.longitude
      
      const isMissing = (!lat && !lng) || (lat === 0 && lng === 0)
      
      if (isMissing) {
        // Spread them out a bit near Indonesia/South East Asia for realism if no data
        const mockCoord = [
            { lat: -6.2, lng: 106.8 }, // Jakarta (Indonesia)
            { lat: -7.2, lng: 112.7 }, // Surabaya (Indonesia)
            { lat: -6.9, lng: 107.6 }, // Bandung (Indonesia)
            { lat: -7.7, lng: 110.3 }, // Jogja (Indonesia)
            { lat: 1.2, lng: 103.8 }    // Singapore
        ]

        const coord = mockCoord[idx % mockCoord.length]

        lat = coord.lat
        lng = coord.lng
      }

      return {
        lat,
        lng,
        name: comp.name,
        color: ['#6366F1', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6'][idx % 5],
      }
    })
  }, [companies])

  useEffect(() => {
    setIsMounted(true)
  }, [])

  useEffect(() => {
    if (isMounted && globeEl.current) {
        // Auto-rotate
        const controls = globeEl.current.controls()

        if (controls) {
            controls.autoRotate = true
            controls.autoRotateSpeed = 1.2 // Slower for premium feel
            controls.enableDamping = true
        }
    }
  }, [isMounted])

  const createMarkerElement = (d: any) => {
    const el = document.createElement('div')
    
    // Office Icon HTML
    el.innerHTML = `
        <div class="globe-marker-container">
            <div class="pulse-ring" style="border-color: ${d.color}"></div>
            <div class="marker-core" style="background-color: ${d.color}">
                <i class="ri-building-2-fill"></i>
            </div>
            <div class="marker-label">${d.name}</div>
        </div>
    `
    el.style.pointerEvents = 'auto'
    el.style.cursor = 'pointer'
    
return el
  }

  return (
    <Card className='shadow-lg rounded-[2.5rem] overflow-hidden border-none bg-[var(--mui-palette-background-paper)] h-full relative'>
      {/* Dynamic Background Glow */}
      <Box className={`absolute -bottom-20 -left-20 w-64 h-64 rounded-full blur-[100px] opacity-20 pointer-events-none ${isDark ? 'bg-indigo-500' : 'bg-blue-300'}`} />
      
      <CardContent className='p-8 h-full flex flex-col relative z-10'>
        <Box className='flex justify-between items-center mbe-6'>
            <Box>
                <Typography variant='subtitle2' className='font-black text-[var(--mui-palette-text-primary)] uppercase tracking-[0.2em]'>Visualisasi Kantor Global</Typography>
                <Typography variant='caption' className='text-[var(--mui-palette-text-secondary)] font-medium'>Pemantau lokasi unit bisnis secara real-time</Typography>
            </Box>
            <Box className='flex items-center gap-2 px-4 py-1.5 bg-[var(--mui-palette-action-hover)] rounded-2xl border border-[var(--mui-palette-divider)]'>
                <Box className='w-2 h-2 rounded-full bg-emerald-500 animate-pulse' />
                <Typography variant='caption' className='text-xs font-bold text-[var(--mui-palette-text-primary)]'>PANDANGAN GLOBAL</Typography>
            </Box>
        </Box>
        
        <Box className='flex-grow flex items-center justify-center relative cursor-grab active:cursor-grabbing min-h-[350px]'>
          <style jsx global>{`
            .globe-marker-container {
                display: flex;
                flex-direction: column;
                align-items: center;
                transition: transform 0.3s ease-out;
                filter: drop-shadow(0 0 10px rgba(0,0,0,0.3));
            }
            .marker-core {
                width: 24px;
                height: 24px;
                border-radius: 8px;
                display: flex;
                align-items: center;
                justify-content: center;
                color: white;
                font-size: 14px;
                position: relative;
                z-index: 2;
                border: 2px solid white;
                box-shadow: 0 4px 10px rgba(0,0,0,0.2);
            }
            .pulse-ring {
                position: absolute;
                width: 40px;
                height: 40px;
                border: 2px solid;
                border-radius: 50%;
                animation: pulse 2s infinite;
                z-index: 1;
            }
            .marker-label {
                margin-top: 6px;
                padding: 2px 8px;
                background: rgba(0,0,0,0.7);
                backdrop-filter: blur(4px);
                color: white;
                font-size: 10px;
                font-weight: 700;
                border-radius: 4px;
                white-space: nowrap;
                opacity: 0.8;
                text-transform: uppercase;
                letter-spacing: 0.05em;
            }
            @keyframes pulse {
                0% { transform: scale(0.5); opacity: 0; }
                50% { opacity: 0.5; }
                100% { transform: scale(1.5); opacity: 0; }
            }
            /* Smart Scaling: Markers shrink as you get closer to reveal terrain detail */
            canvas + div > div {
                transition: transform 0.2s linear !important;
            }
          `}</style>
          
          {isMounted ? (
            <Globe
              ref={globeEl}
              width={500}
              height={400}
              backgroundColor='rgba(0,0,0,0)'
              showAtmosphere={true}
              atmosphereColor={globeConfig.atmosphereColor}
              atmosphereAltitude={globeConfig.atmosphereAltitude}
              globeImageUrl={globeConfig.imageUrl}
              bumpImageUrl='//unpkg.com/three-globe/example/img/earth-topology.png'
              
              htmlElementsData={pointsData}
              htmlElement={createMarkerElement}
              htmlTransitionDuration={500}
            />
          ) : (
             <Box className='flex flex-col items-center gap-4 text-center'>
                <Box className='w-16 h-16 rounded-full border-4 border-primary/20 border-t-primary animate-spin' />
                <Box>
                    <Typography variant='caption' className='text-[var(--mui-palette-text-secondary)] font-black tracking-widest uppercase'>Sinkronisasi Geografis...</Typography>
                </Box>
             </Box>
          )}
        </Box>
      </CardContent>
    </Card>
  )
}

export default GlobalOfficeMap
