export const CONTRACT_ADDRESSES = {
    mainnet: {
      spendAndSave: "0x551B59333B6cbaBC3997796A0106e2D1095A7649" as `0x${string}`,
      usdc: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913" as `0x${string}`,
      chainId: 8453,
      name: "Base Mainnet",
      rpcUrl: "https://mainnet.base.org",
      blockExplorer: "https://basescan.org",
    },
    testnet: {
      spendAndSave: "0x5546CC7b7D31Ac8363b3F5944598da7132151320" as `0x${string}`,
      usdc: "0x036CbD53842c5426634e7929541eC2318f3dCF7e" as `0x${string}`,
      chainId: 84532,
      name: "Base Sepolia",
      rpcUrl: "https://sepolia.base.org",
      blockExplorer: "https://sepolia.basescan.org",
    },
  } as const;
  
  export type NetworkName = keyof typeof CONTRACT_ADDRESSES;
  
  export const CURRENT_NETWORK: NetworkName =
    (process.env.NEXT_PUBLIC_NETWORK as NetworkName) || "testnet";
  
  export function getContractAddress(network: NetworkName = CURRENT_NETWORK) {
    return CONTRACT_ADDRESSES[network].spendAndSave;
  }
  
  export function getUSDCAddress(network: NetworkName = CURRENT_NETWORK) {
    return CONTRACT_ADDRESSES[network].usdc;
  }
  
  export function getChainId(network: NetworkName = CURRENT_NETWORK) {
    return CONTRACT_ADDRESSES[network].chainId;
  }
  
  export function getNetworkConfig(network: NetworkName = CURRENT_NETWORK) {
    return CONTRACT_ADDRESSES[network];
  }
  
  export function getContractForChain(chainId: number) {
    const isMainnet = chainId === 8453;
    return isMainnet ? CONTRACT_ADDRESSES.mainnet : CONTRACT_ADDRESSES.testnet;
  }