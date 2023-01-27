// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "solmate/utils/SafeCastLib.sol";
import {Monaco} from "../../Monaco.sol";
import {BradburyBase} from "./Base.sol";

contract BradburyEvenBiggerAccelFloor is BradburyBase {
    using SafeCastLib for uint256;

    function onTurnBeginning(Monaco monaco, TurnState memory state) internal override {
        if (monaco.turns() == 1) {
            // we have 1st move advantage
            state.balance -= monaco.buyAcceleration(11);
            state.speed += 11;
        }

        buy_accel_at_max(monaco, state, ACCEL_FLOOR * 6);
    }

    function sayMyName() external pure returns (string memory) {
        return "Bradbury-evenBiggerAccelFloor";
    }
}
