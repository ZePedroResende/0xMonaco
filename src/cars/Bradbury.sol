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

    uint256 internal constant INIT_ACCEL_COST = 12;

    uint256 internal constant ACCEL_FLOOR = 15;
    uint256 internal constant SHELL_FLOOR = 200;
    uint256 internal constant SUPER_SHELL_FLOOR = 300;
    uint256 internal constant SHIELD_FLOOR = 400;

    uint256 internal constant ACCEL_HODL_MUL = 5;
    uint256 internal constant ACCEL_BLITZKRIEG_MUL = 10;

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

        uint256 net_worths[3];

        TurnState memory state = TurnState({
            leading: selfIndex == 0,
            initialBalance: self.balance,
            balance: self.balance,
            speed: self.speed,
            y: self.y,
            pctLeft: self.balance * 100 / INITIAL_BALANCE,
            remainingTurns: self.speed > 0 ? (1000 - self.y) / self.speed : 1000,
            targetSpend: 0
        });
        Strat strat = Strat.LAG;
        if (state.remainingTurns == 0) state.remainingTurns = 1;

        //
        // first move
        // inspired by https://gist.github.com/xBA5ED/2459807a536e3dbc9d933713245c30ff
        //
        if (state.y == 0) {
            // first turn
            if (monaco.getAccelerateCost(1) <= INIT_ACCEL_COST) {
                // we're the first car
                state.balance -= monaco.buyAcceleration(15);
                state.speed += 15;
            }
        }

        // define more state depending on race stage
        if (allCars[0].y >= BLITZKRIEG) {
            // leader is almost at the end! blitzkrieg regardless
            // of if the leader is us or someone else
            strat = Strat.BLITZKRIEG;

            // we spend 100% of our budget per turn
            state.targetSpend = state.initialBalance / state.remainingTurns;
        } else if (selfIndex == 0) {
            // we're in 1st, try to hold our position
            strat = Strat.HODL;

            // try and spend 70% of our per-turn budget
            // leave some overhead for blitzkrieg
            state.targetSpend = state.initialBalance / state.remainingTurns * 7 / 10;
        } else {
            // we're in 2nd or 3rd, lag behind the next car
            strat = Strat.LAG;
            frontCar = allCars[selfIndex - 1];

            state.targetSpend = state.initialBalance / state.remainingTurns * 7 / 10;
        }

        // priority: try to sweep floor on acceleration
        buy_accel_at_max(monaco, state, ACCEL_FLOOR);

        if (strat == Strat.LAG) {
            //
            // LAG strat
            //
            console.log("LAG");

            uint256 selfNextPos = self.y + self.speed;
            uint256 otherNextPos = frontCar.y + frontCar.speed;

            // check if we're too far behind
            if (otherNextPos > selfNextPos + LAG_MAX_DESIRED_SPACING) {
                // accelerate with a premium
                // buy_accel_at_premium(monaco, self, 2, ACCEL_FLOOR * LAG_PREMIUM_TOO_FAR);
            } else if (frontCar.speed > self.speed) {
                // we're close but the other car is going faster
                // we try to buy, but we don't panic that much
                uint256 diff = frontCar.speed - self.speed;

                // buy_accel_at_premium(monaco, state, ACCEL_FLOOR * 2);
            }
        } else if (strat == Strat.HODL) {
            //
            // HODL strat
            //
            console.log("HOLD");

            buy_accel_at_max(monaco, state, ACCEL_FLOOR * ACCEL_HODL_MUL);
        } else {
            //
            // BLITZKRIEG strat
            //
            console.log("BLITZKRIEG");
            if (try_finish_right_now(monaco, state)) return;

            buy_accel_at_max(monaco, state, ACCEL_FLOOR * ACCEL_BLITZKRIEG_MUL);

            // TODO
            // priority 1, buy a shell or supershell if we're not first, and if the first is not shielded
            // priority 2, if we're close and with good speed, buy shields
            // priority 3, if we're first, buy speed or price gauge shells
        }

        //
        // take actions
        //
        console.log("worked");
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

    function buy_accel_at_max(Monaco monaco, TurnState memory state, uint256 max_unit_cost) internal {
        while (true) {
            uint256 cost = monaco.getAccelerateCost(1);
            if (cost > state.balance || cost > max_unit_cost) {
                return;
            }
            monaco.buyAcceleration(1);
            state.speed += 1;
            state.balance -= cost.safeCastTo32();
        }
    }

    // function buy_accel_with_budget(Monaco monaco, TurnState memory state, uint256 max, uint256 budget) internal {
    //     while (max > 0) {
    //         max--;
    //         uint256 cost = monaco.getAccelerateCost(1);
    //         if (cost > budget) {
    //             return;
    //         }
    //         budget -= cost;
    //         monaco.buyAcceleration(1);
    //         state.speed = +1;
    //         state.balance -= cost;
    //     }
    // }

    function sayMyName() external pure returns (string memory) {
        return "Bradbury";
    }
}
