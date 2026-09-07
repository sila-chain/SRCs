// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { ISRC173 } from "../interfaces/ISRC173.sol";
import { LibCento } from "../libraries/LibCento.sol";

/// @title Ownership
/// @notice Facet implementing the `ISRC173` ownership standard.
contract Ownership is ISRC173{

    /// @inheritdoc ISRC173
    function owner() external override view returns (address owner_) {
        owner_ = LibCento.contractOwner();
    }

    /// @inheritdoc ISRC173
    function transferOwnership(address _newOwner) external override {
        LibCento.enforceIsContractOwner();
        LibCento.setContractOwner(_newOwner);
    }
}
