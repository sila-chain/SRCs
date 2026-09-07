// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

abstract contract SIP712Domain {
    /**
     * @dev SIP712 Domain Separator
     */
    bytes32 public DOMAIN_SEPARATOR;
}