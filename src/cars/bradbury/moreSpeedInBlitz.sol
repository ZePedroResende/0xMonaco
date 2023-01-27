// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "solmate/utils/SafeCastLib.sol";
import {Monaco} from "../../Monaco.sol";
import {BradburyBase} from "./Base.sol";

contract BradburySpeedInBlitz is BradburyBase {
    using SafeCastLib for uint256;

    function onStratBlitzkrieg(Monaco monaco, TurnState memory state) internal override {
        if (try_finish_right_now(monaco, state)) return;

        //.buy_accel_at_max(monaco, state, ACCEL_FLOOR * ACCEL_BLITZKRIEG_MUL);

        // TODO
        if (state.self_index != 0) {
            // priority 1, buy a shell or supershell if we're not first, and if the first is not shielded
            maybe_buy_any_shell_kind(monaco, state, SHELL_FLOOR * 5, state.front_car);
        }

        uint256 shields_needed = compute_shields_needed(monaco, state.self_index, state.back_car);

        // if we're 1st, we skip the condition "if we're close to the front car"
        uint256 distance_to_front_car = type(uint256).max;
        if (state.front_car.y > state.self.y) {
            distance_to_front_car = state.front_car.y - state.self.y;
        }

        // if we can finish in the next 3 rounds, invest in a shield
        if (state.self.y + state.self.speed * 3 >= 1000) {
            maybe_buy_shield(monaco, state, shields_needed, SHIELD_FLOOR * 5);
            tiny_gouge_super_shell(monaco, state, SHIELD_FLOOR * 5);
        }

        // if we're in first, and 2nd is faster, slow him down
        if (state.self_index == 0 && state.back_car.speed > state.self.speed) {
            maybe_banana(monaco, state, BANANA_FLOOR * 2);
        }

        // try to maintain some speed if we're slow
        if (state.self.speed < 10) {
            buy_accel_at_max(monaco, state, ACCEL_FLOOR * 5);
        }
    }

    function sayMyName() external pure returns (string memory) {
        return "Bradbury-speedInBlitz";
    }
}
