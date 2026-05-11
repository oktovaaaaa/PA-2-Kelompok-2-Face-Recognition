'use client'

import React, { useRef, useEffect } from 'react'

interface OTPInputProps {
  value: string
  onChange: (value: string) => void
  length?: number
  disabled?: boolean
}

const OTPInput: React.FC<OTPInputProps> = ({ value, onChange, length = 6, disabled = false }) => {
  const inputsRef = useRef<(HTMLInputElement | null)[]>([])

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>, index: number) => {
    const val = e.target.value
    if (isNaN(Number(val))) return

    const newOTP = value.split('')
    newOTP[index] = val.substring(val.length - 1)
    const combinedOTP = newOTP.join('')
    onChange(combinedOTP)

    // Move to next input if value is entered
    if (val && index < length - 1) {
      inputsRef.current[index + 1]?.focus()
    }
  }

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>, index: number) => {
    if (e.key === 'Backspace' && !value[index] && index > 0) {
      inputsRef.current[index - 1]?.focus()
    }
  }

  const handlePaste = (e: React.ClipboardEvent) => {
    e.preventDefault()
    const pastedData = e.clipboardData.getData('text').slice(0, length)
    if (isNaN(Number(pastedData))) return
    onChange(pastedData)
  }

  return (
    <div className='flex gap-2 justify-center items-center'>
      {Array.from({ length }).map((_, index) => (
        <input
          key={index}
          ref={(el) => (inputsRef.current[index] = el)}
          type='text'
          inputMode='numeric'
          maxLength={1}
          value={value[index] || ''}
          onChange={(e) => handleChange(e, index)}
          onKeyDown={(e) => handleKeyDown(e, index)}
          onPaste={handlePaste}
          disabled={disabled}
          className='w-11 h-11 md:w-12 md:h-12 text-center text-xl font-black rounded-xl border-2 border-[#E2E8F0] bg-[#F8FAFC] text-[#0F172A] focus:border-[#2563EB] focus:bg-white outline-none transition-all disabled:opacity-50'
        />
      ))}
    </div>
  )
}

export default OTPInput
