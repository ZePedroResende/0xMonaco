// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "solmate/utils/SafeCastLib.sol";
import {Monaco} from "../../Monaco.sol";
import {BradburyBase} from "./Base.sol";

contract BradburyGoBananas is BradburyBase {
    using SafeCastLib for uint256;

    constructor() BradburyBase(Params({beg_accel_mul: 2})) {}

    function lag_banana_mul() internal view override returns (uint256) {
        return 150;
    }

    function hodl_banana_mul() internal view override returns (uint256) {
        return 150;
    }

    function sayMyName() external pure returns (string memory) {
        return "Bradbury-GoBananas";
    }
}
