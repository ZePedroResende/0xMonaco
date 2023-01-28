// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Monaco} from "../../Monaco.sol";
import {BradburyBase} from "./Base.sol";

contract BradburyBiggerBetter is BradburyBase {
    constructor()
        BradburyBase(
            "biggerBetter",
            Params({
                first_turn_accel: 11,
                beg_accel_pct: 600,
                lag_accel_pct: 0,
                lag_banana_pct: 120,
                lag_target_spend_pct: 80,
                hodl_banana_pct: 120,
                hodl_target_spend_pct: 80,
                blitz_accel_pct: 300
            })
        )
    {}
}
