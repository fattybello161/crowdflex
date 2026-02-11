# CrossDAO - STX Staking & Governance Contract

## Overview

CrossDAO is a Clarity smart contract that implements a decentralized autonomous organization (DAO) with STX staking and token-based governance. Users can stake STX to receive xSTX tokens, participate in proposals, and vote with weighted influence based on their stake amount.

## Features

###  Staking & Tokenomics
- **Stake STX**: Convert STX to xSTX tokens with a minimum stake of 10,000 uSTX
- **Fungible Token (xSTX)**: ERC-20-like token representing your stake in the DAO
- **Timestamp Tracking**: Records when stakes are created for time-based mechanics
- 
###  Governance & Proposals
- **Submit Proposals**: Create governance proposals with descriptions and voting duration
- **Weighted Voting**: Vote power is proportional to your staked amount
- **Vote Tracking**: Prevents double voting and tracks vote records per proposal
- **Proposal Execution**: Execute approved proposals (more votes-for than votes-against)

###  Rewards Management
- **Reward Pool**: Accumulate STX rewards for distribution
- **Claim Rewards**: Users can claim their allocated rewards
- **Distribution System**: Distribute rewards from the pool to stakeholders

###  Emergency Controls
- **Emergency Exit**: Trigger emergency mode to allow users to unstake without penalties
- **Emergency Flag**: Prevent operations during emergency scenarios
- **Safe Unstaking**: Burn xSTX and return STX during emergencies

## Contract Constants & Limits

| Constant | Value | Description |
|----------|-------|-------------|
| MIN_STAKE | 10,000 uSTX | Minimum STX required to stake |
| Error u100 | Stake too low | Insufficient stake amount |
| Error u200 | Already voted | User has already voted on proposal |
| Error u201 | No stake found | User has no active stake |
| Error u301 | Voting ongoing | Proposal voting period not ended |
| Error u302 | Already executed | Proposal already executed |
| Error u303 | Vote failed | Insufficient votes-for to execute |
| Error u404 | Not found | Proposal doesn't exist |
| Error u500 | No rewards | User has no claimable rewards |
| Error u510 | Empty pool | Reward pool is empty |
| Error u600 | No emergency | Emergency mode not active |
| Error u601 | No stake | User has no stake to exit |
| Error u999 | Unauthorized | Only contract caller allowed |

## Key Functions

### Staking
```clarity
(stake-stx amount)       ;; Stake STX and mint xSTX
(get-user-stake user)    ;; View user's stake info
(exit-stake)             ;; Emergency unstake (requires emergency flag)
```

### Governance
```clarity
(submit-proposal desc duration)    ;; Create a new proposal
(vote id support)                  ;; Vote on proposal (true/false)
(execute-proposal id)              ;; Execute approved proposal
(get-proposal id)                  ;; View proposal details
```

### Rewards
```clarity
(claim-rewards)                    ;; Claim allocated rewards
(distribute-rewards)               ;; Distribute reward pool
(get-total-reward-pool)            ;; View total rewards available
```

### Emergency
```clarity
(trigger-emergency)    ;; Enable emergency mode
(is-emergency)         ;; Check emergency status
```

## Usage Example

```clarity
;; User stakes 100,000 uSTX
(contract-call? .crossdao stake-stx u100000)

;; Submit a governance proposal
(contract-call? .crossdao submit-proposal (utf8 "Increase reward pool") u144)

;; Vote in favor (weighted by 100,000 uSTX stake)
(contract-call? .crossdao vote u1 true)

;; Execute proposal after voting ends
(contract-call? .crossdao execute-proposal u1)

;; Claim rewards
(contract-call? .crossdao claim-rewards)
```

## Data Structures

- **stakes**: Maps principal → {amount, timestamp}
- **proposals**: Maps proposal-id → {creator, description, end-block, votes-for, votes-against, executed}
- **vote-records**: Maps {proposal-id, voter} → {vote, weight}
- **rewards**: Maps principal → reward amount

## Security Considerations

 **Note**: This contract includes emergency controls for risk mitigation. Always test thoroughly before mainnet deployment.

- Vote weight based on staked amount prevents Sybil attacks
- Double-vote prevention via vote-records
- Proposal execution validation checks
- Emergency exit for critical situations
