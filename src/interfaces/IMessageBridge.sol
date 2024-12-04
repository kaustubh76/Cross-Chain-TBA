// src/interfaces/IMessageBridge.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMessageBridge {
    function sendMessage(
        uint256 destinationChain,
        bytes calldata message
    ) external payable;
    
    function receiveMessage(
        uint256 sourceChain,
        bytes calldata message
    ) external;
}
