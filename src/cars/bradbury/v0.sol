// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "solmate/utils/SafeCastLib.sol";
import {Monaco} from "../../Monaco.sol";
import {BradburyBase} from "./Base.sol";

contract BradburyV0 is BradburyBase {
    using SafeCastLib for uint256;

    function sayMyName() external pure returns (string memory) {
        return "Bradbury-v0";
    }
}
