"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { WalletButton } from "@/components/wallet-button";
import { Shield, LayoutDashboard, Activity } from "lucide-react";
import { cn } from "@/lib/utils";
import { useAccount, useChainId } from "wagmi";
import { Badge } from "@/components/ui/badge";

export function Navbar() {
  const pathname = usePathname();
  const { isConnected } = useAccount();
  const chainId = useChainId();

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
    <nav className="border-b bg-background/95 backdrop-blur supports-[backdrop-filter:bg-background/60">
      <div className="container mx-auto px-4">
        <div className="flex h-16 items-center justify-between">
          {/* Logo */}
          <Link href="/" className="flex items-center gap-2 font-semibold">
            <Shield className="h-6 w-6 text-primary" />
            <span className="text-xl">FUNDit</span>
            {isTestnet && (
              <Badge variant="outline" className="ml-2">
                Testnet
              </Badge>
            )}
          </Link>

          {/* Navigation Links */}
          {isConnected && (
            <div className="flex items-center gap-1">
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

          {/* Wallet Button */}
          <WalletButton />
        </div>
      </div>
    </nav>
  );
}