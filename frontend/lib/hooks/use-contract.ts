"use client";

import { useState, useCallback } from "react";
import { useWriteContract, useWaitForTransactionReceipt, useAccount } from "wagmi";
import { parseUnits, formatUnits } from "viem";
import { ERC20_ABI } from "@/contracts/config";
import { getContractForChain } from "@/contracts/addresses";
import { useChainId } from "wagmi";

// Types for smart contract interactions
export interface ApprovalParams {
  tokenAddress: `0x${string}`;
  spenderAddress: `0x${string}`;
  amount: string;
}

export interface DepositParams {
  vaultAddress: string;
  amount: string;
  savingsType: "target" | "fixed" | "spend-and-save";
  metadata?: Record<string, unknown>;
}

export interface WithdrawParams {
  vaultAddress: string;
  positionId: string;
  amount: string;
}

export interface SpendSaveConfigParams {
  percentage?: number;
  fixedAmount?: number;
  minThreshold: string;
  dailyCap: string;
  monthlyCap: string;
}

// Hook for managing smart contract interactions
export function useContract() {
  const { address } = useAccount();
  const chainId = useChainId();
  const [error, setError] = useState<string | null>(null);

  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const isLoading = isPending || isConfirming;

  /**
   * Approve USDC spending for the contract
   */
  const approveToken = useCallback(
    async (params: ApprovalParams) => {
      setError(null);
      try {
        const amountInWei = parseUnits(params.amount, 6); // USDC has 6 decimals

        writeContract({
          address: params.tokenAddress,
          abi: ERC20_ABI,
          functionName: "approve",
          args: [params.spenderAddress, amountInWei],
        });

        return { success: true };
      } catch (err) {
        const errorMessage = err instanceof Error ? err.message : "Approval failed";
        setError(errorMessage);
        throw err;
      }
    },
    [writeContract]
  );

  /**
   * Approve unlimited USDC spending (common pattern for better UX)
   */
  const approveUnlimited = useCallback(
    async (spenderAddress: `0x${string}`) => {
      setError(null);
      try {
        const contracts = getContractForChain(chainId);
        const maxUint256 = BigInt(
          "115792089237316195423570985008687907853269984665640564039457584007913129639935"
        );

        writeContract({
          address: contracts.usdc,
          abi: ERC20_ABI,
          functionName: "approve",
          args: [spenderAddress, maxUint256],
        });

        return { success: true };
      } catch (err) {
        const errorMessage = err instanceof Error ? err.message : "Approval failed";
        setError(errorMessage);
        throw err;
      }
    },
    [writeContract, chainId]
  );

  /**
   * Deposit to vault (placeholder - you'll implement with actual vault contract)
   */
  const depositToVault = useCallback(
    async (params: DepositParams) => {
      setError(null);
      try {
        // This will be implemented when you have the SavingsVault contract
        console.log("[Contract] Depositing to vault:", params);
        
        // For now, return a simulated response
        // In production, this would call your SavingsVault contract
        return { 
          success: true, 
          txHash: hash,
          positionId: "pos_001" 
        };
      } catch (err) {
        const errorMessage = err instanceof Error ? err.message : "Deposit failed";
        setError(errorMessage);
        throw err;
      }
    },
    [hash]
  );

  /**
   * Withdraw from vault (placeholder)
   */
  const withdrawFromVault = useCallback(
    async (params: WithdrawParams) => {
      setError(null);
      try {
        console.log("[Contract] Withdrawing from vault:", params);
        
        // Implement with actual vault contract
        return { success: true, txHash: hash };
      } catch (err) {
        const errorMessage = err instanceof Error ? err.message : "Withdrawal failed";
        setError(errorMessage);
        throw err;
      }
    },
    [hash]
  );

  /**
   * Create new savings vault (placeholder)
   */
  const createVault = useCallback(async () => {
    setError(null);
    try {
      console.log("[Contract] Creating new vault");
      
      // This will call SavingsFactory.createVault()
      // For now, simulate
      return { 
        success: true, 
        vaultAddress: "0xabcd...ef12" as `0x${string}`,
        txHash: hash 
      };
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : "Failed to create vault";
      setError(errorMessage);
      throw err;
    }
  }, [hash]);

  return {
    // State
    isLoading,
    isSuccess,
    txHash: hash,
    error,
    
    // Functions
    approveToken,
    approveUnlimited,
    depositToVault,
    withdrawFromVault,
    createVault,
  };
}