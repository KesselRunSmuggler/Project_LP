# Project_LP
Repo for Project 3

# Deployment
All 3 stablecoin contracts must be deployed and minted to the user's wallet address. Please ensure these contract addresses are saved for future reference, these must be copy pasted in the respective stablecoin contract addresses in the main contract. Once this is complete, the main contract can be deployed. 

Ensure that all stablecoins are approved on the main contract address to have an unlimited spending limit (999999999999999999999999999999), otherwise deposits and trades will not work. Once this is complete, stablecoins will need to be loaded onto the contract for testing purposes, this can be done by sending stablecoins directly to the contract address, or via the "deposit" functions (note: there are 3 deposit functions, one for each approved stablecoin). 

# Swap
To trade a coin, any of the swap functions can be used. There are 6 different ones in total, each swapping a specific coin to another one. 

# Loan
At this stage, the loan function can only be manually approved by the contract address owner. This is as there are no oracles on the local testnet for liquidations, nor is the liquidation bot coded. Loan interest is accrued in real time and can be paid back in full at any time. The collateral distribution must also be done manually by the contract address owner (not coded, manual transaction required). 
