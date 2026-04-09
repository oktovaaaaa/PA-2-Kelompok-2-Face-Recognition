// src/views/operasional/MapComponent.tsx
'use client'

import { useEffect } from 'react'
import { MapContainer, TileLayer, Marker, Circle, useMap } from 'react-leaflet'
import L from 'leaflet'

// Leaflet Icon Fix (markers not showing by default in React-Leaflet)
const DefaultIcon = L.icon({
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
})

L.Marker.prototype.options.icon = DefaultIcon

const MapUpdater = ({ center }: { center: [number, number] }) => {
  const map = useMap()
  useEffect(() => {
    if (!isNaN(center[0]) && !isNaN(center[1])) {
      map.setView(center)
    }
  }, [center, map])
  return null
}

interface MapComponentProps {
  latitude: number
  longitude: number
  radius: number
  onLocationChange: (lat: number, lon: number) => void
}

const MapComponent = ({ latitude, longitude, radius, onLocationChange }: MapComponentProps) => {
  return (
    <MapContainer 
      center={[latitude, longitude]} 
      zoom={15} 
      style={{ height: '100%', width: '100%' }}
      scrollWheelZoom={true}
    >
      <TileLayer
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
      />
      <MapUpdater center={[latitude, longitude]} />
      <Marker 
        position={[latitude, longitude]}
        draggable={true}
        eventHandlers={{
          dragend: (e: any) => {
            const marker = e.target
            const position = marker.getLatLng()
            onLocationChange(position.lat, position.lng)
          },
        }}
      />
      <Circle 
        center={[latitude, longitude]} 
        radius={radius}
        pathOptions={{ color: '#2563EB', fillColor: '#2563EB', fillOpacity: 0.2 }}
      />
    </MapContainer>
  )
}

export default MapComponent
