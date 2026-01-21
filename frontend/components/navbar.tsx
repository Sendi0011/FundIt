"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { WalletButton } from "@/components/wallet-button";
import { Shield, LayoutDashboard, Activity, Menu, Wallet, Network } from "lucide-react";
import { cn } from "@/lib/utils";
import { useAccount, useChainId } from "wagmi";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { useState } from "react";
import { ConnectButton } from "@rainbow-me/rainbowkit";

export function Navbar() {
  const pathname = usePathname();
  const { isConnected } = useAccount();
  const chainId = useChainId();
  const [isOpen, setIsOpen] = useState(false);

  const isTestnet = chainId === 84532;

  const routes = [
    {
      href: "/dashboard",
      label: "Dashboard",
      icon: LayoutDashboard,
      active: pathname === "/dashboard",
    },
    {
      href: "/activity",
      label: "Activity",
      icon: Activity,
      active: pathname === "/activity",
    },
  ];

  return (
    <nav className="sticky top-0 z-50 border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex h-16 items-center justify-between">
          {/* Logo */}
          <Link href="/" className="flex items-center gap-2 font-semibold flex-shrink-0">
            <Shield className="h-5 w-5 sm:h-6 sm:w-6 text-primary" />
            <span className="text-base sm:text-lg font-bold">FUNDit</span>
            {isTestnet && (
              <Badge variant="outline" className="ml-2 text-xs hidden sm:inline-flex">
                Testnet
              </Badge>
            )}
          </Link>

          {/* Desktop Navigation */}
          {isConnected && (
            <div className="hidden md:flex items-center gap-1">
              {routes.map((route) => (
                <Link
                  key={route.href}
                  href={route.href}
                  className={cn(
                    "flex items-center gap-2 px-3 py-2 rounded-md text-sm font-medium transition-colors",
                    route.active
                      ? "bg-primary text-primary-foreground"
                      : "text-muted-foreground hover:bg-muted hover:text-foreground"
                  )}
                >
                  <route.icon className="h-4 w-4" />
                  {route.label}
                </Link>
              ))}
            </div>
          )}

          {/* Right side - Wallet & Mobile Menu */}
          <div className="flex items-center gap-2">
            <WalletButton />
            
            {isConnected && (
              <Button
                variant="ghost"
                size="sm"
                className="md:hidden p-2"
                onClick={() => setIsOpen(!isOpen)}
              >
                <Menu className="h-5 w-5" />
              </Button>
            )}
          </div>
        </div>

        {/* Mobile Navigation */}
        {isConnected && isOpen && (
          <div className="md:hidden border-t bg-background/95 backdrop-blur">
            <div className="px-2 pt-2 pb-3 space-y-1">
              {/* Navigation Links */}
              {routes.map((route) => (
                <Link
                  key={route.href}
                  href={route.href}
                  onClick={() => setIsOpen(false)}
                  className={cn(
                    "flex items-center gap-3 px-3 py-2 rounded-md text-sm font-medium transition-colors w-full",
                    route.active
                      ? "bg-primary text-primary-foreground"
                      : "text-muted-foreground hover:bg-muted hover:text-foreground"
                  )}
                >
                  <route.icon className="h-4 w-4" />
                  {route.label}
                </Link>
              ))}
              
              {/* Account & Network Info for Mobile */}
              <div className="border-t pt-2 mt-2 lg:hidden">
                <div className="px-3 py-1 text-xs text-muted-foreground font-medium">
                  Wallet
                </div>
                <ConnectButton.Custom>
                  {({ account, chain, openAccountModal, openChainModal }) => (
                    <div className="space-y-1">
                      {account && (
                        <Button
                          variant="ghost"
                          size="sm"
                          className="w-full justify-start gap-3 px-3 py-2 h-auto text-left"
                          onClick={() => {
                            openAccountModal();
                            setIsOpen(false);
                          }}
                        >
                          <Wallet className="h-4 w-4" />
                          <div className="flex flex-col items-start">
                            <span className="text-sm font-medium">{account.displayName}</span>
                            <span className="text-xs text-muted-foreground">Account Settings</span>
                          </div>
                        </Button>
                      )}
                      {chain && (
                        <Button
                          variant="ghost"
                          size="sm"
                          className="w-full justify-start gap-3 px-3 py-2 h-auto text-left"
                          onClick={() => {
                            openChainModal();
                            setIsOpen(false);
                          }}
                        >
                          <Network className="h-4 w-4" />
                          <div className="flex flex-col items-start">
                            <span className="text-sm font-medium flex items-center gap-2">
                              {chain.hasIcon && chain.iconUrl && (
                                <img
                                  alt={chain.name ?? "Chain icon"}
                                  src={chain.iconUrl}
                                  className="w-4 h-4"
                                />
                              )}
                              {chain.name}
                            </span>
                            <span className="text-xs text-muted-foreground">Switch Network</span>
                          </div>
                        </Button>
                      )}
                    </div>
                  )}
                </ConnectButton.Custom>
              </div>
            </div>
          </div>
        )}
      </div>
    </nav>
  );
}