// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../Monaco.sol";

interface ICar {
    function sayMyName() external view returns (string memory);

    function takeYourTurn(
        Monaco monaco,
        Monaco.CarData[] calldata allCars,
        uint256[] calldata bananas,
        uint256 yourCarIndex
    ) external;
}
