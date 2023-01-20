// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";

import "../src/Monaco.sol";

contract SimulateTest is Test {
    error MonacoTest__getCarIndex_carNotFound(address car);
    error MonacoTest__getAbilityCost_abilityNotFound(uint256 abilityIndex);

    Monaco monaco;
    uint[][3] races;

    function setUp() public {}

    function testSimulation() public {
        string[] memory input = new string[](4);

        input[0] = "PermaShield.sol";
        input[1] = "Saucepoint.sol:Sauce";
        input[2] = "Floor.sol";
        input[3] = "ThePackage.sol";


        vm.writeFile(
            string.concat("simulations/", "simulation", ".simulation"),
            string.concat(input[0], ",", input[1], ",",input[2], ",",input[3],"\n"));

        for (uint i = 0; i < input.length; i++) {
            for (uint j = 0; j < input.length; j++) {
                for (uint k = 0; k < input.length; k++) {
                    if (i != j && i != k && j != k) {
                        uint256 snapshot = vm.snapshot();

                        monaco = new Monaco();

                        address[] memory cars = new address[](3);
                        uint[] memory carToIndex = new uint[](3);

                        address a = 0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF;
                        address b = 0xdEAdBeEFDeadBeeFDEadbeefdEadBEeFDEADBEeE;
                        address c = 0xDeaDbeefdeADbEeFDEAdbEeFDEADBEeFdeAdBeE1;

                        deployContract(input[i], a);
                        deployContract(input[j], b);
                        deployContract(input[k], c);

                        cars[0] = a;
                        cars[1] = b;
                        cars[2] = c;

                        carToIndex[0] = i;
                        carToIndex[1] = j;
                        carToIndex[2] = k;


                        for (uint i = 0; i < 3; i++) {
                            monaco.register(ICar(cars[i]));
                        }

                        uint256 lastTurn = 1;
                        while (monaco.state() != Monaco.State.DONE) {
                            monaco.play(1);
                        }

                        Monaco.CarData[] memory allCarData = monaco
                            .getAllCarData();

                        for (uint256 i = 0; i < allCarData.length; i++) {
                            Monaco.CarData memory car = allCarData[i];

                            // Add car data to the current turn
                            uint256 carIndex = getCarIndex(
                                cars,
                                address(car.car)
                            );

                            vm.writeLine(
                                "simulations/simulation.simulation",
                                string.concat(
                                    vm.toString(car.y),
                                    ",",
                                    vm.toString(carToIndex[carIndex])
                                )
                            );
                        }

                        vm.writeLine("simulations/simulation.simulation", "-----");

                        vm.revertTo(snapshot);
                    }
                }
            }
        }
    }

    function getCarIndex(
        address[] memory cars,
        address car
    ) private view returns (uint256) {
        for (uint256 i = 0; i < 3; ++i) {
            if (cars[i] == car) return i;
        }

        revert MonacoTest__getCarIndex_carNotFound(car);
    }

    function deployContract(
        string memory contractName,
        address targetAddr
    ) private {
        bytes memory bytecode = abi.encodePacked(vm.getCode(contractName));
        address deployed;

        assembly {
            deployed := create(0, add(bytecode, 0x20), mload(bytecode))
        }

        vm.etch(targetAddr, deployed.code);
    }
}
