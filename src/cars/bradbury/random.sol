// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Monaco} from "../../Monaco.sol";
import {BradburyBase} from "./Base.sol";

contract BradburyV2_001 is BradburyBase {
    constructor()
        BradburyBase(
            "v2-001",
            Params({
                first_turn_accel: 0,
                beg_accel_pct: 500,
                lag_accel_pct: 0,
                lag_banana_pct: 120,
                lag_target_spend_pct: 90,
                hodl_banana_pct: 120,
                hodl_target_spend_pct: 90,
                blitz_accel_pct: 300
            })
        )
    {}
}
