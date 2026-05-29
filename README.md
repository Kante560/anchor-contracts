# ⚓ anchor-contracts

Smart contract repo for Anchor — trustless escrow on Base.

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

```bash
cp .env.example .env               # Fill in your keys
source .env
forge script script/Deploy.s.sol \
  --rpc-url https://sepolia.base.org \
  --broadcast --verify \
  --etherscan-api-key $BASESCAN_API_KEY
```

## After Deploy

Copy `out/Anchor.sol/Anchor.json` to `anchor-frontend/lib/Anchor.json`
Copy the deployed address to `anchor-frontend/lib/contract.ts`

## Contract
- **Network**: Base Mainnet / Base Sepolia
- **Address**: `0x — TBD after deploy`
- **Basescan**: https://sepolia.basescan.org/address/0x...
