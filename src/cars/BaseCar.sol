// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./constants.sol";
import "../Monaco.sol";
import "../interfaces/ICar.sol";

abstract contract BaseCar is ICar {
    //
    // constants
    //
    uint256 constant INITIAL_BALANCE = 17500;

    uint256 constant ACCEL_FLOOR = 15;
    uint256 constant SHELL_FLOOR = 200;
    uint256 constant SUPER_SHELL_FLOOR = 300;
    uint256 constant SHIELD_FLOOR = 400;
    uint256 constant BANANA_FLOOR = 200;

    //
    // structs
    //
    enum Strat {
        LAG, // stick to 3rd place, but close enough to 2nd car
        HODL, // hold your spot
        BLITZKRIEG // all out war
    }

    struct TurnState {
        Strat strat;
        bool leading;
        uint256 speed;
        uint256 initialBalance;
        uint256 balance;
        uint256 y;
        uint256 pctLeft;
        uint256 remainingTurns;
        uint256 targetSpend;
        uint256 spent;
        uint256 self_index;
        Monaco.CarData self;
        Monaco.CarData front_car;
        Monaco.CarData back_car;
    }

    //
    // API
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

    function compute_shields_needed(Monaco monaco, uint256 self_index, Monaco.CarData memory back_car)
        internal
        view
        returns (uint256 result)
    {
        if (self_index == 2) return 0;

        result = 1;
        if (self_index < 2) {
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
            state.spent += cost;
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
            state.spent += super_shell_cost;
        } else if (shell_cost < budget && front_car.shield == 0 && shell_cost < state.balance) {
            monaco.buyShell(1);
            state.balance -= shell_cost;
            state.spent += shell_cost;
        }
    }

    function maybe_banana(Monaco monaco, TurnState memory state, uint256 price) internal returns (uint256 count) {
        uint256 cost = monaco.getBananaCost();

        if (cost <= price && state.balance >= cost) {
            monaco.buyBanana();
            state.balance -= cost;
            state.spent += cost;
            return 1;
        }
        return 0;
    }

    function maybe_buy_shield(Monaco monaco, TurnState memory state, uint256 max_shields, uint256 price) internal {
        uint256 cost = monaco.getShieldCost(max_shields);

        if (cost <= price * 1 && state.balance >= cost) {
            monaco.buyShield(max_shields);
            state.balance -= cost;
            state.spent += cost;
        }
    }

    function buy_accel_with_budget(Monaco monaco, TurnState memory state, uint256 budget) public {
        while (true) {
            uint256 cost = monaco.getAccelerateCost(1);
            if (cost > budget || state.balance < cost) {
                return;
            }
            monaco.buyAcceleration(1);
            budget -= cost;
            state.speed += 1;
            state.balance -= cost;
            state.spent += cost;
        }
    }

    function accel_with_remaining_budget_for_turn(Monaco monaco, TurnState memory state) internal {
        uint256 spent = state.initialBalance - state.balance;
        if (state.targetSpend > spent) {
            buy_accel_with_budget(monaco, state, state.targetSpend - spent);
        }
    }

    function aggressive_shell_gouging(Monaco monaco, TurnState memory state) internal {
        uint256 budget = state.balance;

        while (true) {
            uint256 shellPrice = monaco.getShellCost(1);
            uint256 superShellPrice = monaco.getSuperShellCost(1);

            if (shellPrice < superShellPrice && shellPrice <= budget && shellPrice < SHELL_FLOOR * 2) {
                monaco.buyShell(1);
                budget -= shellPrice;
                state.balance -= shellPrice;
                state.spent += shellPrice;
            } else if (superShellPrice <= shellPrice && superShellPrice <= budget && superShellPrice < SHELL_FLOOR * 2)
            {
                monaco.buySuperShell(1);
                budget -= superShellPrice;
                state.balance -= superShellPrice;
                state.spent += superShellPrice;
            } else {
                break;
            }
        }
    }

    function tiny_gouge_super_shell(Monaco monaco, TurnState memory state, uint256 /*budget*/ ) internal {
        uint256 budget = state.initialBalance - state.balance;

        while (true) {
            uint256 superShellPrice = monaco.getSuperShellCost(1);

            if (superShellPrice <= budget && superShellPrice < state.balance) {
                monaco.buySuperShell(1);
                budget -= superShellPrice;
                state.balance -= superShellPrice;
                state.spent += superShellPrice;
            } else {
                break;
            }
        }
    }
}
