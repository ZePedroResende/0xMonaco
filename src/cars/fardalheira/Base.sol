// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/console.sol";
import {Monaco} from "../../Monaco.sol";
import {BaseCar} from "../BaseCar.sol";

abstract contract FardalheiraBase is BaseCar {
    //
    // constants
    //
    uint256 internal constant LATE_GAME = 600;
    uint256 internal constant BLITZKRIEG = 800; // all-out spending
    uint256 internal constant INIT_ACCEL_COST = 12;
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

    //
    // structs
    //
    struct Params {
        uint256 first_turn_accel;
        /// beginning of turn, % from accel floor price we're willing to take
        uint256 beg_accel_pct;
        /// lag strat, % from accel floor price we're willing to take
        uint256 lag_accel_pct;
        /// lag strat, % from banana floor price we're willing to take
        uint256 lag_banana_pct;
        /// during lag strat, how much of turn's budget to spend
        uint256 lag_target_spend_pct;
        /// hodl strat, % from banana floor price we're willing to take
        uint256 hodl_banana_pct;
        /// during hodl strat, how much of turn's budget to spend
        uint256 hodl_target_spend_pct;
        /// blitz strat, % from accel floor price we're willing to take
        uint256 blitz_accel_pct;
        uint256 aggressive_shell_gouging_pct;
    }

    uint256 public immutable first_turn_accel;
    uint256 public immutable beg_accel_pct;
    uint256 public immutable lag_accel_pct;
    uint256 public immutable lag_banana_pct;
    uint256 public immutable lag_target_spend_pct;
    uint256 public immutable hodl_banana_pct;
    uint256 public immutable hodl_target_spend_pct;
    uint256 public immutable blitz_accel_pct;
    uint256 public immutable aggressive_shell_gouging_pct;
    string name;

    constructor(string memory _name, Params memory params) {
        name = string.concat("Fardalheira-", _name);
        first_turn_accel = params.first_turn_accel;
        beg_accel_pct = params.beg_accel_pct;
        lag_accel_pct = params.lag_accel_pct;
        lag_banana_pct = params.lag_banana_pct;
        lag_target_spend_pct = params.lag_target_spend_pct;
        hodl_banana_pct = params.hodl_banana_pct;
        hodl_target_spend_pct = params.hodl_target_spend_pct;
        blitz_accel_pct = params.blitz_accel_pct;
        aggressive_shell_gouging_pct = params.aggressive_shell_gouging_pct;
    }

    function takeYourTurn(
        Monaco monaco,
        Monaco.CarData[] calldata allCars,
        uint256[] calldata, /*bananas*/
        uint256 self_index
    ) external virtual {
        //
        // setup vars
        //
        Monaco.CarData memory self = allCars[self_index];
        Monaco.CarData memory front_car;
        if (self_index > 0) front_car = allCars[self_index - 1];
        Monaco.CarData memory back_car;

        TurnState memory state = TurnState({
            strat: Strat.LAG,
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
            targetSpend: 0,
            spent: 0
        });
        Strat strat;

        /// how much left until blitz starts, or until race ends
        uint256 remainingDistance = (allCars[0].y >= BLITZKRIEG) ? (1000 - state.self.y) : (BLITZKRIEG - state.self.y);
        console.log(remainingDistance);
        /// that distance in turns, based on current speed. if we're stopped, then we assume speed=1
        state.remainingTurns = self.speed > 0 ? (remainingDistance) / (self.speed > 0 ? self.speed : 1) : 1000;
        if (state.remainingTurns == 0) state.remainingTurns = 1;

        if (allCars[0].y >= BLITZKRIEG) {
            // leader is almost at the end! blitzkrieg regardless
            // of if the leader is us or someone else
            strat = Strat.BLITZKRIEG;
            // we spend 100% of our budget per turn
            state.targetSpend = state.initialBalance / state.remainingTurns;
        } else if (self_index <= 1) {
            // we're in 1st or 2nd, conserve energy
            strat = Strat.HODL;

            // try and spend 70% of our per-turn budget
            // leave some overhead for blitzkrieg
            state.targetSpend = state.initialBalance / state.remainingTurns * hodl_target_spend_pct / 100;
        } else {
            // we're in 3rd, lag behind the next car
            strat = Strat.LAG;

            state.targetSpend = state.initialBalance / state.remainingTurns * lag_target_spend_pct / 100;
        }

        onTurnBeginning(monaco, state);
        if (nobudget(state)) return;

        if (strat == Strat.LAG) {
            onStratLag(monaco, state);
        } else if (strat == Strat.HODL) {
            onStratHodl(monaco, state);
        } else {
            onStratBlitzkrieg(monaco, state);
        }
        onTurnFinish(monaco, state);
    }

    function onTurnBeginning(Monaco monaco, TurnState memory state) internal virtual {
        if (monaco.turns() == 1 && first_turn_accel > 0) {
            // we have 1st move advantage
            state.balance -= monaco.buyAcceleration(first_turn_accel);
            state.speed += first_turn_accel;
        }

        if (nobudget(state)) return;

        buy_accel_at_max(monaco, state, ACCEL_FLOOR * beg_accel_pct / 100);
    }

    function onStratLag(Monaco monaco, TurnState memory state) internal virtual {
        uint256 self_next_pos = state.self.y + state.self.speed;
        uint256 other_next_pos = state.front_car.y + state.front_car.speed;

        buy_accel_at_max(monaco, state, ACCEL_FLOOR * lag_accel_pct / 100);

        if (nobudget(state)) return;

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

        if (nobudget(state)) return;

        // if we're in second and we have speed?
        // TODO tweak this value
        if (state.self_index == 1 && state.self.speed > 10) {
            //   2nd and is a banana worth it?.maybe buy one?
            //   if no banana, is a shield VERY cheap?.maybe buy one?
            uint256 bought = maybe_banana(monaco, state, BANANA_FLOOR * lag_banana_pct / 100);

            if (bought == 0) {
                maybe_buy_shield(monaco, state, 1, SHIELD_FLOOR / 2);
            }
            aggressive_shell_gouging(monaco, state, SHELL_FLOOR * aggressive_shell_gouging_pct / 100);
        }
    }

    function onStratHodl(Monaco monaco, TurnState memory state) internal virtual {
        maybe_banana(monaco, state, BANANA_FLOOR * hodl_banana_pct / 100);
        aggressive_shell_gouging(monaco, state, SHELL_FLOOR * aggressive_shell_gouging_pct / 100);
    }

    function onStratBlitzkrieg(Monaco monaco, TurnState memory state) internal virtual {
        if (try_finish_right_now(monaco, state)) return;

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
            tiny_gouge_super_shell(monaco, state);
        }
        if (nobudget(state)) return;

        // if we're in first, and 2nd is faster, slow him down
        if (state.self_index == 0 && state.back_car.speed > state.self.speed) {
            maybe_banana(monaco, state, BANANA_FLOOR * 2);
        }
        if (nobudget(state)) return;

        // try to maintain some speed if we're slow
        if (state.self.speed < 10) {
            buy_accel_at_max(monaco, state, ACCEL_FLOOR * blitz_accel_pct / 100);
        }
    }

    function onTurnFinish(Monaco monaco, TurnState memory state) internal virtual {
        if (state.strat == Strat.BLITZKRIEG) {
            accel_with_remaining_budget_for_turn(monaco, state);
        }
    }

    /// if we're in blitz, budget is unlimited
    /// otherwise, try to keep it below the target
    function nobudget(TurnState memory state) internal virtual returns (bool) {
        if (state.strat == Strat.BLITZKRIEG) {
            return false;
        }

        return state.targetSpend <= state.spent;
    }

    function aggressive_shell_gouging_within_budget(Monaco monaco, TurnState memory state) internal {
        while (true) {
            if (nobudget(state)) return;

            uint256 shellPrice = monaco.getShellCost(1);
            uint256 superShellPrice = monaco.getSuperShellCost(1);

            if (shellPrice < superShellPrice && shellPrice < SHELL_FLOOR * 2) {
                monaco.buyShell(1);
                state.balance -= shellPrice;
                state.spent += shellPrice;
            } else if (superShellPrice <= shellPrice && superShellPrice < SHELL_FLOOR * 2) {
                monaco.buySuperShell(1);
                state.balance -= superShellPrice;
                state.spent += superShellPrice;
            } else {
                break;
            }
        }
    }

    function tiny_gouge_super_shell_within_budget(Monaco monaco, TurnState memory state) internal {
        while (true) {
            if (nobudget(state)) return;
            uint256 superShellPrice = monaco.getSuperShellCost(1);

            if (superShellPrice < state.balance) {
                monaco.buySuperShell(1);
                state.balance -= superShellPrice;
                state.spent += superShellPrice;
            } else {
                break;
            }
        }
    }

    function sayMyName() external view returns (string memory) {
        return name;
    }
}
