// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.21;

// ISRC7579AccountConfig and ISRC7579ModuleConfig are as defined in SRC-7579.

interface ISRC8286FrameAccount is ISRC7579AccountConfig, ISRC7579ModuleConfig {
    // Selects an installed frame validator (module type id 11, TBD), masks its approval mode
    // with the frame's allowed scope, clears the execution bit if the transaction's SENDER
    // frames present an unsupported execution mode (supportsExecutionMode), then calls APPROVE.
    // MUST revert if the executing frame's mode is not VERIFY.
    // MUST NOT call APPROVE if validation fails (leaving the mode at APPROVE_NONE).
    function verify(bytes calldata data) external returns (uint8 approvalMode);

    function supportsApprovalMode(uint8 approvalMode) external view returns (bool);
}
