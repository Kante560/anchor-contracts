// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/AnchorV2.sol";

contract DeployAnchorV2 is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address arbitrator = vm.envAddress("ARBITRATOR_ADDRESS");

        require(arbitrator != address(0), "ARBITRATOR_ADDRESS not set in .env");

        vm.startBroadcast(deployerKey);

        AnchorV2 anchor = new AnchorV2(arbitrator);

        console.log("=================================");
        console.log("AnchorV2 deployed at:", address(anchor));
        console.log("Arbitrator assigned: ", arbitrator);
        console.log("Network chain ID: ", block.chainid);
        console.log("=================================");
        console.log("Next: copy address to anchor-frontend/lib/contract.ts");

        vm.stopBroadcast();
    }
}
