// contract name
export const SRC20_EXPIRABLE_CONTRACT = "MockSRC20Expirable";

// constructor parameters
export const SRC20_NAME = "PointToken";
export const SRC20_SYMBOL = "POINT";

export const YEAR_IN_MILLISECONDS = 31_556_926_000;

// custom error
export const ERROR_SRC20_INVALID_SENDER = "SRC20InvalidSender";
export const ERROR_SRC20_INVALID_RECEIVER = "SRC20InvalidReceiver";
export const ERROR_SRC20_INSUFFICIENT_BALANCE = "SRC20InsufficientBalance";
export const ERROR_SRC20_INVALID_APPROVER = "SRC20InvalidApprover";
export const ERROR_SRC20_INVALID_SPENDER = "SRC20InvalidSpender";
export const ERROR_SRC20_INSUFFICIENT_ALLOWANCE = "SRC20InsufficientAllowance";
export const ERROR_SRC7818_TRANSFER_EXPIRED = "SRC7818TransferredExpiredToken";
export const ERROR_SRC7818_INVALID_EPOCH = "SRC7818InvalidEpoch";

// events
export const EVENT_TRANSFER = "Transfer";
export const EVENT_APPROVAL = "Approval";

export interface SlidingWindowState {
  initialBlockNumber: Number;
  blocksPerEpoch: Number;
  windowSize: Number;
}
