"use client"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { TrendingUp, RefreshCw, Eye, EyeOff } from "lucide-react"
import { useState } from "react"

interface TotalSavedCardProps {
  totalAmount: number
  monthlyIncrease: number
  onRefresh?: () => void
  isRefreshing?: boolean
}

export function TotalSavedCard({ totalAmount, monthlyIncrease, onRefresh, isRefreshing }: TotalSavedCardProps) {
  const [isVisible, setIsVisible] = useState(true)
  const [showRefreshed, setShowRefreshed] = useState(false)

  const handleRefresh = async () => {
    if (onRefresh) {
      await onRefresh()
      setShowRefreshed(true)
      setTimeout(() => setShowRefreshed(false), 2000) // Hide after 2 seconds
    }
  }

  return (
    <Card className="bg-gradient-to-br from-primary via-primary to-secondary relative overflow-hidden">
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle className="text-primary-foreground">Total Saved</CardTitle>
        <div className="flex items-center gap-2">
          <Button
            variant="ghost"
            size="sm"
            onClick={() => setIsVisible(!isVisible)}
            className="text-primary-foreground hover:bg-primary-foreground/20 h-8 w-8 p-0"
          >
            {isVisible ? <Eye className="h-4 w-4" /> : <EyeOff className="h-4 w-4" />}
          </Button>
          <Button
            variant="ghost"
            size="sm"
            onClick={handleRefresh}
            disabled={isRefreshing}
            className="text-primary-foreground hover:bg-primary-foreground/20 h-8 w-8 p-0"
          >
            <RefreshCw className={`h-4 w-4 transition-transform duration-500 ${isRefreshing ? 'animate-spin' : ''}`} />
          </Button>
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="space-y-1 relative">
          <div className="text-3xl sm:text-5xl font-bold text-primary-foreground">
            {isVisible 
              ? totalAmount.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })
              : "••••••"
            }
          </div>
          
          {/* Balance Refreshed Indicator */}
          {showRefreshed && (
            <div className="absolute inset-0 flex items-center justify-center bg-primary-foreground/10 rounded-lg animate-fade-in-out">
              <div className="flex items-center gap-2 text-primary-foreground font-medium">
                <RefreshCw className="h-4 w-4" />
                <span className="text-sm">Balance Refreshed!</span>
              </div>
            </div>
          )}
          
          <p className="text-sm text-primary-foreground/80">USDC on Base</p>
        </div>

        <div className="flex items-center gap-2 text-primary-foreground/90">
          <TrendingUp className="h-4 w-4" />
          <span className="text-sm font-medium">
            {isVisible ? `+$${monthlyIncrease.toFixed(2)} this month` : "+$•••• this month"}
          </span>
        </div>
      </CardContent>
      
      <style jsx>{`
        @keyframes fade-in-out {
          0% { opacity: 0; transform: scale(0.9); }
          50% { opacity: 1; transform: scale(1); }
          100% { opacity: 0; transform: scale(0.9); }
        }
        .animate-fade-in-out {
          animation: fade-in-out 2s ease-in-out;
        }
      `}</style>
    </Card>
  )
}
