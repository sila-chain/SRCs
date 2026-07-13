# SIP-5725: Transferrable Vesting NFT - Reference Implementation

This repository serves as a reference implementation for **SIP-5725 Transferrable Vesting NFT Standard**. A Non-Fungible Token (NFT) standard used to vest SRC-20 tokens over a vesting release curve.

## Contents

- [SIP-5725 Specification](./contracts/ISRC5725.sol): Interface and definitions for the SIP-5725 specification.
- [SRC-5725 Implementation (abstract)](./contracts/SRC5725.sol): SRC-5725 contract which can be extended to implement the specification.
- [VestingNFT Implementation](./contracts/reference/LinearVestingNFT.sol): Full SRC-5725 implementation using cliff vesting curve.
- [LinearVestingNFT Implementation](./contracts/reference/VestingNFT.sol): Full SRC-5725 implementation using linear vesting curve.
