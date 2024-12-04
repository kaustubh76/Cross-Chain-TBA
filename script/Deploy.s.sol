// script/Deploy.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/CrossChainTransferManager.sol";
import "../src/core/CrossChainTBA.sol";
import "../src/core/TokenBoundAccountFactory.sol";
import "../src/core/ERC6551Registry.sol";

contract Deploy is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address messageBridge = vm.envAddress("MESSAGE_BRIDGE");
        
        vm.startBroadcast(deployerPrivateKey);

        // Deploy implementation
        CrossChainTBA implementation = new CrossChainTBA();
        console.log("Implementation deployed at:", address(implementation));
        
        // Deploy registry
        ERC6551Registry registry = new ERC6551Registry();
        console.log("Registry deployed at:", address(registry));
        
        // Deploy factory
        TokenBoundAccountFactory factory = new TokenBoundAccountFactory(
            address(implementation)
        );
        console.log("Factory deployed at:", address(factory));
        
        // Deploy manager
        CrossChainTransferManager manager = new CrossChainTransferManager(
            address(registry),
            messageBridge,
            address(implementation)
        );
        console.log("Manager deployed at:", address(manager));
        
        // Setup supported chains
        uint256[] memory supportedChains = _getSupportedChains();
        for (uint256 i = 0; i < supportedChains.length; i++) {
            manager.setSupportedChain(supportedChains[i], true);
            console.log("Enabled chain:", supportedChains[i]);
        }

        vm.stopBroadcast();
    }
    
    function _getSupportedChains() internal pure returns (uint256[] memory) {
        uint256[] memory chains = new uint256[](4);
        chains[0] = 1; // Ethereum
        chains[1] = 137; // Polygon
        chains[2] = 56; // BSC
        chains[3] = 43114; // Avalanche
        return chains;
    }
}