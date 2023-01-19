// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/console.sol";
import "./../interfaces/ICar.sol";
import "solmate/utils/SafeCastLib.sol";

contract Bradbury is ICar {
    using SafeCastLib for uint256;

    uint256 internal constant LATE_GAME = 600;
    uint256 internal constant BLITZKRIEG = 800; // all-out spending

    uint256 internal constant ACCEL_FLOOR = 15;
    uint256 internal constant SHELL_FLOOR = 200;
    uint256 internal constant SUPER_SHELL_FLOOR = 300;
    uint256 internal constant SHIELD_FLOOR = 400;

    // how much extra we're willing to spend per accel if we're slower too far behind
    uint256 internal constant LAG_PREMIUM_TOO_FAR = 5;
    // how much extra we're willing to spend per accel if we're near 2nd but slower
    uint256 internal constant LAG_PREMIUM_NEAR_BUT_SLOWER = 3;
    // how much distance we want at most from the 2nd player
    uint256 internal constant LAG_MAX_DESIRED_SPACING = 20;

    enum Strat {
        LAG, // stick to 3rd place, but close enough to 2nd car
        HODL, // hold your spot
        BLITZKRIEG // all out war
    }

    function takeYourTurn(
        Monaco monaco,
        Monaco.CarData[] calldata allCars,
        uint256[] calldata bananas,
        uint256 selfIndex
    ) external {
        Strat strat = Strat.LAG;

        Monaco.CarData memory self = allCars[selfIndex];
        Monaco.CarData memory nextCar;

        if (allCars[0].y >= BLITZKRIEG) {
            // leader is almost at the end! blitzkrieg regardless
            // of if the leader is us or someone else
            strat = Strat.BLITZKRIEG;
        } else if (selfIndex < 2) {
            // we're in 1st or 2nd
            strat = Strat.HODL;
            // nextCar = allCars[selfIndex - 1];
        } else {
            // we're in 3rd
            strat = Strat.LAG;
            nextCar = allCars[selfIndex - 1];
        }

        if (strat == Strat.LAG) {
            console.log("LAG");
            lag(monaco, allCars, bananas, selfIndex, self, nextCar);
        } else if (strat == Strat.HODL) {
            console.log("HODL");
            hodl(monaco, allCars, bananas, selfIndex, self);
        } else {
            console.log("BLITZKRIEG");
            blitzkrieg(monaco, allCars, bananas, selfIndex, self);
        }
    }

    function lag(
        Monaco monaco,
        Monaco.CarData[] calldata allCars,
        uint256[] calldata bananas,
        uint256 selfIndex,
        Monaco.CarData memory self,
        Monaco.CarData memory otherCar
    ) internal {
        buy_accel_cheap(monaco, self);

        uint256 selfNextPos = self.y + self.speed;
        uint256 otherNextPos = otherCar.y + otherCar.speed;

        // check if we're too far behind
        if (otherNextPos > selfNextPos + LAG_MAX_DESIRED_SPACING) {
            // accelerate with a premium
            buy_accel_at_premium(monaco, self, 2, ACCEL_FLOOR * LAG_PREMIUM_TOO_FAR);
        } else if (otherCar.speed > self.speed) {
            // we're close but the other car is going faster
            // we try to buy, but we don't panic that much
            uint256 diff = otherCar.speed - self.speed;
            buy_accel_at_premium(monaco, self, diff, ACCEL_FLOOR * LAG_PREMIUM_NEAR_BUT_SLOWER);
        }

        // TODO if we're about to hit a banana, consider throwing a shell
    }

    function hodl(
        Monaco monaco,
        Monaco.CarData[] calldata allCars,
        uint256[] calldata bananas,
        uint256 selfIndex,
        Monaco.CarData memory self
    ) internal {
        buy_accel_cheap(monaco, self);
    }

    function blitzkrieg(
        Monaco monaco,
        Monaco.CarData[] calldata allCars,
        uint256[] calldata bananas,
        uint256 selfIndex,
        Monaco.CarData memory self
    ) internal {
        buy_accel_at_premium(monaco, self, type(uint256).max, type(uint256).max);
    }

    //
    // aux
    //
    function buy_accel_cheap(Monaco monaco, Monaco.CarData memory self) internal {
        while (true) {
            uint256 cost = monaco.getAccelerateCost(1);
            if (cost > self.balance || cost > ACCEL_FLOOR) {
                return;
            }
            monaco.buyAcceleration(1);
            self.speed += 1;
            self.balance -= cost.safeCastTo32();
        }
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
