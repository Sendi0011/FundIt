// Types derived from your smart contract
export interface SpendAndSaveConfig {
    enabled: boolean;
    isPercentage: boolean;
    value: bigint;
    minSpendThreshold: bigint;
    dailyCap: bigint;
    monthlyCap: bigint;
    dailySaved: bigint;
    monthlySaved: bigint;
    lastResetDay: bigint;
    lastResetMonth: bigint;
    destinationId: bigint;
    totalAutoSaved: bigint;
    transactionCount: bigint;
  }
  
  export interface UserStats {
    totalAutoSaved: bigint;
    transactionCount: bigint;
    dailySaved: bigint;
    monthlySaved: bigint;
    lastAutoSave: bigint;
  }
  
  export interface EnableSpendAndSaveParams {
    value: bigint;
    isPercentage: boolean;
    minSpendThreshold: bigint;
    dailyCap: bigint;
    monthlyCap: bigint;
    destinationId: bigint;
  }