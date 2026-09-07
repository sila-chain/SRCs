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
 * can immediately exercise different type/format combinations without any prior updates.
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
        textPlain          = "Hello, XML & SVM!";

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
                    " xmlns:svmstate='urn:svm:state:1.0'"
                    " svmstate:chain-id=''"
                    " svmstate:contract-address=''"
                    " svmstate:block-number=''>"

                    "<TestContract xmlns='urn:example:format-showcase'>"

                    // ---- Unsigned Integers ----
                    "<UintRaw svmstate:call='valueUint()(uint256)' svmstate:format='integer'/>"
                    "<UintDecimal2 svmstate:call='valueMoney()(uint256)' svmstate:format='decimal' svmstate:scale='2'/>"
                    "<UintHex svmstate:call='valueHex()(uint256)' svmstate:format='hex'/>"

                    // Date/Datetime from UNIX timestamps (seconds since epoch)
                    "<Date svmstate:call='timestampDate()(uint256)' svmstate:format='iso8601-date'/>"
                    "<DateTime svmstate:call='timestampDateTime()(uint256)' svmstate:format='iso8601-datetime'/>"

                    // ---- Signed Integers ----
                    "<IntPos svmstate:call='valueIntPos()(int256)' svmstate:format='decimal'/>"
                    "<IntNeg svmstate:call='valueIntNeg()(int256)' svmstate:format='decimal'/>"

                    // ---- Address ----
                    "<ExampleAddress svmstate:call='exampleAddress()(address)' svmstate:format='address'/>"

                    // ---- Booleans ----
                    "<FlagTrue svmstate:call='flagTrue()(bool)' svmstate:format='boolean'/>"
                    "<FlagFalse svmstate:call='flagFalse()(bool)' svmstate:format='boolean'/>"

                    // ---- String ----
                    "<TextPlain svmstate:call='textPlain()(string)' svmstate:format='string'/>"

                    // ---- Bytes (hex + base64) ----
                    "<BytesHex svmstate:call='dataBytes()(bytes)' svmstate:format='hex'/>"
                    "<BytesBase64 svmstate:call='dataBytes()(bytes)' svmstate:format='base64'/>"

                    // ---- Multi-binding: amount as text, currency as attribute ----
                    "<Money"
                    " svmstate:calls='valueMoney()(uint256);currency()(string)'"
                    " svmstate:formats='decimal;string'"
                    " svmstate:scales='2;'"        // 2 decimals for amount, no scaling for currency
                    " svmstate:targets=';currency'/>"

                    // ---- Array binding profile (Mode B): scalar arrays -> repeated rows ----
                    "<ArrayExamples>"

                    // int256[] -> repeated <Coupon> with decimal+scale
                    "<Coupons"
                    " svmstate:call='couponAmounts()(int256[])'"
                    " svmstate:item-element='Coupon'>"
                    "<Coupon"
                    " svmstate:item-field='0'"
                    " svmstate:format='decimal'"
                    " svmstate:scale='2'/>"
                    "</Coupons>"

                    // string[] -> repeated <Label> with plain string
                    "<CouponLabels"
                    " svmstate:call='couponLabels()(string[])'"
                    " svmstate:item-element='Label'>"
                    "<Label"
                    " svmstate:item-field='0'"
                    " svmstate:format='string'/>"
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
