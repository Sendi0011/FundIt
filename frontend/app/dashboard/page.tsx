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
import { Plus } from "lucide-react";
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
  
  const { address } = useAccount();
  const { stats, config, isEnabled } = useSpendAndSave();

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
      <div className="min-h-screen bg-gradient-to-b from-background to-background/50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-8">
          {/* Header */}
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold">Dashboard</h1>
              <p className="text-muted-foreground mt-1">
                Welcome back! Manage your savings
              </p>
            </div>
            <Button
              onClick={() => setModalState("start-saving")}
              className="gap-2"
              size="lg"
            >
              <Plus className="h-5 w-5" />
              Start New Saving
            </Button>
          </div>

          {/* Total Saved Card - Using Real Data */}
          <TotalSavedCard
            totalAmount={totalAutoSaved}
            monthlyIncrease={monthlySaved}
          />

          {/* Main Content Grid */}
          <div className="grid lg:grid-cols-3 gap-6">
            <div className="lg:col-span-2 space-y-6">
              {/* Active Savings */}
              <div className="space-y-4">
                <h2 className="text-2xl font-bold">Active Savings</h2>
                <div className="grid gap-4">
                  {/* Spend & Save Card - Only show if enabled */}
                  {isEnabled && (
                    <SavingsCard
                      type="spend-and-save"
                      title="Automated Savings"
                      amount={totalAutoSaved}
                      onClick={() => setModalState("spend-save-management")}
                    />
                  )}

                  {/* Placeholder for Target Savings - You'll integrate with SavingsVault */}
                  {/* <SavingsCard
                    type="target"
                    title="Summer Vacation"
                    amount={250}
                    targetAmount={500}
                  /> */}

                  {/* Placeholder for Fixed Savings */}
                  {/* <SavingsCard
                    type="fixed"
                    title="Emergency Fund"
                    amount={1000}
                    duration="60 days"
                    unlockDate="March 15, 2026"
                  /> */}

                  {/* Empty State */}
                  {!isEnabled && (
                    <div className="border-2 border-dashed rounded-lg p-8 text-center">
                      <p className="text-muted-foreground mb-4">
                        No active savings yet
                      </p>
                      <Button
                        onClick={() => setModalState("start-saving")}
                        variant="outline"
                      >
                        Start Your First Saving
                      </Button>
                    </div>
                  )}
                </div>
              </div>
            </div>

            <div className="space-y-6">
              {/* Spend & Save Stats - Using Real Data */}
              {isEnabled && <SpendSaveStats />}

              {/* Spend & Save Activity */}
              {isEnabled && <SpendSaveActivity />}

              {/* General Activity Feed */}
              <ActivityFeed />
            </div>
          </div>
        </div>
      </div>

      {/* Modals */}
      <StartSavingModal
        isOpen={modalState === "start-saving"}
        onClose={() => setModalState("closed")}
        onSelectType={handleSelectType}
      />

      {modalState === "target-form" && (
        <div className="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4">
          <div className="w-full max-w-2xl">
            <TargetSavingsForm
              onSubmit={() => setModalState("closed")}
              isLoading={false}
            />
          </div>
        </div>
      )}

      {modalState === "fixed-form" && (
        <div className="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4">
          <div className="w-full max-w-2xl">
            <FixedSavingsForm
              onSubmit={() => setModalState("closed")}
              isLoading={false}
            />
          </div>
        </div>
      )}

      {modalState === "spend-save-config" && (
        <div className="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4 overflow-y-auto">
          <div className="w-full max-w-2xl my-8">
            <div className="relative">
              <Button
                variant="ghost"
                size="sm"
                className="absolute right-0 top-0 z-10"
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
        <div className="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4">
          <div className="w-full max-w-2xl">
            <SpendSaveManagement
              onUpdate={() => setModalState("closed")}
              isLoading={false}
            />
          </div>
        </div>
      )}

      {modalState === "withdraw" && withdrawState && (
        <div className="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4">
          <div className="w-full max-w-2xl">
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
    </ConnectWalletGuard>
  );
}