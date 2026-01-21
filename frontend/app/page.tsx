"use client"

import { Navbar } from "@/components/navbar"
import { WelcomeScreen } from "@/components/onboarding/welcome-screen"
import { useState } from "react"

export default function Home() {
  const [vaultCreated, setVaultCreated] = useState(false)

  if (!vaultCreated) {
    return (
      <>
        <Navbar />
        <WelcomeScreen onCreateVault={() => setVaultCreated(true)} isCreating={false} />
      </>
    )
  }

  // Redirect to dashboard after vault creation
  if (typeof window !== "undefined") {
    window.location.href = "/dashboard"
  }

  return (
    <>
      <Navbar />
      <div className="min-h-screen bg-linear-to-b from-background to-background/50 flex items-center justify-center">
        <div className="text-center">
          <p className="text-muted-foreground">Redirecting to dashboard...</p>
        </div>
      </div>
    </>
  )
}
