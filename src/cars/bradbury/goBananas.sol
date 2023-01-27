// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "solmate/utils/SafeCastLib.sol";
import {Monaco} from "../../Monaco.sol";
import {BradburyBase} from "./Base.sol";

contract BradburyGoBananas is BradburyBase {
    using SafeCastLib for uint256;

    function onStratLag(Monaco monaco, TurnState memory state) internal override {
        uint256 self_next_pos = state.self.y + state.self.speed;
        uint256 other_next_pos = state.front_car.y + state.front_car.speed;

        // if is accel expensive, and next guy is too fast or too far in front?
        // TODO tweak this value?
        if (monaco.getAccelerateCost(1) > ACCEL_FLOOR * 3) {
            if (
                (
                    state.front_car.speed > state.self.speed + 8
                        || (state.front_car.speed > 1 && other_next_pos > self_next_pos + 50)
                )
            ) {
                // nuke 'em hard
                maybe_buy_any_shell_kind(monaco, state, SHELL_FLOOR * 5, state.front_car);
            } else if (
                (
                    state.front_car.speed > state.self.speed + 2
                        || (state.front_car.speed > 1 && other_next_pos > self_next_pos + 20)
                )
            ) {
                // nuke 'em, but not so hard
                maybe_buy_any_shell_kind(monaco, state, SHELL_FLOOR * 3, state.front_car);
            }
        }

        // TODO do we want to check our budget here?

        // if we're in second and we have speed?
        // TODO tweak this value
        if (state.self_index == 1 && state.self.speed > 10) {
            //   2nd and is a banana worth it?.maybe buy one?
            //   if no banana, is a shield VERY cheap?.maybe buy one?
            uint256 bought = maybe_banana(monaco, state, BANANA_FLOOR * 15 / 10);

            if (bought == 0) {
                maybe_buy_shield(monaco, state, 1, SHIELD_FLOOR / 2);
            }
            aggressive_shell_gouging(monaco, state);
        }
    }

    function onStratHodl(Monaco monaco, TurnState memory state) internal override {
        maybe_banana(monaco, state, BANANA_FLOOR * 15 / 10);
        aggressive_shell_gouging(monaco, state);
    }

    function sayMyName() external pure returns (string memory) {
        return "Bradbury-GoBananas";
    }
}
