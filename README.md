# ⚓ anchor-contracts

Smart contract repo for Anchor — trustless escrow on Base.

## V2 Architecture

AnchorV2 introduces a robust arbitration system for dispute resolution:
- **Arbitrator Role:** An `immutable` arbitrator address is assigned at deployment.
- **Disputes:** Either the Client or Freelancer can call `raiseDispute()` to freeze funds.
- **Resolution:** The Arbitrator calls `resolveDispute()` to payout the winner and set the status to `Resolved`.

## Setup

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash && foundryup

# Clone and install deps
git clone https://github.com/you/anchor-contracts
cd anchor-contracts
forge install OpenZeppelin/openzeppelin-contracts --no-commit
```

## Commands

```bash
forge build                        # Compile
forge test -vvv                    # Run all tests
forge test --gas-report            # Gas usage
forge coverage                     # Coverage report
```

## Deploy to Base Sepolia

**Note:** `AnchorV2` requires an `ARBITRATOR_ADDRESS` in your `.env` file before deploying.

```bash
cp .env.example .env               # Fill in your keys (PRIVATE_KEY, BASESCAN_API_KEY, ARBITRATOR_ADDRESS)
source .env
forge script script/Deploy.s.sol:DeployAnchorV2 \
  --rpc-url https://sepolia.base.org \
  --broadcast --verify \
  --etherscan-api-key $BASESCAN_API_KEY
```

## After Deploy

Copy `out/AnchorV2.sol/AnchorV2.json` to `anchor-frontend/lib/Anchor.json`
Copy the deployed address to your frontend's `.env.local` (`NEXT_PUBLIC_CONTRACT_ADDRESS`).

## Contract
- **Version**: V2
- **Network**: Base Sepolia
- **Address**: `0x2674C1B98A8c7EfAD38FdC386f87012aAa2A40ec`
- **Arbitrator Address**: `0x5eA5849225DdDBf9d3C11DF547E3D645AA394937`
- **Basescan**: [https://sepolia.basescan.org/address/0x2674C1B98A8c7EfAD38FdC386f87012aAa2A40ec](https://sepolia.basescan.org/address/0x2674C1B98A8c7EfAD38FdC386f87012aAa2A40ec)
