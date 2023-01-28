// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Monaco} from "../../Monaco.sol";
import {BradburyBase} from "./Base.sol";

contract BradburyGoBananas is BradburyBase {
    constructor()
        BradburyBase(
            "goBananas",
            Params({
                first_turn_accel: 11,
                beg_accel_pct: 200,
                lag_accel_pct: 0,
                lag_banana_pct: 150,
                lag_target_spend_pct: 90,
                hodl_banana_pct: 150,
                hodl_target_spend_pct: 90,
                blitz_accel_pct: 300
            })
        )
    {}
}
