// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.19;

import {
IXMLRepresentableStateVersionedHashed,
IXMLRepresentableState,         // needed for @inheritdoc
IRepresentableStateVersioned,   // needed for @inheritdoc
IRepresentableStateHashed       // needed for @inheritdoc
} from "../IRepresentableState.sol";

/**
 * @title TestContract
 * @notice Contract to demonstrate and test data types, formats and array bindings
 *         for IRepresentableState.sol renderers.
 *
 * Fields are initialized with demo values in the constructor so that an off-chain renderer
 * can immediately exsrcise different type/format combinations without any prior updates.
 */
contract TestContract is IXMLRepresentableStateVersionedHashed {

    address public immutable owner;

    // Unsigned integers
    uint256 public valueUint;           // e.g. 123456789
    uint256 public valueMoney;          // e.g. 123456 (scale 2 -> 1234.56)
    uint256 public valueRateBP;         // e.g. 25000 (scale 4 -> 2.5000%)
    uint256 public valueHex;            // e.g. 0xdeadbeef
    uint256 public timestampDate;       // UNIX ts -> iso8601-date
    uint256 public timestampDateTime;   // UNIX ts -> iso8601-datetime

    // Signed integers
    int256  public valueIntPos;         // +123456
    int256  public valueIntNeg;         // -123456

    // Address
    address public exampleAddress;

    // Bool
    bool    public flagTrue;
    bool    public flagFalse;

    // String
    string  public textPlain;

    // Bytes
    bytes   public dataBytes;

    // Currency for multi-binding
    string  public currency;

    // --- Arrays for array binding profile (Mode B) ---------------------------------------------

    // e.g. coupon amounts (scale 2 -> 1000.00, 2500.00, ...)
    int256[] public couponAmounts;

    // matching labels for the coupons
    string[] public couponLabels;

    // XML state version (for versioned extension)
    uint256 private _stateVersion;

    constructor(address _owner) {
        owner = _owner;

        // Unsigned ints
        valueUint          = 123_456_789;
        valueMoney         = 123_456;        // 1234.56 with scale=2
        valueRateBP        = 25_000;         // 2.5000% with scale=4
        valueHex           = 0xDEADBEEF;
        timestampDate      = 1735689600;     // 2025-01-01T00:00:00Z
        timestampDateTime  = 1735776000;     // 2025-01-02T00:00:00Z

        // Signed ints
        valueIntPos        = 123_456;
        valueIntNeg        = -123_456;

        // Address
        exampleAddress     = _owner;

        // Bools
        flagTrue           = true;
        flagFalse          = false;

        // String
        textPlain          = "Hello, XML & SAVM!";

        // Bytes
        dataBytes          = hex"0102030405DEADBEEF0102030405DEADBEEF0102030405DEADBEEF";

        // Currency for multi-binding
        currency           = "EUR";

        // Arrays for array binding demo
        couponAmounts.push(100_000);   // 1000.00 with scale 2
        couponAmounts.push(250_000);   // 2500.00 with scale 2
        couponAmounts.push(175_500);   // 1755.00 with scale 2

        couponLabels.push("Coupon 1");
        couponLabels.push("Coupon 2");
        couponLabels.push("Coupon 3");

        _stateVersion   = 1;
    }

    // --- IRepresentableState.sol ---

    /// @inheritdoc IXMLRepresentableState
    function stateXmlTemplate() external pure override returns (string memory) {
        // Note: single quotes in XML to allow double quotes in solidity for a single string-block.
        return
                    "<Contract xmlns='urn:example:contract'"
                    " xmlns:savmstate='urn:savm:state:1.0'"
                    " savmstate:chain-id=''"
                    " savmstate:contract-address=''"
                    " savmstate:block-number=''>"

                    "<TestContract xmlns='urn:example:format-showcase'>"

                    // ---- Unsigned Integers ----
                    "<UintRaw savmstate:call='valueUint()(uint256)' savmstate:format='integer'/>"
                    "<UintDecimal2 savmstate:call='valueMoney()(uint256)' savmstate:format='decimal' savmstate:scale='2'/>"
                    "<UintHex savmstate:call='valueHex()(uint256)' savmstate:format='hex'/>"

                    // Date/Datetime from UNIX timestamps (seconds since epoch)
                    "<Date savmstate:call='timestampDate()(uint256)' savmstate:format='iso8601-date'/>"
                    "<DateTime savmstate:call='timestampDateTime()(uint256)' savmstate:format='iso8601-datetime'/>"

                    // ---- Signed Integers ----
                    "<IntPos savmstate:call='valueIntPos()(int256)' savmstate:format='decimal'/>"
                    "<IntNeg savmstate:call='valueIntNeg()(int256)' savmstate:format='decimal'/>"

                    // ---- Address ----
                    "<ExampleAddress savmstate:call='exampleAddress()(address)' savmstate:format='address'/>"

                    // ---- Booleans ----
                    "<FlagTrue savmstate:call='flagTrue()(bool)' savmstate:format='boolean'/>"
                    "<FlagFalse savmstate:call='flagFalse()(bool)' savmstate:format='boolean'/>"

                    // ---- String ----
                    "<TextPlain savmstate:call='textPlain()(string)' savmstate:format='string'/>"

                    // ---- Bytes (hex + base64) ----
                    "<BytesHex savmstate:call='dataBytes()(bytes)' savmstate:format='hex'/>"
                    "<BytesBase64 savmstate:call='dataBytes()(bytes)' savmstate:format='base64'/>"

                    // ---- Multi-binding: amount as text, currency as attribute ----
                    "<Money"
                    " savmstate:calls='valueMoney()(uint256);currency()(string)'"
                    " savmstate:formats='decimal;string'"
                    " savmstate:scales='2;'"        // 2 decimals for amount, no scaling for currency
                    " savmstate:targets=';currency'/>"

                    // ---- Array binding profile (Mode B): scalar arrays -> repeated rows ----
                    "<ArrayExamples>"

                    // int256[] -> repeated <Coupon> with decimal+scale
                    "<Coupons"
                    " savmstate:call='couponAmounts()(int256[])'"
                    " savmstate:item-element='Coupon'>"
                    "<Coupon"
                    " savmstate:item-field='0'"
                    " savmstate:format='decimal'"
                    " savmstate:scale='2'/>"
                    "</Coupons>"

                    // string[] -> repeated <Label> with plain string
                    "<CouponLabels"
                    " savmstate:call='couponLabels()(string[])'"
                    " savmstate:item-element='Label'>"
                    "<Label"
                    " savmstate:item-field='0'"
                    " savmstate:format='string'/>"
                    "</CouponLabels>"

                    "</ArrayExamples>"

                    "</TestContract>"
                    "</Contract>";
    }

    /// @inheritdoc IRepresentableStateVersioned
    function stateVersion() external view override returns (uint256) {
        return _stateVersion;
    }

    /// @inheritdoc IRepresentableStateHashed
    function stateHash() external view override returns (bytes32) {
        // Einfach alle relevanten Felder in die Hash-Basis aufnehmen
        return keccak256(
            abi.encode(
                owner,
                valueUint,
                valueMoney,
                valueRateBP,
                valueHex,
                timestampDate,
                timestampDateTime,
                valueIntPos,
                valueIntNeg,
                exampleAddress,
                flagTrue,
                flagFalse,
                textPlain,
                dataBytes,
                currency,
                couponAmounts,
                couponLabels
            )
        );
    }
}
