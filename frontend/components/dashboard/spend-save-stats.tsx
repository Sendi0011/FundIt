"use client";

import { useSpendAndSave } from "@/lib/hooks/use-spend-and-save";
import { useAccount } from "wagmi";
import { formatUnits } from "viem";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { TrendingUp, Calendar, Hash, Clock } from "lucide-react";

export function SpendSaveStats() {
  const { isConnected } = useAccount();
  const { stats, config, isEnabled } = useSpendAndSave();

  if (!isConnected || !isEnabled) {
    return null;
  }

  const formatUSDC = (value: bigint | undefined) => {
    if (!value) return "0";
    return formatUnits(value, 6);
  };

  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">
            Total Auto-Saved
          </CardTitle>
          <TrendingUp className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">
            {formatUSDC(stats?.totalAutoSaved)} USDC
          </div>
          <p className="text-xs text-muted-foreground">
            Lifetime savings
          </p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">
            This Month
          </CardTitle>
          <Calendar className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">
            {formatUSDC(config?.monthlySaved)} USDC
          </div>
          <p className="text-xs text-muted-foreground">
            of {formatUSDC(config?.monthlyCap)} cap
          </p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">
            Today
          </CardTitle>
          <Clock className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">
            {formatUSDC(config?.dailySaved)} USDC
          </div>
          <p className="text-xs text-muted-foreground">
            of {formatUSDC(config?.dailyCap)} cap
          </p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">
            Transactions
          </CardTitle>
          <Hash className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">
            {stats?.transactionCount.toString() || "0"}
          </div>
          <p className="text-xs text-muted-foreground">
            Auto-saves completed
          </p>
        </CardContent>
      </Card>
    </div>
  );
}