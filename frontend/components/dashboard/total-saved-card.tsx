"use client"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { TrendingUp } from "lucide-react"

interface TotalSavedCardProps {
  totalAmount: number
  monthlyIncrease: number
}

export function TotalSavedCard({ totalAmount, monthlyIncrease }: TotalSavedCardProps) {
  return (
    <Card className="bg-linear-to-br from-primary via-primary to-secondary">
      <CardHeader>
        <CardTitle className="text-primary-foreground">Total Saved</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="space-y-1">
          <div className="text-5xl font-bold text-primary-foreground">
            {totalAmount.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
          </div>
          <p className="text-sm text-primary-foreground/80">USDC on Base</p>
        </div>

        <div className="flex items-center gap-2 text-primary-foreground/90">
          <TrendingUp className="h-4 w-4" />
          <span className="text-sm font-medium">+${monthlyIncrease.toFixed(2)} this month</span>
        </div>
      </CardContent>
    </Card>
  )
}
