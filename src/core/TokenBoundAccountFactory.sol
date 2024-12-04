// src/core/TokenBoundAccountFactory.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./CrossChainTBA.sol";

contract TokenBoundAccountFactory {
    using Clones for address;

    address public implementation;
    
    event AccountCreated(address account, address owner);
    
    constructor(address _implementation) {
        implementation = _implementation;
    }
    
    function createAccount(address owner) external returns (address) {
        address clone = implementation.clone();
        CrossChainTBA(clone).initialize(owner);
        
        emit AccountCreated(clone, owner);
        return clone;
    }
}
