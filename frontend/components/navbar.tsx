"use client"
import Link from "next/link"
import { History } from "lucide-react"
import { Button } from "./ui/button"
import { WalletButton } from "@/components/wallet-button";

export function Navbar() {
  return (
    <nav className="border-b border-border bg-background sticky top-0 z-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
        <Link href="/" className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-full bg-gradient-to-br from-primary to-accent flex items-center justify-center">
            <span className="text-primary-foreground font-bold text-lg">₣</span>
          </div>
          <span className="font-bold text-lg text-foreground hidden sm:block">FUNDit</span>
        </Link>

        <div className="flex items-center gap-4">
          <Link href="/dashboard" className="text-sm font-medium hover:text-primary transition-colors hidden md:block">
            Dashboard
          </Link>
          <Link href="/activity">
            <Button variant="ghost" size="sm" className="gap-2 hidden sm:flex">
              <History className="h-4 w-4" />
              <span className="hidden md:inline">Activity</span>
            </Button>
          </Link>
          <WalletButton />
        </div>
      </div>
    </nav>
  )
}
