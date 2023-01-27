// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "solmate/utils/SafeCastLib.sol";
import {Monaco} from "../../Monaco.sol";
import {BradburyBase} from "./Base.sol";

contract BradburySmallerEndBudget is BradburyBase {
    using SafeCastLib for uint256;

    constructor() BradburyBase(Params({beg_accel_mul: 2})) {}

    function hodl_target_spend_pct() internal view override returns (uint256) {
        return 100;
    }

    function lag_target_spend_pct() internal view override returns (uint256) {
        return 100;
    }

    function sayMyName() external pure returns (string memory) {
        return "Bradbury-SmallerEndBudget";
    }
}
