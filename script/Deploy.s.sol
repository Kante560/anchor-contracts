// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/Anchor.sol";

contract DeployAnchor is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        Anchor anchor = new Anchor();

        console.log("=================================");
        console.log("Anchor deployed at:", address(anchor));
        console.log("Network chain ID: ", block.chainid);
        console.log("=================================");
        console.log("Next: copy address to anchor-frontend/lib/contract.ts");

        vm.stopBroadcast();
    }
}
