# SRC-8226: Regulated Agent Mandate (RAMS) reference implementation

Reference implementation for SRC-8226. Under development.

## Layout

| Path | Contents |
|---|---|
| `contracts/interfaces/IAgentMandate.sol` | Mandate lifecycle, recording, freeze, and view interface |
| `contracts/interfaces/IComplianceProvider.sol` | Principal eligibility interface |
| `contracts/interfaces/IAgentExecutor.sol` | Optional account-side executor interface |
| `contracts/AgentMandate.sol` | RAMS registry (reference implementation) |
| `contracts/ComplianceProvider.sol` | Reference compliance provider |
| `contracts/AgentExecutor.sol` | Reference executor (optional venue) |
| `contracts/regulated-asset-mock/ISRC7943.sol` | SRC-7943 interface (vendored, used by the tests) |
| `contracts/regulated-asset-mock/uRWA20.sol` | SRC-7943 uRWA-20 regulated asset (vendored, used by the tests) |
| `test/` | Foundry tests |

## Build

```sh
forge build
forge test
```
