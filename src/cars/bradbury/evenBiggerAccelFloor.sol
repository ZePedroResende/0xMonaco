// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "solmate/utils/SafeCastLib.sol";
import {Monaco} from "../../Monaco.sol";
import {BradburyBase} from "./Base.sol";

contract BradburyEvenBiggerAccelFloor is BradburyBase {
    using SafeCastLib for uint256;

    constructor() BradburyBase(Params({beg_accel_mul: 6})) {}

    function sayMyName() external pure returns (string memory) {
        return "Bradbury-evenBiggerAccelFloor";
    }
}
