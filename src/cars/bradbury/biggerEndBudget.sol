// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "solmate/utils/SafeCastLib.sol";
import {Monaco} from "../../Monaco.sol";
import {BradburyBase} from "./Base.sol";

contract BradburyBiggerEndBudget is BradburyBase {
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
        Strat strat;

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
            state.targetSpend = state.initialBalance / state.remainingTurns * 8 / 10;
        } else {
            // we're in 2nd or 3rd, lag behind the next car
            strat = Strat.LAG;
            front_car = allCars[self_index - 1];

            state.remainingTurns = self.speed > 0 ? (800 - self.y) / self.speed : 800;
            if (state.remainingTurns == 0) state.remainingTurns = 1;
            state.targetSpend = state.initialBalance / state.remainingTurns * 8 / 10;
        }

        onTurnBeginning(monaco, state);
        if (strat == Strat.LAG) {
            onStratLag(monaco, state);
        } else if (strat == Strat.HODL) {
            onStratHodl(monaco, state);
        } else {
            onStratBlitzkrieg(monaco, state);
        }
        onTurnFinish(monaco, state);
    }

    function sayMyName() external pure returns (string memory) {
        return "Bradbury-BiggerEndBudget";
    }
}
