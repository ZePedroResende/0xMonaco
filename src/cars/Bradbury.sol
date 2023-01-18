// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./../interfaces/ICar.sol";

contract Bradbury is ICar {
    uint256 internal constant LATE_GAME = 600;
    uint256 internal constant BLITZKRIEG = 800; // all-out spending

    uint256 internal constant ACCEL_FLOOR = 15;
    uint256 internal constant SHELL_FLOOR = 200;
    uint256 internal constant SUPER_SHELL_FLOOR = 300;
    uint256 internal constant SHIELD_FLOOR = 400;

    enum Strat {
        LAG, // stick to 3rd place, but close enough to 2nd car
        HOLD, // hold your spot
        BLITZKRIEG // all out war
    }

    function takeYourTurn(
        Monaco monaco,
        Monaco.CarData[] calldata allCars,
        uint256[] calldata bananas,
        uint256 ourCarIndex
    ) external {
        Strat strat = Strat.LAG;
        Monaco.CarData calldata lagCar;

        // find lag car
        if (ourCarIndex == 0) {
            lagCar = allCars[1];
        } else if (ourCarIndex == 1) {
            lagCar = allCars[2];
        } else {
            // we're in the lead
            strat = Strat.HOLD;
        }

        // if we're near the end, all out war
        if (allCars[ourCarIndex].y >= BLITZKRIEG) {
            strat = Strat.BLITZKRIEG;
        }

        if (strat == Strat.LAG) {
            lag(monaco, allCars, bananas, ourCarIndex);
        } else if (strat == Strat.HOLD) {
            hold(monaco, allCars, bananas, ourCarIndex);
        } else {
            blitzkrieg(monaco, allCars, bananas, ourCarIndex);
        }
    }

    function lag(Monaco monaco, Monaco.CarData[] calldata allCars, uint256[] calldata bananas, uint256 ourCarIndex)
        internal
    {
        // TODO
        if (monaco.getAccelerateCost(1) < ACCEL_FLOOR) monaco.buyAcceleration(1);
        if (monaco.getShellCost(1) < SHELL_FLOOR) monaco.buyShell(1);
        if (ourCarIndex == 2 && monaco.getSuperShellCost(1) < SUPER_SHELL_FLOOR) monaco.buySuperShell(1);
        if (ourCarIndex != 2 && monaco.getShieldCost(1) < SHIELD_FLOOR) monaco.buyShield(1);
    }

    function hold(Monaco monaco, Monaco.CarData[] calldata allCars, uint256[] calldata bananas, uint256 ourCarIndex)
        internal
    {
        lag(monaco, allCars, bananas, ourCarIndex);
        //TODO
    }

    function blitzkrieg(
        Monaco monaco,
        Monaco.CarData[] calldata allCars,
        uint256[] calldata bananas,
        uint256 ourCarIndex
    ) internal {
        //TODO
        lag(monaco, allCars, bananas, ourCarIndex);
    }

    function sayMyName() external pure returns (string memory) {
        return "Bradbury";
    }
}
