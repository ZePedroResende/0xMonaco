// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "solmate/utils/SafeCastLib.sol";
import {Monaco} from "../../Monaco.sol";
import {BradburyBase} from "./Base.sol";

contract BradburyGoBananas is BradburyBase {
    using SafeCastLib for uint256;

    constructor()
        BradburyBase(Params({beg_accel_pct: 200, lag_accel_pct: 0, lag_banana_pct: 150, hodl_banana_pct: 150}))
    {}

    function sayMyName() external pure returns (string memory) {
        return "Bradbury-GoBananas";
    }
}
