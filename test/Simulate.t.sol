// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";

import "../src/Monaco.sol";

contract SimulateTest is Test {
    error MonacoTest__getCarIndex_carNotFound(address car);
    error MonacoTest__getAbilityCost_abilityNotFound(uint256 abilityIndex);

    struct Out {
        uint256 car0;
        string name0;
        uint256 car1;
        string name1;
        uint256 car2;
        string name2;
    }

    function setUp() public {}

    function testSimulation() public {
        Monaco monaco;
        string[] memory input = new string[](9);

        //  input[0] = "PermaShield.sol";
        //  input[2] = "Floor.sol";
        //  input[3] = "ThePackage.sol";

        input[0] = "v1.sol:BradburyV1";
        input[1] = "biggerEndBudget.sol:BradburyBiggerEndBudget";
        input[2] = "goBananas.sol:BradburyGoBananas";
        input[3] = "moreSpeedInBlitz.sol:BradburySpeedInBlitz";
        input[4] = "v0.sol:BradburyV0";
        input[5] = "smallerEndBudget.sol:BradburySmallerEndBudget";
        input[6] = "evenBiggerAccelFloor.sol:BradburyEvenBiggerAccelFloor";
        input[7] = "biggerBetter.sol:BradburyBiggerBetter";
        input[8] = "lagSpeed_blitzSpeed.sol:BradburyLagSpeedBlitzSpeed";

        //        input[6] = "ExampleCar.sol";
        //        input[7] = "Saucepoint.sol:Sauce";

        vm.writeFile(
            string.concat("simulations/", "simulation", ".simulation"),
            string.concat(
                input[0],
                ",",
                input[1],
                ",",
                input[2],
                ",",
                input[3],
                ",",
                input[4],
                ",",
                input[5], //",",
                ",",
                input[6], //",",
                ",",
                input[7], //",",
                ",",
                input[8], //",",
                //input[6], ",",
                //input[7],
                "\n"
            )
        );

        for (uint256 i = 0; i < input.length; i++) {
            for (uint256 j = 0; j < input.length; j++) {
                for (uint256 k = 0; k < input.length; k++) {
                    if (i != j && i != k && j != k) {
                        console.log(string.concat(vm.toString(i), ",", vm.toString(j), ",", vm.toString(k), "\n"));
                        uint256 snapshot = vm.snapshot();

                        monaco = new Monaco();

                        address[] memory cars = new address[](3);
                        uint256[] memory carToIndex = new uint[](3);

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

                        for (uint256 p = 0; p < 3; p++) {
                            monaco.register(ICar(cars[p]));
                        }

                        uint256 lastTurn = 1;
                        while (monaco.state() != Monaco.State.DONE) {
                            monaco.play(1);
                        }

                        Monaco.CarData[] memory allCarData = monaco.getAllCarData();

                        vm.writeLine(
                            "simulations/simulation.simulation",
                            string.concat(
                                vm.toString(carToIndex[0]),
                                ",",
                                vm.toString(carToIndex[1]),
                                ",",
                                vm.toString(carToIndex[2]),
                                "\n"
                            )
                        );
                        for (uint256 p = 0; p < allCarData.length; p++) {
                            Monaco.CarData memory car = allCarData[p];

                            // Add car data to the current turn
                            uint256 carIndex = getCarIndex(cars, address(car.car));

                            vm.writeLine(
                                "simulations/simulation.simulation",
                                string.concat(vm.toString(car.y), ",", vm.toString(carToIndex[carIndex]))
                            );
                        }

                        vm.writeLine("simulations/simulation.simulation", "-----");

                        vm.revertTo(snapshot);
                    }
                }
            }
        }
    }

    function testSimulationByName(string memory car0Name, string memory car1Name, string memory car2Name)
        public
        returns (Out memory)
    {
        //string memory car0Name, string memory car1Name, string memory car2Name

        //string memory car0Name  = "B_biggerAccelFloor.sol:BradburyBigAccelFloor";
        //string memory car1Name  = "B_biggerEndBudget.sol:BradburyBiggerEndBudget";
        //string memory car2Name  = "B_goBananas.sol:BradburyGoBananas";
        Monaco monaco = new Monaco();

        address[] memory cars = new address[](3);
        string[] memory carToName = new string[](3);

        address a = 0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF;
        address b = 0xdEAdBeEFDeadBeeFDEadbeefdEadBEeFDEADBEeE;
        address c = 0xDeaDbeefdeADbEeFDEAdbEeFDEADBEeFdeAdBeE1;

        deployContract(car0Name, a);
        deployContract(car1Name, b);
        deployContract(car2Name, c);

        cars[0] = a;
        cars[1] = b;
        cars[2] = c;

        carToName[0] = car0Name;
        carToName[1] = car1Name;
        carToName[2] = car2Name;

        for (uint256 p = 0; p < 3; p++) {
            monaco.register(ICar(cars[p]));
        }

        uint256 lastTurn = 1;
        while (monaco.state() != Monaco.State.DONE) {
            monaco.play(1);
        }

        Monaco.CarData[] memory allCarData = monaco.getAllCarData();

        Out memory out = Out(
            allCarData[0].y,
            carToName[getCarIndex(cars, address(allCarData[0].car))],
            allCarData[1].y,
            carToName[getCarIndex(cars, address(allCarData[1].car))],
            allCarData[2].y,
            carToName[getCarIndex(cars, address(allCarData[2].car))]
        );

        return out;
    }

    function getCarIndex(address[] memory cars, address car) private view returns (uint256) {
        for (uint256 i = 0; i < 3; ++i) {
            if (cars[i] == car) return i;
        }

        revert MonacoTest__getCarIndex_carNotFound(car);
    }

    function deployContract(string memory contractName, address targetAddr) private {
        bytes memory bytecode = abi.encodePacked(vm.getCode(contractName));
        address deployed;

        assembly {
            deployed := create(0, add(bytecode, 0x20), mload(bytecode))
        }

        vm.etch(targetAddr, deployed.code);
    }
}
