# SRC-7858

This is reference implementation of SRC-7858

## Implementation Describe

### Per-Token Expiry

Default `SRC7858` is each token has its own independent start and end date, stored using `block.timestamp` or `block.number`. This provides flexibility, allowing tokens to expire at different dates/blocks.

### Epoch-based Expiry

`SRC7858Epoch` similar to SRC-7818, this method enforces a shared lifetime duration for all tokens, ensuring they expire simultaneously. This can be useful for fixed-term subscriptions or time-based access control.

## Usage

#### Install Dependencies
```bash
yarn install
```

#### Compile the Contract
Compile the reference implementation
```bash
yarn compile
```

#### Run Tests
Execute the provided test suite to verify the contract's functionality and integrity
```bash
yarn test
```

### Cleaning Build Artifacts
To clean up compiled files and artifacts generated during testing or deployment
```bash
yarn clean
```
