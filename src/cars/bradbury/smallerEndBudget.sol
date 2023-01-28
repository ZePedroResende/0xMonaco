// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Monaco} from "../../Monaco.sol";
import {BradburyBase} from "./Base.sol";

contract BradburySmallerEndBudget is BradburyBase {
    constructor()
        BradburyBase(
            "smallerEndBudget",
            Params({
                first_turn_accel: 11,
                beg_accel_pct: 200,
                lag_accel_pct: 0,
                lag_banana_pct: 120,
                lag_target_spend_pct: 100,
                hodl_banana_pct: 120,
                hodl_target_spend_pct: 100,
                blitz_accel_pct: 300
            })
        )
    {}
}
