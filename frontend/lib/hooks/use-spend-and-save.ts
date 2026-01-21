"use client";

import { useReadContract, useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { parseUnits } from "viem";
import { CONTRACTS } from "@/contracts/config";
import { getContractForChain } from "@/contracts/addresses";
import { useAccount, useChainId } from "wagmi";
import type { SpendAndSaveConfig, UserStats } from "@/contracts/types";

export function useSpendAndSave() {
  const { address } = useAccount();
  const chainId = useChainId();
  const contractAddress = getContractForChain(chainId).spendAndSave;

  // Read Functions
  const { data: config, refetch: refetchConfig } = useReadContract({
    address: contractAddress,
    abi: CONTRACTS.spendAndSave.abi,
    functionName: "getUserConfig",
    args: address ? [address] : undefined,
    query: {
      enabled: !!address,
    },
  }) as { data: SpendAndSaveConfig | undefined; refetch: () => void };

  const { data: stats, refetch: refetchStats } = useReadContract({
    address: contractAddress,
    abi: CONTRACTS.spendAndSave.abi,
    functionName: "getUserStats",
    args: address ? [address] : undefined,
    query: {
      enabled: !!address,
    },
  }) as { data: UserStats | undefined; refetch: () => void };

  const { data: isEnabled } = useReadContract({
    address: contractAddress,
    abi: CONTRACTS.spendAndSave.abi,
    functionName: "isSpendAndSaveEnabled",
    args: address ? [address] : undefined,
    query: {
      enabled: !!address,
    },
  });

  const { data: vault } = useReadContract({
    address: contractAddress,
    abi: CONTRACTS.spendAndSave.abi,
    functionName: "getUserVault",
    args: address ? [address] : undefined,
    query: {
      enabled: !!address,
    },
  });

  const { data: remainingDailyCap } = useReadContract({
    address: contractAddress,
    abi: CONTRACTS.spendAndSave.abi,
    functionName: "getRemainingDailyCap",
    args: address ? [address] : undefined,
    query: {
      enabled: !!address,
    },
  });

  const { data: remainingMonthlyCap } = useReadContract({
    address: contractAddress,
    abi: CONTRACTS.spendAndSave.abi,
    functionName: "getRemainingMonthlyCap",
    args: address ? [address] : undefined,
    query: {
      enabled: !!address,
    },
  });

  const { writeContract, data: hash, isPending } = useWriteContract();

  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  // Helper functions
  const enableSpendAndSave = async (params: {
    percentage?: number;
    fixedAmount?: string;
    minThreshold: string;
    dailyCap: string;
    monthlyCap: string;
  }) => {
    const isPercentage = params.percentage !== undefined;
    const value = isPercentage
      ? BigInt(params.percentage!)
      : parseUnits(params.fixedAmount!, 6);

    return writeContract({
      address: contractAddress,
      abi: CONTRACTS.spendAndSave.abi,
      functionName: "enableSpendAndSave",
      args: [
        value,
        isPercentage,
        parseUnits(params.minThreshold, 6),
        parseUnits(params.dailyCap, 6),
        parseUnits(params.monthlyCap, 6),
        0n, // destinationId (0 for flexible)
      ],
    });
  };

  const updateConfig = async (params: {
    percentage?: number;
    fixedAmount?: string;
    minThreshold: string;
    dailyCap: string;
    monthlyCap: string;
  }) => {
    const isPercentage = params.percentage !== undefined;
    const value = isPercentage
      ? BigInt(params.percentage!)
      : parseUnits(params.fixedAmount!, 6);

    return writeContract({
      address: contractAddress,
      abi: CONTRACTS.spendAndSave.abi,
      functionName: "updateSpendAndSaveConfig",
      args: [
        value,
        isPercentage,
        parseUnits(params.minThreshold, 6),
        parseUnits(params.dailyCap, 6),
        parseUnits(params.monthlyCap, 6),
        0n,
      ],
    });
  };

  const pauseSpendAndSave = async () => {
    return writeContract({
      address: contractAddress,
      abi: CONTRACTS.spendAndSave.abi,
      functionName: "pauseSpendAndSave",
    });
  };

  const resumeSpendAndSave = async () => {
    return writeContract({
      address: contractAddress,
      abi: CONTRACTS.spendAndSave.abi,
      functionName: "resumeSpendAndSave",
    });
  };

  const disableSpendAndSave = async () => {
    return writeContract({
      address: contractAddress,
      abi: CONTRACTS.spendAndSave.abi,
      functionName: "disableSpendAndSave",
    });
  };

  const linkVault = async (vaultAddress: `0x${string}`) => {
    return writeContract({
      address: contractAddress,
      abi: CONTRACTS.spendAndSave.abi,
      functionName: "linkVault",
      args: [vaultAddress],
    });
  };

  return {
    config,
    stats,
    isEnabled: isEnabled as boolean,
    vault: vault as `0x${string}` | undefined,
    remainingDailyCap: remainingDailyCap as bigint | undefined,
    remainingMonthlyCap: remainingMonthlyCap as bigint | undefined,
    isLoading: isPending || isConfirming,
    isSuccess,
    txHash: hash,

    enableSpendAndSave,
    updateConfig,
    pauseSpendAndSave,
    resumeSpendAndSave,
    disableSpendAndSave,
    linkVault,
    refetchConfig,
    refetchStats,
  };
}