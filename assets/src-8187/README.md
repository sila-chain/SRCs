# SRC-8187 Token Puller — Reference Implementation

Reference implementation for Token Puller, a standardized interface for permissioned, on-demand token pulls with custom sourcing logic, permit support, and allowance delegation.

## Overview

A **Puller** contract acts as an intermediary that:

- Manages pull allowances granted by owners to spenders
- Executes custom sourcing logic to obtain tokens (e.g., withdrawing from a vault)
- Transfers the sourced tokens to a requested destination
- Supports SIP-712 signed permits and allowance delegation

## Project Structure

```
contracts/
├── interfaces/IPuller.sol         — Full SRC-8187 interface with natspec docs
├── base/BasePuller.sol            — Abstract base: approvals, SIP-712 permits, allowance delegation
└── pullers/SRC4626Puller.sol      — Sources tokens via SRC-4626 vault withdrawal
```

### IPuller

The interface defining all events (`PullApproval`, `TokensPulled`, `TransferPullAllowance`) and functions (`approvePull`, `pullFrom`, `pullAllowance`, `maxPullable`, `transferPullAllowance`, `permitPull`, `pullFromWithPermit`, `sip712Domain`, `nonces`)

See [IPuller.sol](./contracts/interfaces/IPuller.sol).

### BasePuller

Abstract base contract implementing:

- Allowance storage and consumption with infinite-allowance skip
- `transferPullAllowance` with special infinite-allowance transfer and renunciation (`toSpender == address(0)`)
- `permitPull` via SIP-712 (`ECDSA.recoverCalldata` for EOA signatures)
    - **TODO**: Support for SRC-6492 (universal signature validation) and SRC-1271 (smart contract wallets)
- `pullFromWithPermit` with front-run DoS protection (silent permit failure fallback)
- Abstract `_sourceTokens(address token, address owner, address to, uint256 amount)` and `maxPullable`

Uses OpenZeppelin's `SIP712` for domain separators, `ECDSA` for signature recovery, and `SafeSRC20` for token transfers.

See [BasePuller.sol](./contracts/base/BasePuller.sol).

### SRC4626Puller

Concrete puller paired with a single SRC-4626 vault. Its `_sourceTokens` calls `vault.withdraw(amount, to, owner)` — the vault's own SRC-20 allowance mechanism consumes the owner's share approval, burns shares, and sends the underlying asset directly to the destination.

See [SRC4626Puller.sol](./contracts/pullers/SRC4626Puller.sol).
