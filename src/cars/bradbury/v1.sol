// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "solmate/utils/SafeCastLib.sol";
import {Monaco} from "../../Monaco.sol";
import {BradburyBase} from "./Base.sol";

contract BradburyV1 is BradburyBase {
    using SafeCastLib for uint256;

    function beg_accel_mul() internal view override returns (uint256) {
        return 5;
    }

    function sayMyName() external pure returns (string memory) {
        return "Bradbury-v1";
    }
}