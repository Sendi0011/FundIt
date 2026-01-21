"use client";

import { useAccount } from "wagmi";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { WalletButton } from "@/components/wallet-button";
import { Shield } from "lucide-react";

export function ConnectWalletGuard({ children }: { children: React.ReactNode }) {
  const { isConnected, isConnecting } = useAccount();

  if (isConnecting) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-pulse text-center">
          <Shield className="h-12 w-12 mx-auto mb-4 text-primary" />
          <p className="text-muted-foreground">Connecting...</p>
        </div>
      </div>
    );
  }

  if (!isConnected) {
    return (
      <div className="flex items-center justify-center min-h-screen p-4">
        <Card className="max-w-md w-full">
          <CardHeader className="text-center">
            <div className="mx-auto mb-4 w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center">
              <Shield className="h-6 w-6 text-primary" />
            </div>
            <CardTitle>Connect Your Wallet</CardTitle>
            <CardDescription>
              Connect your wallet to access FUNDit and start saving automatically
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2 text-sm text-muted-foreground">
              <div className="flex items-start gap-2">
                <span className="text-primary">✓</span>
                <span>Secure, non-custodial savings on Base</span>
              </div>
              <div className="flex items-start gap-2">
                <span className="text-primary">✓</span>
                <span>Automated Spend & Save feature</span>
              </div>
              <div className="flex items-start gap-2">
                <span className="text-primary">✓</span>
                <span>Full control of your funds</span>
              </div>
            </div>
            
            <div className="pt-4">
              <WalletButton />
            </div>

            <p className="text-xs text-center text-muted-foreground">
              By connecting, you agree to our Terms of Service
            </p>
          </CardContent>
        </Card>
      </div>
    );
  }

  return <>{children}</>;
}