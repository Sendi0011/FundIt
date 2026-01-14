"use client";

import { useState, useEffect } from "react";
import { useSpendAndSave } from "@/lib/hooks/use-spend-and-save";
import { useContract } from "@/lib/hooks/use-contract";
import { useAccount } from "wagmi";
import { formatUnits, parseUnits } from "viem";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Switch } from "@/components/ui/switch";
import { Slider } from "@/components/ui/slider";
import { useToast } from "@/hooks/use-toast";
import { Loader2, Check } from "lucide-react";
import { getContractForChain } from "@/contracts/addresses";
import { useChainId } from "wagmi";

export function SpendSaveConfig() {
  const { address, isConnected } = useAccount();
  const chainId = useChainId();
  const { toast } = useToast();
  
  const {
    config,
    isEnabled,
    isLoading,
    isSuccess,
    enableSpendAndSave,
    updateConfig,
    refetchConfig,
  } = useSpendAndSave();

  const { approveUnlimited, isLoading: isApproving } = useContract();

  // Form state
  const [isPercentage, setIsPercentage] = useState(true);
  const [percentage, setPercentage] = useState(10);
  const [fixedAmount, setFixedAmount] = useState("5");
  const [minThreshold, setMinThreshold] = useState("10");
  const [dailyCap, setDailyCap] = useState("50");
  const [monthlyCap, setMonthlyCap] = useState("500");
  const [hasApproval, setHasApproval] = useState(false);

  // Load existing config
  useEffect(() => {
    if (config && config.enabled) {
      setIsPercentage(config.isPercentage);
      if (config.isPercentage) {
        setPercentage(Number(config.value));
      } else {
        setFixedAmount(formatUnits(config.value, 6));
      }
      setMinThreshold(formatUnits(config.minSpendThreshold, 6));
      setDailyCap(formatUnits(config.dailyCap, 6));
      setMonthlyCap(formatUnits(config.monthlyCap, 6));
    }
  }, [config]);

  // Handle approval
  const handleApprove = async () => {
    try {
      const contracts = getContractForChain(chainId);
      await approveUnlimited(contracts.spendAndSave);
      
      toast({
        title: "Approval Pending",
        description: "Please confirm the transaction in your wallet",
      });
    } catch (error) {
      toast({
        title: "Approval Failed",
        description: error instanceof Error ? error.message : "Unknown error",
        variant: "destructive",
      });
    }
  };

  // Handle enable/update
  const handleSubmit = async () => {
    if (!isConnected) {
      toast({
        title: "Wallet Not Connected",
        description: "Please connect your wallet first",
        variant: "destructive",
      });
      return;
    }

    try {
      const params = {
        percentage: isPercentage ? percentage : undefined,
        fixedAmount: !isPercentage ? fixedAmount : undefined,
        minThreshold,
        dailyCap,
        monthlyCap,
      };

      if (isEnabled) {
        await updateConfig(params);
        toast({
          title: "Update Pending",
          description: "Your configuration is being updated",
        });
      } else {
        await enableSpendAndSave(params);
        toast({
          title: "Enabling Spend & Save",
          description: "Please confirm the transaction",
        });
      }
    } catch (error) {
      toast({
        title: "Transaction Failed",
        description: error instanceof Error ? error.message : "Unknown error",
        variant: "destructive",
      });
    }
  };

  // Watch for success
  useEffect(() => {
    if (isSuccess) {
      refetchConfig();
      toast({
        title: "Success!",
        description: isEnabled ? "Configuration updated" : "Spend & Save enabled",
      });
    }
  }, [isSuccess, isEnabled, refetchConfig, toast]);

  if (!isConnected) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Spend & Save Configuration</CardTitle>
          <CardDescription>
            Connect your wallet to configure automated savings
          </CardDescription>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-muted-foreground text-center py-8">
            Please connect your wallet to continue
          </p>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>
          {isEnabled ? "Update" : "Enable"} Spend & Save
        </CardTitle>
        <CardDescription>
          Automatically save a portion of every USDC transaction
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-6">
        {/* Savings Method */}
        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <Label>Savings Method</Label>
            <div className="flex items-center gap-2">
              <span className="text-sm text-muted-foreground">
                {isPercentage ? "Percentage" : "Fixed Amount"}
              </span>
              <Switch
                checked={isPercentage}
                onCheckedChange={setIsPercentage}
              />
            </div>
          </div>
        </div>

        {/* Percentage or Fixed Amount */}
        {isPercentage ? (
          <div className="space-y-2">
            <Label>Save Percentage: {percentage}%</Label>
            <Slider
              value={[percentage]}
              onValueChange={([value]) => setPercentage(value)}
              min={1}
              max={50}
              step={1}
              className="w-full"
            />
            <p className="text-xs text-muted-foreground">
              Example: Spend 100 USDC → Save {percentage} USDC
            </p>
          </div>
        ) : (
          <div className="space-y-2">
            <Label>Fixed Amount (USDC)</Label>
            <Input
              type="number"
              value={fixedAmount}
              onChange={(e) => setFixedAmount(e.target.value)}
              placeholder="5"
              step="0.01"
              min="0.01"
            />
            <p className="text-xs text-muted-foreground">
              Save {fixedAmount} USDC on every transaction
            </p>
          </div>
        )}

        {/* Minimum Threshold */}
        <div className="space-y-2">
          <Label>Minimum Spend Threshold (USDC)</Label>
          <Input
            type="number"
            value={minThreshold}
            onChange={(e) => setMinThreshold(e.target.value)}
            placeholder="10"
            step="1"
            min="1"
          />
          <p className="text-xs text-muted-foreground">
            Only save on spends above this amount
          </p>
        </div>

        {/* Daily Cap */}
        <div className="space-y-2">
          <Label>Daily Cap (USDC)</Label>
          <Input
            type="number"
            value={dailyCap}
            onChange={(e) => setDailyCap(e.target.value)}
            placeholder="50"
            step="1"
            min="1"
          />
          <p className="text-xs text-muted-foreground">
            Maximum to save per day
          </p>
        </div>

        {/* Monthly Cap */}
        <div className="space-y-2">
          <Label>Monthly Cap (USDC)</Label>
          <Input
            type="number"
            value={monthlyCap}
            onChange={(e) => setMonthlyCap(e.target.value)}
            placeholder="500"
            step="1"
            min="1"
          />
          <p className="text-xs text-muted-foreground">
            Maximum to save per month
          </p>
        </div>

        {/* Approval Step */}
        {!hasApproval && !isEnabled && (
          <div className="bg-muted p-4 rounded-lg space-y-3">
            <p className="text-sm">
              Step 1: Approve USDC spending for automated saves
            </p>
            <Button
              onClick={handleApprove}
              disabled={isApproving}
              className="w-full"
            >
              {isApproving ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Approving...
                </>
              ) : (
                "Approve USDC"
              )}
            </Button>
          </div>
        )}

        {/* Enable/Update Button */}
        <Button
          onClick={handleSubmit}
          disabled={isLoading || (!hasApproval && !isEnabled)}
          className="w-full"
          size="lg"
        >
          {isLoading ? (
            <>
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              Processing...
            </>
          ) : isSuccess ? (
            <>
              <Check className="mr-2 h-4 w-4" />
              Success!
            </>
          ) : isEnabled ? (
            "Update Configuration"
          ) : (
            "Enable Spend & Save"
          )}
        </Button>

        {/* Current Config Display */}
        {config && config.enabled && (
          <div className="mt-6 p-4 bg-muted rounded-lg space-y-2">
            <h4 className="font-semibold text-sm">Current Configuration</h4>
            <div className="grid grid-cols-2 gap-2 text-xs">
              <div>
                <span className="text-muted-foreground">Method:</span>
                <span className="ml-2 font-medium">
                  {config.isPercentage ? `${config.value}%` : `${formatUnits(config.value, 6)} USDC`}
                </span>
              </div>
              <div>
                <span className="text-muted-foreground">Min Threshold:</span>
                <span className="ml-2 font-medium">
                  {formatUnits(config.minSpendThreshold, 6)} USDC
                </span>
              </div>
              <div>
                <span className="text-muted-foreground">Daily Cap:</span>
                <span className="ml-2 font-medium">
                  {formatUnits(config.dailyCap, 6)} USDC
                </span>
              </div>
              <div>
                <span className="text-muted-foreground">Monthly Cap:</span>
                <span className="ml-2 font-medium">
                  {formatUnits(config.monthlyCap, 6)} USDC
                </span>
              </div>
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
}