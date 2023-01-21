// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./../../interfaces/ICar.sol";

contract Floor is ICar {
    uint256 internal constant ACCEL_FLOOR = 15;
    uint256 internal constant SHELL_FLOOR = 200;
    uint256 internal constant SUPER_SHELL_FLOOR = 300;
    uint256 internal constant SHIELD_FLOOR = 400;

    function takeYourTurn(
        Monaco monaco,
        Monaco.CarData[] calldata allCars,
        uint256[] calldata, /*bananas*/
        uint256 ourCarIndex
    ) external {
        uint256 balance = allCars[ourCarIndex].balance;

        uint256 cost = monaco.getAccelerateCost(1);
        if (cost <= balance && cost < ACCEL_FLOOR) {
            monaco.buyAcceleration(1);
            balance -= cost;
        }

        cost = monaco.getShellCost(1);
        if (cost <= balance && monaco.getShellCost(1) < SHELL_FLOOR) {
            monaco.buyShell(1);
            balance -= cost;
        }

        cost = monaco.getSuperShellCost(1);
        if (ourCarIndex == 2 && cost <= balance && cost < SUPER_SHELL_FLOOR) {
            monaco.buySuperShell(1);
            balance -= cost;
        }

        cost = monaco.getShieldCost(1);
        if (ourCarIndex != 2 && cost <= balance && cost < SHIELD_FLOOR) {
            monaco.buyShield(1);
            balance -= cost;
        }
    }

    function sayMyName() external pure returns (string memory) {
        return "Floor";
    }
}
