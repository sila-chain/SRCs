// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.19;

import {
IXMLRepresentableStateVersionedHashed,
IXMLRepresentableState, IRepresentableStateVersioned, IRepresentableStateHashed     // needed for @inheritdoc
} from "../IRepresentableState.sol";

/**
 * @title Example XML-representable contract
 * @notice Simple "instrument" with state fields owner, notional, maturity, and active flag and
 *         and XML representation of its internal state using the generic IRepresentableState.sol
 *         schema.
 * @author Christian Fries
 */
contract MinimalInstrument is IXMLRepresentableStateVersionedHashed {
    address public owner;

    uint256 public notional;
    string  public currency;
    uint256 public maturityDate;
    bool    public active;

    uint256 private _stateVersion;

    event Updated(address indexed updater, uint256 newNotional, uint256 newMaturity, bool newActive);

    constructor(address _owner, uint256 _notional, uint256 _maturityDate) {
        owner = _owner;
        notional = _notional;
        currency = "EUR";
        maturityDate = _maturityDate;
        active = true;
        _stateVersion = 1;
    }

    function update(uint256 _notional, uint256 _maturityDate, bool _active) external {
        require(msg.sender == owner, "not owner");
        notional = _notional;
        maturityDate = _maturityDate;
        active = _active;
        _stateVersion += 1;
        emit Updated(msg.sender, _notional, _maturityDate, _active);
    }

    // --- IRepresentableState.sol ---

    /// @inheritdoc IXMLRepresentableState
    function stateXmlTemplate() external pure override returns (string memory) {
        // Note: formatted as a single string for simplicity; newlines are optional.
        return
                    "<Contract xmlns='urn:example:contract'"
                    " xmlns:svmstate='urn:svm:state:1.0'"
                    " svmstate:chain-id=''"
                    " svmstate:contract-address=''"
                    " svmstate:block-number=''>"

                    "<Instrument xmlns='urn:example:format-showcase'>"
                    " xmlns:svmstate='urn:svm:state:1.0'>"
                    "<Owner svmstate:call='owner()(address)' svmstate:format='address'/>"
                    "<Notional"
                    " svmstate:calls='notional()(uint256);currency()(string)'"
                    " svmstate:formats='decimal;string'"
                    " svmstate:targets=';currency'/>"
                    "<MaturityDate svmstate:call='maturityDate()(uint256)' svmstate:format='iso8601-date'/>"
                    "<Active svmstate:call='active()(bool)' svmstate:format='boolean'/>"
                    "</Instrument>"
                    "</Contract>";
    }

    /// @inheritdoc IRepresentableStateVersioned
    function stateVersion() external view override returns (uint256) {
        return _stateVersion;
    }

    /// @inheritdoc IRepresentableStateHashed
    function stateHash() external view override returns (bytes32) {
        // Canonical encoding of the state relevant to the XML representation.
        return keccak256(abi.encode(owner, notional, maturityDate, active));
    }
}

