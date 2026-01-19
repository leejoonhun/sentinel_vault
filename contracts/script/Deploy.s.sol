// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Script, console } from "forge-std/Script.sol";

contract DeployScript is Script {
    function setUp() public { }

    function run() public {
        vm.startBroadcast();

        // TODO: Deploy SentinelVault
        console.log("Deploying Sentinel Protocol...");

        vm.stopBroadcast();
    }
}
