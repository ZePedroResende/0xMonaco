// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./../interfaces/ICar.sol";
import "solmate/utils/SafeCastLib.sol";

contract Bradbury is ICar {
    using SafeCastLib for uint256;

    uint256 internal constant LATE_GAME = 600;
    uint256 internal constant BLITZKRIEG = 800; // all-out spending
    uint256 internal constant INITIAL_BALANCE = 17500;

    uint256 internal constant INIT_ACCEL_COST = 12;

    uint256 internal constant ACCEL_FLOOR = 15;
    uint256 internal constant SHELL_FLOOR = 200;
    uint256 internal constant SUPER_SHELL_FLOOR = 300;
    uint256 internal constant SHIELD_FLOOR = 400;
    uint256 internal constant BANANA_FLOOR = 200;

    uint256 internal constant ACCEL_HODL_MUL = 5;
    uint256 internal constant ACCEL_BLITZKRIEG_MUL = 10;

    //
    // in Lag mode, we're in 3rd position
    //
    // we value speed highly if we're too far from the 2nd
    uint256 internal constant LAG_PREMIUM_TOO_FAR = 30;
    // we value speed even more highly if we're near but going slower
    // how much extra we're willing to spend per accel if we're near 2nd but slower
    uint256 internal constant LAG_PREMIUM_NEAR_BUT_SLOWER = 3;
    // how much distance we want at most from the 2nd player
    uint256 internal constant LAG_MAX_DESIRED_SPACING = 20;

    enum Strat {
        LAG, // stick to 3rd place, but close enough to 2nd car
        HODL, // hold your spot
        BLITZKRIEG // all out war
    }

    struct TurnState {
        bool leading;
        uint256 speed;
        uint256 initialBalance;
        uint256 balance;
        uint256 y;
        uint256 pctLeft;
        uint256 remainingTurns;
        uint256 targetSpend;
    }

    function takeYourTurn(
        Monaco monaco,
        Monaco.CarData[] calldata allCars,
        uint256[] calldata bananas,
        uint256 self_index
    ) external {
        //
        // setup vars
        //
        Monaco.CarData memory self = allCars[self_index];
        Monaco.CarData memory front_car;
        if (self_index > 0) front_car = allCars[self_index - 1];
        Monaco.CarData memory back_car;

        TurnState memory state = TurnState({
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

        //
        // first move
        // inspired by https://gist.github.com/xBA5ED/2459807a536e3dbc9d933713245c30ff
        //
        if (state.y == 0) {
            // first turn
            if (monaco.getAccelerateCost(1) <= INIT_ACCEL_COST) {
                // we're the first car
                state.balance -= monaco.buyAcceleration(11);
                state.speed += 11;
            }
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
                //   2nd and is a banana worth it? maybe buy one?
                //   if no banana, is a shield VERY cheap? maybe buy one?
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
            // aggresive gouging of shells & super shells up to floor * 2
            // buy a banana, *after the shells*
        } else {
            //
            // BLITZKRIEG strat
            //
            if (try_finish_right_now(monaco, state)) return;

            // buy_accel_at_max(monaco, state, ACCEL_FLOOR * ACCEL_BLITZKRIEG_MUL);

            // TODO
            if (self_index != 0) {
                // priority 1, buy a shell or supershell if we're not first, and if the first is not shielded
                maybe_buy_any_shell_kind(monaco, state, SHELL_FLOOR * 5, front_car);
            }

            uint256 shields_needed = compute_shields_needed(monaco, self_index, allCars, back_car);

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
            if (self.speed < 10) {
                buy_accel_at_max(monaco, state, ACCEL_FLOOR * 3);
            }
        }

        accel_with_remaining_budget_for_turn(monaco, state);
    }

    //
    // aux
    //
    function try_finish_right_now(Monaco monaco, TurnState memory state) internal returns (bool finished) {
        uint256 remainingDist = 1000 - state.y;
        if (remainingDist > state.speed) {
            uint256 needed = remainingDist - state.speed;
            try monaco.getAccelerateCost(needed) returns (uint256 cost) {
                if (cost <= state.balance) {
                    monaco.buyAcceleration(needed);
                    return true;
                }
            } catch {}
        }
        return false;
    }

    function compute_shields_needed(
        Monaco monaco,
        uint256 self_index,
        Monaco.CarData[] calldata allCars,
        Monaco.CarData memory back_car
    ) internal view returns (uint256 result) {
        if (self_index == 2) return 0;

        result = 1;
        if (self_index < 2) {
            back_car = allCars[self_index + 1];

            // find position of next turn's car
            // maybe cache some of this in the first turn?
            (,, uint32 next_car_y,,) = monaco.getCarData(monaco.cars((monaco.turns() + 1) % 3));

            // does it not match the back_car?
            // then we need two shields if we want protection
            if (next_car_y != back_car.y) {
                result = 2;
            }
        }
    }

    function buy_accel_at_max(Monaco monaco, TurnState memory state, uint256 max_unit_cost) internal {
        while (true) {
            uint256 cost = monaco.getAccelerateCost(1);
            if (cost > state.balance || cost > max_unit_cost) {
                return;
            }
            monaco.buyAcceleration(1);
            state.speed += 1;
            state.balance -= cost;
        }
    }

    function maybe_buy_any_shell_kind(
        Monaco monaco,
        TurnState memory state,
        uint256 budget,
        Monaco.CarData memory front_car
    ) internal {
        uint256 shell_cost = monaco.getShellCost(1);
        uint256 super_shell_cost = monaco.getSuperShellCost(1);

        // TODO
        // super shell more expensive than shell we're in second, or only 1 player with speed, and no bananas?
        // then only buy shell

        if (super_shell_cost < shell_cost * 15 / 10 && super_shell_cost < budget && super_shell_cost < state.balance) {
            monaco.buySuperShell(1);
            state.balance -= super_shell_cost;
        } else if (shell_cost < budget && front_car.shield == 0 && shell_cost < state.balance) {
            monaco.buyShell(1);
            state.balance -= shell_cost;
        }
    }

    function maybe_banana(Monaco monaco, TurnState memory state, uint256 price) internal returns (uint256 count) {
        uint256 cost = monaco.getBananaCost();

        if (cost <= price) {
            monaco.buyBanana();
            state.balance -= cost;
            return 1;
        }
        return 0;
    }

    function maybe_buy_shield(Monaco monaco, TurnState memory state, uint256 max_shields, uint256 price) internal {
        uint256 cost = monaco.getShieldCost(1);

        if (cost <= price) {
            monaco.buyShield(1);
            state.balance -= cost;
        }
    }

    function buy_accel_with_budget(Monaco monaco, TurnState memory state, uint256 budget) internal {
        while (true) {
            uint256 cost = monaco.getAccelerateCost(1);
            if (cost > budget) {
                return;
            }
            monaco.buyAcceleration(1);
            budget -= cost;
            state.speed += 1;
            state.balance -= cost;
        }
    }

    function accel_with_remaining_budget_for_turn(Monaco monaco, TurnState memory state) internal {
        uint256 spent = state.initialBalance - state.balance;
        if (state.targetSpend > spent) {
            buy_accel_with_budget(monaco, state, state.targetSpend - spent);
        }
    }

    function aggressive_shell_gouging(Monaco monaco, TurnState memory state) internal {
        uint256 budget = state.initialBalance - state.balance;

        while (true) {
            uint256 shellPrice = monaco.getShellCost(1);
            uint256 superShellPrice = monaco.getSuperShellCost(1);

            if (shellPrice < superShellPrice && shellPrice <= budget && shellPrice < SHELL_FLOOR * 2) {
                monaco.buyShell(1);
                budget -= shellPrice;
                state.balance -= shellPrice;
            } else if (superShellPrice <= shellPrice && superShellPrice <= budget && superShellPrice < SHELL_FLOOR * 2)
            {
                monaco.buySuperShell(1);
                budget -= superShellPrice;
                state.balance -= superShellPrice;
            } else {
                break;
            }
        }
    }

    function tiny_gouge_super_shell(Monaco monaco, TurnState memory state, uint256 budget) internal {
        uint256 budget = state.initialBalance - state.balance;

        while (true) {
            uint256 superShellPrice = monaco.getSuperShellCost(1);

            if (superShellPrice <= budget && superShellPrice < state.balance) {
                monaco.buySuperShell(1);
                budget -= superShellPrice;
                state.balance -= superShellPrice;
            } else {
                break;
            }
        }
    }

    function sayMyName() external pure returns (string memory) {
        return "Bradbury";
    }
}
