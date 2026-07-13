// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./SRC5050Sender.sol";
import "./SRC5050Receiver.sol";

contract SRC5050 is SRC5050Sender, SRC5050Receiver {
    function _registerAction(bytes4 action) internal {
        _registerReceivable(action);
        _registerSendable(action);
    }
}
