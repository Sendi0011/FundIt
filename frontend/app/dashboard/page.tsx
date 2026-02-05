"use client";

import { Navbar } from "@/components/navbar";
import { ConnectWalletGuard } from "@/components/auth/connect-wallet-guard";
import { TotalSavedCard } from "@/components/dashboard/total-saved-card";
import { SavingsCard } from "@/components/dashboard/savings-card";
import { SpendSaveStats } from "@/components/dashboard/spend-save-stats";
import { SpendSaveActivity } from "@/components/dashboard/spend-save-activity";
import { ActivityFeed } from "@/components/dashboard/activity-feed";
import { StartSavingModal } from "@/components/savings/start-saving-modal";
import { TargetSavingsForm } from "@/components/savings/target-savings-form";
import { FixedSavingsForm } from "@/components/savings/fixed-savings-form";
import { SpendSaveConfig } from "@/components/savings/spend-save-config";
import { SpendSaveManagement } from "@/components/savings/spend-save-management";
import { WithdrawDialog } from "@/components/dashboard/withdraw-dialog";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { 
  Plus, 
  LayoutDashboard, 
  Sparkles, 
  TrendingUp, 
  Shield, 
  Zap,
  Target,
  Clock,
  Wallet,
  PiggyBank,
  Star
} from "lucide-react";
import { useState } from "react";
import { useSpendAndSave } from "@/lib/hooks/use-spend-and-save";
import { useAccount } from "wagmi";
import { formatUnits } from "viem";

type ModalState =
  | "closed"
  | "start-saving"
  | "target-form"
  | "fixed-form"
  | "spend-save-config"
  | "spend-save-management"
  | "withdraw";

interface WithdrawState {
  positionId: string;
  type: "target" | "fixed" | "spend-and-save";
  title: string;
  amount: number;
  isLocked?: boolean;
}

export default function DashboardPage() {
  const [modalState, setModalState] = useState<ModalState>("closed");
  const [withdrawState, setWithdrawState] = useState<WithdrawState | null>(null);
  const [isRefreshing, setIsRefreshing] = useState(false);
  
  const { address } = useAccount();
  const { stats, config, isEnabled, refetch } = useSpendAndSave();

  const handleRefresh = async () => {
    setIsRefreshing(true);
    try {
      await refetch?.();
    } catch (error) {
      console.error("Failed to refresh:", error);
    } finally {
      setIsRefreshing(false);
    }
  };

  const handleSelectType = (type: "target" | "fixed" | "spend-and-save") => {
    if (type === "target") {
      setModalState("target-form");
    } else if (type === "fixed") {
      setModalState("fixed-form");
    } else if (type === "spend-and-save") {
      setModalState("spend-save-config");
    }
  };

  const handleOpenWithdraw = (position: WithdrawState) => {
    setWithdrawState(position);
    setModalState("withdraw");
  };

  const handleWithdrawConfirm = async (amount: number) => {
    // Smart contract integration would go here
    console.log("Withdrawing:", amount);
    // Simulate withdrawal
    await new Promise((resolve) => setTimeout(resolve, 1000));
  };

  // Format blockchain data
  const totalAutoSaved = stats?.totalAutoSaved 
    ? Number(formatUnits(stats.totalAutoSaved, 6)) 
    : 0;
  
  const monthlySaved = config?.monthlySaved 
    ? Number(formatUnits(config.monthlySaved, 6)) 
    : 0;
  
  const transactionCount = stats?.transactionCount 
    ? Number(stats.transactionCount) 
    : 0;

  return (
    <ConnectWalletGuard>
      <Navbar />
      <div className="min-h-screen bg-linear-to-b from-background to-background/50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6 sm:py-8 space-y-6 sm:space-y-8">
          {/* Header */}
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 animate-fade-in">
            <div>
              <h1 className="text-2xl sm:text-3xl font-bold flex items-center gap-2 sm:gap-3">
                <div className="p-2 bg-primary/10 rounded-xl">
                  <LayoutDashboard className="h-6 w-6 sm:h-8 sm:w-8 text-primary" />
                </div>
                Dashboard
                <Badge variant="secondary" className="hidden sm:inline-flex">
                  <Sparkles className="h-3 w-3 mr-1" />
                  Smart Savings
                </Badge>
              </h1>
              <p className="text-muted-foreground mt-1 text-sm sm:text-base">
                Welcome back! Track and manage your automated savings
              </p>
            </div>
            <Button
              onClick={() => setModalState("start-saving")}
              className="gap-2 hover:scale-105 transition-transform w-full sm:w-auto"
              size="lg"
            >
              <Plus className="h-4 w-4 sm:h-5 sm:w-5" />
              Start New Saving
            </Button>
          </div>

          {/* Total Saved Card - Enhanced */}
          <div className="animate-slide-in">
            <TotalSavedCard
              totalAmount={totalAutoSaved}
              monthlyIncrease={monthlySaved}
              onRefresh={handleRefresh}
              isRefreshing={isRefreshing}
            />
          </div>

          {/* Main Content Grid */}
          <div className="grid lg:grid-cols-3 gap-6">
            <div className="lg:col-span-2 space-y-6">
              {/* Active Savings */}
              <div className="space-y-4">
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-green-100 dark:bg-green-900 rounded-lg">
                    <PiggyBank className="h-5 w-5 text-green-600 dark:text-green-400" />
                  </div>
                  <div>
                    <h2 className="text-xl sm:text-2xl font-bold">Active Savings</h2>
                    <p className="text-sm text-muted-foreground">Your automated savings strategies</p>
                  </div>
                </div>
                
                <div className="grid gap-4">
                  {/* Spend & Save Card - Enhanced */}
                  {isEnabled && (
                    <div className="animate-slide-in" style={{ animationDelay: "100ms" }}>
                      <SavingsCard
                        type="spend-and-save"
                        title="Automated Savings"
                        amount={totalAutoSaved}
                        onClick={() => setModalState("spend-save-management")}
                      />
                    </div>
                  )}

                  {/* Enhanced Empty State */}
                  {!isEnabled && (
                    <div className="border-2 border-dashed rounded-xl p-8 text-center bg-muted/20 hover:bg-muted/30 transition-colors animate-fade-in">
                      <div className="p-4 bg-muted/50 rounded-full w-16 h-16 mx-auto mb-4 flex items-center justify-center">
                        <Target className="h-8 w-8 text-muted-foreground" />
                      </div>
                      <h3 className="font-semibold text-lg mb-2">No active savings yet</h3>
                      <p className="text-muted-foreground mb-4 text-sm">
                        Start your financial journey with automated savings
                      </p>
                      <Button
                        onClick={() => setModalState("start-saving")}
                        variant="outline"
                        className="gap-2 hover:scale-105 transition-transform"
                      >
                        <Star className="h-4 w-4" />
                        Start Your First Saving
                      </Button>
                    </div>
                  )}

                  {/* Future Savings Placeholders with Better Styling */}
                  {isEnabled && (
                    <>
                      <div className="border-2 border-dashed rounded-xl p-6 text-center bg-blue-50/50 dark:bg-blue-950/20 hover:bg-blue-50 dark:hover:bg-blue-950/30 transition-colors animate-slide-in" style={{ animationDelay: "200ms" }}>
                        <div className="p-3 bg-blue-100 dark:bg-blue-900 rounded-full w-12 h-12 mx-auto mb-3 flex items-center justify-center">
                          <Target className="h-6 w-6 text-blue-600 dark:text-blue-400" />
                        </div>
                        <h4 className="font-medium mb-1">Target Savings</h4>
                        <p className="text-xs text-muted-foreground mb-3">Save towards specific goals</p>
                        <Button size="sm" variant="outline" className="gap-1">
                          <Plus className="h-3 w-3" />
                          Add Goal
                        </Button>
                      </div>

                      <div className="border-2 border-dashed rounded-xl p-6 text-center bg-purple-50/50 dark:bg-purple-950/20 hover:bg-purple-50 dark:hover:bg-purple-950/30 transition-colors animate-slide-in" style={{ animationDelay: "300ms" }}>
                        <div className="p-3 bg-purple-100 dark:bg-purple-900 rounded-full w-12 h-12 mx-auto mb-3 flex items-center justify-center">
                          <Clock className="h-6 w-6 text-purple-600 dark:text-purple-400" />
                        </div>
                        <h4 className="font-medium mb-1">Fixed Savings</h4>
                        <p className="text-xs text-muted-foreground mb-3">Lock funds for higher returns</p>
                        <Button size="sm" variant="outline" className="gap-1">
                          <Plus className="h-3 w-3" />
                          Lock Funds
                        </Button>
                      </div>
                    </>
                  )}
                </div>
              </div>
            </div>

            <div className="space-y-6">
              {/* Enhanced Sidebar */}
              <div className="space-y-4">
                <div className="flex items-center gap-2">
                  <TrendingUp className="h-5 w-5 text-primary" />
                  <h3 className="font-semibold">Insights & Activity</h3>
                </div>

                {/* Spend & Save Stats - Enhanced */}
                {isEnabled && (
                  <div className="animate-slide-in" style={{ animationDelay: "400ms" }}>
                    <SpendSaveStats />
                  </div>
                )}

                {/* Spend & Save Activity - Enhanced */}
                {isEnabled && (
                  <div className="animate-slide-in" style={{ animationDelay: "500ms" }}>
                    <SpendSaveActivity />
                  </div>
                )}

                {/* General Activity Feed - Enhanced */}
                <div className="animate-slide-in" style={{ animationDelay: "600ms" }}>
                  <ActivityFeed />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Enhanced Modals remain the same but with better backdrop */}
      <StartSavingModal
        isOpen={modalState === "start-saving"}
        onClose={() => setModalState("closed")}
        onSelectType={handleSelectType}
      />

      {modalState === "target-form" && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="w-full max-w-2xl animate-scale-in">
            <TargetSavingsForm
              onSubmit={() => setModalState("closed")}
              isLoading={false}
            />
          </div>
        </div>
      )}

      {modalState === "fixed-form" && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="w-full max-w-2xl animate-scale-in">
            <FixedSavingsForm
              onSubmit={() => setModalState("closed")}
              isLoading={false}
            />
          </div>
        </div>
      )}

      {modalState === "spend-save-config" && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4 overflow-y-auto">
          <div className="w-full max-w-2xl my-8 animate-scale-in">
            <div className="relative">
              <Button
                variant="ghost"
                size="sm"
                className="absolute right-0 top-0 z-10 hover:bg-destructive hover:text-destructive-foreground"
                onClick={() => setModalState("closed")}
              >
                ✕
              </Button>
              <SpendSaveConfig />
            </div>
          </div>
        </div>
      )}

      {modalState === "spend-save-management" && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="w-full max-w-2xl animate-scale-in">
            <SpendSaveManagement
              onUpdate={() => setModalState("closed")}
              isLoading={false}
            />
          </div>
        </div>
      )}

      {modalState === "withdraw" && withdrawState && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="w-full max-w-2xl animate-scale-in">
            <WithdrawDialog
              positionId={withdrawState.positionId}
              type={withdrawState.type}
              amount={withdrawState.amount}
              title={withdrawState.title}
              isLocked={withdrawState.isLocked}
              onWithdraw={handleWithdrawConfirm}
              onClose={() => {
                setModalState("closed");
                setWithdrawState(null);
              }}
            />
          </div>
        </div>
      )}

      <style jsx global>{`
        @keyframes fade-in {
          from { opacity: 0; transform: translateY(20px); }
          to { opacity: 1; transform: translateY(0); }
        }
        
        @keyframes slide-in {
          from { opacity: 0; transform: translateX(-20px); }
          to { opacity: 1; transform: translateX(0); }
        }
        
        @keyframes scale-in {
          from { opacity: 0; transform: scale(0.95); }
          to { opacity: 1; transform: scale(1); }
        }
        
        .animate-fade-in {
          animation: fade-in 0.6s ease-out;
        }
        
        .animate-slide-in {
          animation: slide-in 0.4s ease-out forwards;
          opacity: 0;
        }
        
        .animate-scale-in {
          animation: scale-in 0.3s ease-out;
        }
      `}</style>
    </ConnectWalletGuard>
  );
}