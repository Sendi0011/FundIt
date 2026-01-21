"use client"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Zap, Lock, TrendingUp } from "lucide-react"

interface WelcomeScreenProps {
  onCreateVault: () => void
  isCreating?: boolean
}

export function WelcomeScreen({ onCreateVault, isCreating }: WelcomeScreenProps) {
  return (
    <div className="min-h-screen bg-linear-to-br from-background via-background to-background flex items-center justify-center p-4">
      <Card className="w-full max-w-2xl shadow-xl">
        <CardHeader className="text-center space-y-4">
          <div className="w-16 h-16 rounded-full bg-linear-to-br from-primary to-accent mx-auto flex items-center justify-center">
            <span className="text-primary-foreground font-bold text-3xl">₣</span>
          </div>
          <CardTitle className="text-4xl">Welcome to FUNDit</CardTitle>
          <CardDescription className="text-lg">Secure, automated savings on Base blockchain</CardDescription>
        </CardHeader>

        <CardContent className="space-y-8">
          <div className="grid md:grid-cols-3 gap-4 mb-8">
            <div className="flex flex-col items-center text-center space-y-2">
              <div className="w-12 h-12 rounded-lg bg-blue-100 dark:bg-blue-950 flex items-center justify-center">
                <Zap className="h-6 w-6 text-accent" />
              </div>
              <h3 className="font-semibold">Effortless</h3>
              <p className="text-sm text-muted-foreground">Save without thinking</p>
            </div>

            <div className="flex flex-col items-center text-center space-y-2">
              <div className="w-12 h-12 rounded-lg bg-blue-100 dark:bg-blue-950 flex items-center justify-center">
                <Lock className="h-6 w-6 text-accent" />
              </div>
              <h3 className="font-semibold">Secure</h3>
              <p className="text-sm text-muted-foreground">Non-custodial & capped</p>
            </div>

            <div className="flex flex-col items-center text-center space-y-2">
              <div className="w-12 h-12 rounded-lg bg-blue-100 dark:bg-blue-950 flex items-center justify-center">
                <TrendingUp className="h-6 w-6 text-accent" />
              </div>
              <h3 className="font-semibold">Transparent</h3>
              <p className="text-sm text-muted-foreground">See every transaction</p>
            </div>
          </div>

          <div className="space-y-4">
            <p className="text-center text-foreground">Create your vault once, then choose your savings strategy:</p>
            <ul className="space-y-2 text-sm">
              <li className="flex items-center gap-2">
                <span className="w-2 h-2 rounded-full bg-primary" />
                <span>Target Savings - Save towards a specific goal</span>
              </li>
              <li className="flex items-center gap-2">
                <span className="w-2 h-2 rounded-full bg-primary" />
                <span>Fixed Savings - Lock funds for a set duration</span>
              </li>
              <li className="flex items-center gap-2">
                <span className="w-2 h-2 rounded-full bg-primary" />
                <span>Spend & Save - Auto-save on every transaction</span>
              </li>
            </ul>
          </div>

          <Button onClick={onCreateVault} disabled={isCreating} size="lg" className="w-full">
            {isCreating ? "Creating Vault..." : "Create My FUNDit Vault"}
          </Button>

          <p className="text-xs text-center text-muted-foreground">
            Your funds are always in your control. You can withdraw anytime.
          </p>
        </CardContent>
      </Card>
    </div>
  )
}
