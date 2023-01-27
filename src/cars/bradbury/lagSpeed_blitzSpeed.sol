// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "solmate/utils/SafeCastLib.sol";
import {Monaco} from "../../Monaco.sol";
import {BradburyBase} from "./Base.sol";

contract BradburyLagSpeedBlitzSpeed is BradburyBase {
    using SafeCastLib for uint256;

    function lag_accel_mul() internal view override returns (uint256) {
        return 6;
    }

    function blitz_accel_mul() internal view override returns (uint256) {
        return 5;
    }

    function sayMyName() external pure returns (string memory) {
        return "Bradbury-LagSpeedBlitzSpeed";
    }
}
