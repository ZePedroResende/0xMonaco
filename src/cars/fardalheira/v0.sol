// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "solmate/utils/SafeCastLib.sol";
import {Monaco} from "../../Monaco.sol";
import {FardalheiraBase} from "./Base.sol";

contract FardalheiraV0a is FardalheiraBase {
    using SafeCastLib for uint256;

    constructor()
        FardalheiraBase(
            "v0a",
            Params({
                first_turn_accel: 11,
                beg_accel_pct: 200,
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

contract FardalheiraV0b is FardalheiraBase {
    using SafeCastLib for uint256;

    constructor()
        FardalheiraBase(
            "v0b",
            Params({
                first_turn_accel: 11,
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

contract FardalheiraV0c is FardalheiraBase {
    using SafeCastLib for uint256;

    constructor()
        FardalheiraBase(
            "v0c",
            Params({
                first_turn_accel: 11,
                beg_accel_pct: 600,
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

contract FardalheiraV0d is FardalheiraBase {
    using SafeCastLib for uint256;

    constructor()
        FardalheiraBase(
            "v0d",
            Params({
                first_turn_accel: 0,
                beg_accel_pct: 600,
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

contract FardalheiraV0e is FardalheiraBase {
    using SafeCastLib for uint256;

    constructor()
        FardalheiraBase(
            "v0e",
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
