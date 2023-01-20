// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/console.sol";
import "./../interfaces/ICar.sol";
import "solmate/utils/SafeCastLib.sol";

contract Bradbury is ICar {
    using SafeCastLib for uint256;

    uint256 internal constant LATE_GAME = 600;
    uint256 internal constant BLITZKRIEG = 800; // all-out spending
    uint256 internal constant INITIAL_BALANCE = 17500;

    uint256 internal constant ACCEL_FLOOR = 15;
    uint256 internal constant SHELL_FLOOR = 200;
    uint256 internal constant SUPER_SHELL_FLOOR = 300;
    uint256 internal constant SHIELD_FLOOR = 400;

    //
    // in Lag mode, we're in 3rd position
    //
    // we value speed highly if we're too far from the 2nd
    uint256 internal constant LAG_PREMIUM_TOO_FAR = 5;
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
        uint256 speed;
        uint256 balance;
        uint256 y;
        uint256 new_cost;
        uint256 new_speed;
    }

    function takeYourTurn(
        Monaco monaco,
        Monaco.CarData[] calldata allCars,
        uint256[] calldata bananas,
        uint256 selfIndex
    ) external {
        //
        // setup vars
        //
        Monaco.CarData memory self = allCars[selfIndex];
        Monaco.CarData memory frontCar;
        if (selfIndex > 0) frontCar = allCars[selfIndex - 1];
        Monaco.CarData memory backCar;
        if (selfIndex < 2) backCar = allCars[selfIndex + 1];

        TurnState memory state =
            TurnState({balance: self.balance, speed: self.speed, y: self.y, new_cost: 0, new_speed: 0});

        uint256 balancePctLeft = self.balance * 100 / INITIAL_BALANCE;
        uint256 remainingTurns = self.speed > 0 ? (1000 - self.y) / self.speed : 1000;
        Strat strat = Strat.LAG;

        uint256 new_accel = 0;

        // can we finish right away?

        if (allCars[0].y >= BLITZKRIEG) {
            // leader is almost at the end! blitzkrieg regardless
            // of if the leader is us or someone else
            strat = Strat.BLITZKRIEG;
        } else if (selfIndex == 0) {
            // we're in 1st, try to hold our position
            strat = Strat.HODL;
        } else {
            // we're in 3rd, lag behind the next car
            strat = Strat.LAG;
            frontCar = allCars[selfIndex - 1];
        }

        if (strat == Strat.BLITZKRIEG) {
            if (try_finish_right_now(monaco, state)) return;
        }

        buy_accel_cheap(monaco, state);

        //
        if (strat == Strat.LAG) {
            console.log("LAG");
            //     uint256 selfNextPos = self.y + self.speed;
            //     uint256 otherNextPos = frontCar.y + frontCar.speed;
            //
            //     // check if we're too far behind
            //     if (otherNextPos > selfNextPos + LAG_MAX_DESIRED_SPACING) {
            //         // accelerate with a premium
            //         // buy_accel_at_premium(monaco, self, 2, ACCEL_FLOOR * LAG_PREMIUM_TOO_FAR);
            //     } else if (frontCar.speed > self.speed) {
            //         // we're close but the other car is going faster
            //         // we try to buy, but we don't panic that much
            //         uint256 diff = frontCar.speed - self.speed;
            //         // buy_accel_at_premium(monaco, self, diff, ACCEL_FLOOR * LAG_PREMIUM_NEAR_BUT_SLOWER);
            //     }
        } else if (strat == Strat.HODL) {
            console.log("HOLD");
            //
        } else {
            console.log("BLITZKRIEG");
            //
            //     // buy_accel_at_premium(monaco, self, type(uint256).max, ACCEL_FLOOR * 10);
        }

        //
        // take actions
        //
        if (state.new_speed > 0) monaco.buyAcceleration(state.new_speed);
        console.log("gasleft:", gasleft());
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

    function buy_accel_cheap(Monaco monaco, TurnState memory state) internal {
        uint256 new_speed = 0;
        uint256 cost = 0;
        while (new_speed < 10) {
            uint256 new_cost = monaco.getAccelerateCost(new_speed + 1);
            if (new_cost > state.balance || new_cost > ACCEL_FLOOR * (new_speed + 1)) {
                break;
            }
            cost = new_cost;
            new_speed += 1;
        }

        state.new_speed = new_speed;
        state.new_cost = cost;
    }

    function buy_accel_at_premium(Monaco monaco, Monaco.CarData memory self, uint256 max_units, uint256 max_unit_cost)
        internal
    {
        while (true) {
            if (max_units == 0) return;
            uint256 cost = monaco.getAccelerateCost(1);
            if (cost > self.balance || cost > max_unit_cost) {
                return;
            }
            console.log("buying for ", cost);
            monaco.buyAcceleration(1);
            self.speed += 1;
            self.balance -= cost.safeCastTo32();
            max_units -= 1;
        }
    }

    function sayMyName() external pure returns (string memory) {
        return "Bradbury";
    }
}
