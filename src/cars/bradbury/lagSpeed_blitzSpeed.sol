// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "solmate/utils/SafeCastLib.sol";
import {Monaco} from "../../Monaco.sol";
import {BradburyBase} from "./Base.sol";

contract BradburyLagSpeedBlitzSpeed is BradburyBase {
    using SafeCastLib for uint256;

    function takeYourTurn(
        Monaco monaco,
        Monaco.CarData[] calldata allCars,
        uint256[] calldata, /*bananas*/
        uint256 self_index
    ) external override {
        //
        // setup vars
        //
        Monaco.CarData memory self = allCars[self_index];
        Monaco.CarData memory front_car;
        if (self_index > 0) front_car = allCars[self_index - 1];
        Monaco.CarData memory back_car;

        TurnState memory state = TurnState({
            self_index: self_index,
            self: self,
            front_car: front_car,
            back_car: back_car,
            leading: self_index == 0,
            initialBalance: self.balance,
            balance: self.balance,
            speed: self.speed,
            y: self.y,
            pctLeft: self.balance * 100 / INITIAL_BALANCE,
            remainingTurns: 0,
            targetSpend: 0
        });
        Strat strat = Strat.LAG;

        if (monaco.turns() == 1) {
            // we have 1st move advantage
            state.balance -= monaco.buyAcceleration(11);
            state.speed += 11;
        }

        // define more state depending on race stage
        if (allCars[0].y >= BLITZKRIEG) {
            // leader is almost at the end! blitzkrieg regardless
            // of if the leader is us or someone else
            strat = Strat.BLITZKRIEG;

            // we spend 100% of our budget per turn
            state.remainingTurns = self.speed > 0 ? (1000 - self.y) / self.speed : 1000;
            if (state.remainingTurns == 0) state.remainingTurns = 1;
            state.targetSpend = state.initialBalance / state.remainingTurns;
        } else if (self_index == 0) {
            // we're in 1st, try to hold our position
            strat = Strat.HODL;

            // try and spend 70% of our per-turn budget
            // leave some overhead for blitzkrieg
            state.remainingTurns = self.speed > 0 ? (800 - self.y) / self.speed : 800;
            if (state.remainingTurns == 0) state.remainingTurns = 1;
            state.targetSpend = state.initialBalance / state.remainingTurns * 9 / 10;
        } else {
            // we're in 2nd or 3rd, lag behind the next car
            strat = Strat.LAG;
            front_car = allCars[self_index - 1];

            state.remainingTurns = self.speed > 0 ? (800 - self.y) / self.speed : 800;
            if (state.remainingTurns == 0) state.remainingTurns = 1;
            state.targetSpend = state.initialBalance / state.remainingTurns * 9 / 10;
        }

        // priority: try to sweep floor on acceleration
        // TODO adjust this value
        buy_accel_at_max(monaco, state, ACCEL_FLOOR * 2);

        if (strat == Strat.LAG) {
            //
            // LAG strat
            //
            uint256 self_next_pos = self.y + self.speed;
            uint256 other_next_pos = front_car.y + front_car.speed;

            buy_accel_at_max(monaco, state, ACCEL_FLOOR * 6);

            // if is accel expensive, and next guy is too fast or too far in front?
            // TODO tweak this value?
            if (monaco.getAccelerateCost(1) > ACCEL_FLOOR * 3) {
                if ((front_car.speed > self.speed + 8 || (front_car.speed > 1 && other_next_pos > self_next_pos + 50)))
                {
                    // nuke 'em hard
                    maybe_buy_any_shell_kind(monaco, state, SHELL_FLOOR * 5, front_car);
                } else if (
                    (front_car.speed > self.speed + 2 || (front_car.speed > 1 && other_next_pos > self_next_pos + 20))
                ) {
                    // nuke 'em, but not so hard
                    maybe_buy_any_shell_kind(monaco, state, SHELL_FLOOR * 3, front_car);
                }
            }

            // TODO do we want to check our budget here?

            // if we're in second and we have speed?
            // TODO tweak this value
            if (self_index == 1 && self.speed > 10) {
                //   2nd and is a banana worth it?.maybe buy one?
                //   if no banana, is a shield VERY cheap?.maybe buy one?
                uint256 bought = maybe_banana(monaco, state, BANANA_FLOOR * 12 / 10);

                if (bought == 0) {
                    maybe_buy_shield(monaco, state, 1, SHIELD_FLOOR / 2);
                }
                aggressive_shell_gouging(monaco, state);
            }
        } else if (strat == Strat.HODL) {
            //
            // HODL strat
            //
            maybe_banana(monaco, state, BANANA_FLOOR * 12 / 10);
            aggressive_shell_gouging(monaco, state);
            // get the cost of banana, save that money
            //.aggresive gouging of shells & super shells up to floor * 2
            // buy a banana, *after the shells*
        } else {
            //
            // BLITZKRIEG strat
            //
            if (try_finish_right_now(monaco, state)) return;

            //.buy_accel_at_max(monaco, state, ACCEL_FLOOR * ACCEL_BLITZKRIEG_MUL);

            // TODO
            if (self_index != 0) {
                // priority 1, buy a shell or supershell if we're not first, and if the first is not shielded
                maybe_buy_any_shell_kind(monaco, state, SHELL_FLOOR * 5, front_car);
            }

            uint256 shields_needed = compute_shields_needed(monaco, self_index, back_car);

            // if we're 1st, we skip the condition "if we're close to the front car"
            uint256 distance_to_front_car = type(uint256).max;
            if (front_car.y > self.y) {
                distance_to_front_car = front_car.y - self.y;
            }

            // if we can finish in the next 3 rounds, invest in a shield
            if (self.y + self.speed * 3 >= 1000) {
                maybe_buy_shield(monaco, state, shields_needed, SHIELD_FLOOR * 5);
                tiny_gouge_super_shell(monaco, state, SHIELD_FLOOR * 5);
            }

            // if we're in first, and 2nd is faster, slow him down
            if (self_index == 0 && back_car.speed > self.speed) {
                maybe_banana(monaco, state, BANANA_FLOOR * 2);
            }

            // try to maintain some speed if we're slow
            if (self.speed < 20) {
                buy_accel_at_max(monaco, state, ACCEL_FLOOR * 5);
            }
        }

        accel_with_remaining_budget_for_turn(monaco, state);
    }

    function sayMyName() external pure returns (string memory) {
        return "Bradbury-LagSpeedBlitzSpeed";
    }
}
