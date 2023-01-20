// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";

import "../src/Monaco.sol";

contract SimulateTest is Test {

    error MonacoTest__getCarIndex_carNotFound(address car);
    error MonacoTest__getAbilityCost_abilityNotFound(uint256 abilityIndex);

    Monaco monaco;
    string[][3] races;

    function setUp() public {

        string[] memory input = new string[](3);
        input[1] = "Saucepoint.sol:Sauce";
        input[0] = "PermaShield.sol";
        input[2] = "Floor.sol";

        races = getCombinations(input);

        vm.writeFile(string.concat("simulations/", "bla", ".csv"), "races[0]\n");
    }

    function testGames() public {
        for(uint i= 0; i< 1000; i++) {
            uint256 snapshot = vm.snapshot();
            monaco = new Monaco();
            address[] memory cars = new address[](3);

            //for(uint i=0 ; i<3; i++){
                address a = 0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF;
                address b = 0xdEAdBeEFDeadBeeFDEadbeefdEadBEeFDEADBEeE;
                address c = 0xDeaDbeefdeADbEeFDEAdbEeFDEADBEeFdeAdBeE1;
                deployContract(races[0][0], a);
                deployContract(races[0][1], b);
                deployContract(races[0][2], c);
                cars[0] = a; 
                cars[1] = b;
                cars[2] = c;
           // }


            for(uint i=0 ; i<3; i++){
                monaco.register(ICar(cars[i]));
            }

            uint256 lastTurn = 1;
            while (monaco.state() != Monaco.State.DONE) {

                monaco.play(1);



            }

            Monaco.CarData[] memory allCarData = monaco.getAllCarData();

            for (uint256 i = 0; i < allCarData.length; i++) {
                Monaco.CarData memory car = allCarData[i];

                // Add car data to the current turn
                uint256 carIndex = getCarIndex(cars, address(car.car));

                vm.writeLine("simulations/bla.csv", string.concat( vm.toString(car.y),",",vm.toString(carIndex) ));
            }

                vm.writeLine("simulations/bla.csv", "-----" );
            
            // after resetting to a snapshot all changes are discarded
            vm.revertTo(snapshot);
        }

    }

    function getCarIndex(address[] memory cars, address car) private view returns (uint256) {
        for (uint256 i = 0; i < 3; ++i) {
            if (cars[i] == car) return i;
        }

        revert MonacoTest__getCarIndex_carNotFound(car);
    }
    function getCombinations(string[] memory input) public pure returns (string[][3] memory) {
        uint size = getCombinationCount(input);
        string[][3] memory combinations;

        for (uint i = 0; i < input.length; i++) {
            combinations[i] = new string[](3);
        }

        uint index = 0;
        for (uint i = 0; i < input.length; i++) {
            for (uint j = i+1; j < input.length; j++) {
                for (uint k = j+1; k < input.length; k++) {
                    combinations[index][0] = input[i];
                    combinations[index][1] = input[j];
                    combinations[index][2] = input[k];
                    index++;
                }
            }
        }
        return combinations;
    }

    function getCombinationCount(string[] memory input) public pure returns (uint256) {
        require(input.length >= 3, "Input array must have at least 3 elements.");
        uint256 n = input.length;
        uint256 k = 3;
        uint256 factorialn = factorial(n);
        uint256 factorialk = factorial(k);
        uint256 factorialnminusK = factorial(n-k);
        return factorialn / (factorialk * factorialnminusK);
    }

    function factorial(uint256 n) private pure returns (uint256) {
        uint256 result = 1;
        for (uint256 i = 1; i <= n; i++) {
            result *= i;
        }
        return result;
    }

    function deployContract(string memory contractName, address targetAddr) private{
        bytes memory bytecode = abi.encodePacked(vm.getCode(contractName));
        address deployed ;
        assembly {
            deployed := create(0, add(bytecode, 0x20), mload(bytecode))
        }

        // Set the bytecode of an arbitrary address
        vm.etch(targetAddr, deployed.code);
    }

}
