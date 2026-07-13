// SPDX-License-Identifier: CC0-1.0

pragma solidity >=0.5.0;

interface IWSIL {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}
