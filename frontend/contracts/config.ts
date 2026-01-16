import SpendAndSaveABI from "./abis/SpendAndSaveModule.abi.json";
import { CONTRACT_ADDRESSES, CURRENT_NETWORK } from "./addresses";

export const SPEND_AND_SAVE_ABI = SpendAndSaveABI;

export const CONTRACTS = {
  spendAndSave: {
    abi: SPEND_AND_SAVE_ABI,
    address: CONTRACT_ADDRESSES[CURRENT_NETWORK].spendAndSave,
    addresses: {
      mainnet: CONTRACT_ADDRESSES.mainnet.spendAndSave,
      testnet: CONTRACT_ADDRESSES.testnet.spendAndSave,
    },
  },
  usdc: {
    addresses: {
      mainnet: CONTRACT_ADDRESSES.mainnet.usdc,
      testnet: CONTRACT_ADDRESSES.testnet.usdc,
    },
  },
} as const;

// Standard ERC20 ABI (for USDC approval)
export const ERC20_ABI = [
  {
    inputs: [
      { name: "spender", type: "address" },
      { name: "amount", type: "uint256" },
    ],
    name: "approve",
    outputs: [{ name: "", type: "bool" }],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [{ name: "account", type: "address" }],
    name: "balanceOf",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      { name: "owner", type: "address" },
      { name: "spender", type: "address" },
    ],
    name: "allowance",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "decimals",
    outputs: [{ name: "", type: "uint8" }],
    stateMutability: "view",
    type: "function",
  },
] as const;