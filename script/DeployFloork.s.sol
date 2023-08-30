// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Script.sol';

import {Floork} from '../src/Floork.sol';

contract DeployFloorkScript is Script {

    function run() public {
        // Load our seed phrase from a protected file
        uint privateKey = vm.envUint('PRIVATE_KEY');

        // Using the passed in the script call, has all subsequent calls (at this call
        // depth only) create transactions that can later be signed and sent onchain.
        vm.startBroadcast(privateKey);

        // Deploy our Floork contract
        new Floork(0xf59257E961883636290411c11ec5Ae622d19455e);

        // Stop collecting onchain transactions
        vm.stopBroadcast();
    }

}
