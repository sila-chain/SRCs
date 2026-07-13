// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {ISRC7943Fungible} from "./ISRC7943.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {SRC20} from "@openzeppelin/contracts/token/SRC20/SRC20.sol";
import {ISRC20} from "@openzeppelin/contracts/token/SRC20/ISRC20.sol";
import {ISRC165} from "@openzeppelin/contracts/utils/introspection/ISRC165.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";

/// @title uRWA-20 Token Contract
/// @notice An SRC-20 token implementation adhering to the ISRC-7943 interface for Real World Assets.
/// @dev Combines standard SRC-20 functionality with RWA-specific features like whitelisting,
/// controlled minting/burning, asset forced transfers, and freezing. Managed via AccessControl.
contract uRWA20 is Context, SRC20, AccessControlEnumerable, ISRC7943Fungible {
    /// @notice Role identifiers.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant FREEZING_ROLE = keccak256("FREEZING_ROLE");
    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");
    bytes32 public constant FORCE_TRANSFER_ROLE = keccak256("FORCE_TRANSFER_ROLE");

    /// @notice Mapping storing the send whitelist status for each account address.
    /// @dev True indicates the account is allowed to send tokens, false otherwise.
    mapping(address account => bool allowed) internal _sendWhitelist;

    /// @notice Mapping storing the receive whitelist status for each account address.
    /// @dev True indicates the account is allowed to receive tokens, false otherwise.
    mapping(address account => bool allowed) internal _receiveWhitelist;

    /// @notice Mapping storing the freezing status of assets for each account address.
    /// @dev It gives the amount of SRC-20 tokens frozen in `account` wallet.
    mapping(address account => uint256 amount) internal _frozenTokens;

    /// @notice Emitted when an account's send whitelist status is changed.
    /// @param account The address whose status was changed.
    /// @param status The new whitelist status (true = whitelisted, false = not whitelisted).
    event SendWhitelisted(address indexed account, bool status);

    /// @notice Emitted when an account's receive whitelist status is changed.
    /// @param account The address whose status was changed.
    /// @param status The new whitelist status (true = whitelisted, false = not whitelisted).
    event ReceiveWhitelisted(address indexed account, bool status);

    /// @notice Contract constructor.
    /// @dev Initializes the SRC-20 token with name and symbol, and grants all roles
    /// (Admin, Minter, Burner, Freezer, Force Transfer, Whitelist) to the `initialAdmin`.
    /// @param name The name of the token.
    /// @param symbol The symbol of the token.
    /// @param initialAdmin The address to receive initial administrative and operational roles.
    constructor(string memory name, string memory symbol, address initialAdmin) SRC20(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _grantRole(MINTER_ROLE, initialAdmin);
        _grantRole(BURNER_ROLE, initialAdmin);
        _grantRole(FREEZING_ROLE, initialAdmin);
        _grantRole(WHITELIST_ROLE, initialAdmin);
        _grantRole(FORCE_TRANSFER_ROLE, initialAdmin);
    }

    /// @inheritdoc ISRC7943Fungible
    function canTransfer(address from, address to, uint256 amount) public view virtual override returns (bool allowed) {
        uint256 frozen = getFrozenTokens(from);
        if (frozen > 0) {
            uint256 fromBalance = balanceOf(from);
            uint256 unfrozen = fromBalance > frozen ? fromBalance - frozen : 0;
            if (amount > unfrozen) return allowed;
        }
        if (!canSend(from) || !canReceive(to)) return allowed;
        allowed = true;
    }

    /// @inheritdoc ISRC7943Fungible
    function canSend(address account) public view virtual override returns (bool allowed) {
        allowed = _sendWhitelist[account];
    }

    /// @inheritdoc ISRC7943Fungible
    function canReceive(address account) public view virtual override returns (bool allowed) {
        allowed = _receiveWhitelist[account];
    }

    /// @inheritdoc ISRC7943Fungible
    function getFrozenTokens(address account) public view virtual override returns (uint256 amount) {
        amount = _frozenTokens[account];
    }

    /// @notice Updates the send whitelist status for a given account.
    /// @dev Can only be called by accounts holding the `WHITELIST_ROLE`.
    /// Emits a {SendWhitelisted} event upon successful update.
    /// @param account The address whose whitelist status is to be changed.
    /// @param status The new whitelist status (true = whitelisted, false = not whitelisted).
    function changeSendWhitelist(address account, bool status) external onlyRole(WHITELIST_ROLE) {
        _sendWhitelist[account] = status;
        emit SendWhitelisted(account, status);
    }

    /// @notice Updates the receive whitelist status for a given account.
    /// @dev Can only be called by accounts holding the `WHITELIST_ROLE`.
    /// Emits a {ReceiveWhitelisted} event upon successful update.
    /// @param account The address whose whitelist status is to be changed.
    /// @param status The new whitelist status (true = whitelisted, false = not whitelisted).
    function changeReceiveWhitelist(address account, bool status) external onlyRole(WHITELIST_ROLE) {
        _receiveWhitelist[account] = status;
        emit ReceiveWhitelisted(account, status);
    }

    /// @notice Creates `amount` new tokens and assigns them to `to`.
    /// @dev Can only be called by accounts holding the `MINTER_ROLE`.
    /// Requires `to` to be allowed according to {canReceive}.
    /// Emits a {Transfer} event with `from` set to the zero address.
    /// @param to The address that will receive the minted tokens.
    /// @param amount The amount of tokens to mint.
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    /// @notice Destroys `amount` tokens from the caller's account.
    /// @dev Can only be called by accounts holding the `BURNER_ROLE`.
    /// Emits a {Transfer} event with `to` set to the zero address.
    /// @param amount The amount of tokens to burn.
    function burn(uint256 amount) external onlyRole(BURNER_ROLE) {
        _burn(_msgSender(), amount);
    }

    /// @inheritdoc ISRC7943Fungible
    /// @dev Can only be called by accounts holding the `FREEZING_ROLE`
    function setFrozenTokens(address account, uint256 amount)
        public
        virtual
        override
        onlyRole(FREEZING_ROLE)
        returns (bool result)
    {
        _frozenTokens[account] = amount;
        emit Frozen(account, amount);
        result = true;
    }

    /// @inheritdoc ISRC7943Fungible
    /// @dev Can only be called by accounts holding the `FORCE_TRANSFER_ROLE`.
    function forcedTransfer(address from, address to, uint256 amount)
        public
        virtual
        override
        onlyRole(FORCE_TRANSFER_ROLE)
        returns (bool result)
    {
        require(to != address(0), SRC20InvalidReceiver(address(0)));
        require(from != address(0), SRC20InvalidSender(address(0)));
        require(canReceive(to), SRC7943CannotReceive(to));
        _excessFrozenUpdate(from, amount);
        super._update(from, to, amount); // Directly update balances, bypassing overridden _update
        emit ForcedTransfer(from, to, amount);
        result = true;
    }

    /// @notice Updates frozen token amount when a forced transfer or burn exceeds the unfrozen balance.
    /// @dev This function reduces the frozen token amount to ensure consistency when tokens are forcibly
    /// moved or burned beyond the unfrozen balance. Emits a {Frozen} event when frozen amount is reduced.
    /// @param account The address whose frozen tokens may need adjustment.
    /// @param amount The amount being forcibly transferred or burned.
    function _excessFrozenUpdate(address account, uint256 amount) internal {
        uint256 unfrozenBalance = _unfrozenBalance(account);
        if (amount > unfrozenBalance && amount <= balanceOf(account)) {
            _frozenTokens[account] -= amount - unfrozenBalance;
            emit Frozen(account, getFrozenTokens(account));
        }
    }

    /// @notice Calculates the unfrozen token balance for an account.
    /// @dev Returns the amount of tokens that are available for transfer, which is the total balance
    /// minus the frozen amount. If frozen tokens exceed the balance, returns 0 to prevent underflow.
    /// This is a helper function used throughout the contract for transfer validation.
    /// @param account The address to calculate unfrozen balance for.
    /// @return unfrozenBalance The amount of tokens available for transfer.
    function _unfrozenBalance(address account) internal view returns (uint256 unfrozenBalance) {
        unfrozenBalance =
            balanceOf(account) < getFrozenTokens(account) ? 0 : balanceOf(account) - getFrozenTokens(account);
    }

    /// @notice Hook that is called during any token transfer, including minting and burning.
    /// @dev Overrides the SRC-20 `_update` hook. Enforces transfer restrictions based on {canTransfer}, {canSend} and {canReceive} logic.
    /// Reverts with {SRC7943InsufficientUnfrozenBalance} | {SRC7943CannotSend} | {SRC7943CannotReceive} if any check fails.
    /// @param from The address sending tokens (zero address for minting).
    /// @param to The address receiving tokens (zero address for burning).
    /// @param amount The amount being transferred.
    function _update(address from, address to, uint256 amount) internal virtual override {
        if (from != address(0) && to != address(0)) {
            // Transfer
            uint256 unfrozenFromBalance = _unfrozenBalance(from);
            uint256 fromBalance = balanceOf(from);
            require(fromBalance >= amount, SRC20InsufficientBalance(from, fromBalance, amount));
            require(
                amount <= unfrozenFromBalance, SRC7943InsufficientUnfrozenBalance(from, amount, unfrozenFromBalance)
            );
            require(canSend(from), SRC7943CannotSend(from));
            require(canReceive(to), SRC7943CannotReceive(to));
        } else if (from == address(0)) {
            // Mint
            require(canReceive(to), SRC7943CannotReceive(to));
        } else {
            // Burn
            require(canSend(from), SRC7943CannotSend(from));
            _excessFrozenUpdate(from, amount);
        }

        super._update(from, to, amount);
    }

    /// @dev Mock-only: a dynamic arg before `amount` lets tests exsrcise the executor's amount-by-index decode.
    function swap(uint256 a, uint256[] calldata t, uint256 amount) external {}

    /// @notice See {ISRC165-supportsInterface}.
    /// @dev Indicates support for the {ISRC7943Fungible} interface in addition to inherited interfaces.
    /// @param interfaceId The interface identifier, as specified in SRC-165.
    /// @return True if the contract implements `interfaceId`, false otherwise.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ISRC165)
        returns (bool)
    {
        return interfaceId == type(ISRC7943Fungible).interfaceId || interfaceId == type(ISRC20).interfaceId
            || super.supportsInterface(interfaceId);
    }
}
