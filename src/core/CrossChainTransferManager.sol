// src/core/CrossChainTransferManager.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IERC6551Registry.sol";
import "../interfaces/IMessageBridge.sol";
import "./CrossChainTBA.sol";

contract CrossChainTransferManager is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // State variables
    mapping(uint256 => bool) public supportedChains;
    mapping(bytes32 => bool) public processedTransfers;
    IERC6551Registry public immutable registry;
    IMessageBridge public immutable messageBridge;
    address public owner;
    address public implementation;

    // Events
    event TransferInitiated(
        address indexed fromTBA,
        uint256 indexed destinationChain,
        bytes32 transferId
    );
    event TransferCompleted(
        address indexed toTBA,
        uint256 indexed sourceChain,
        bytes32 transferId
    );
    event ChainStatusUpdated(uint256 chainId, bool supported);
    event ImplementationUpdated(address newImplementation);

    constructor(
        address _registry,
        address _messageBridge,
        address _implementation
    ) {
        registry = IERC6551Registry(_registry);
        messageBridge = IMessageBridge(_messageBridge);
        implementation = _implementation;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    function initiateTransfer(
        address tba,
        uint256 destinationChain,
        bytes calldata params
    ) external nonReentrant returns (bytes32) {
        require(supportedChains[destinationChain], "Unsupported chain");
        require(IERC6551Account(tba).owner() == msg.sender, "Not TBA owner");

        bytes32 transferId = keccak256(
            abi.encodePacked(
                block.chainid,
                destinationChain,
                tba,
                msg.sender,
                block.timestamp
            )
        );
        
        require(!processedTransfers[transferId], "Transfer exists");
        processedTransfers[transferId] = true;

        bytes memory message = abi.encode(
            transferId,
            tba,
            msg.sender,
            params
        );
        
        messageBridge.sendMessage(destinationChain, message);

        emit TransferInitiated(tba, destinationChain, transferId);
        return transferId;
    }

    function completeTransfer(
        bytes32 transferId,
        address sourceTBA,
        address originalOwner,
        uint256 sourceChain,
        bytes calldata params
    ) external nonReentrant {
        require(!processedTransfers[transferId], "Transfer processed");
        processedTransfers[transferId] = true;

        address newTBA = _createTBA(sourceTBA, originalOwner, params);
        _handleAssetTransfer(newTBA, params);

        emit TransferCompleted(newTBA, sourceChain, transferId);
    }

    function _createTBA(
        address sourceTBA,
        address originalOwner,
        bytes calldata params
    ) internal returns (address) {
        // Extract token details from source TBA
        (address tokenContract, uint256 tokenId) = _extractTBADetails(sourceTBA);
        
        bytes memory initData = abi.encodeWithSelector(
            CrossChainTBA.initialize.selector,
            originalOwner
        );

        return registry.createAccount(
            implementation,
            block.chainid,
            tokenContract,
            tokenId,
            uint256(keccak256(abi.encodePacked(block.timestamp))),
            initData
        );
    }

    function _extractTBADetails(address tba) 
        internal 
        view 
        returns (address tokenContract, uint256 tokenId) 
    {
        // Implementation specific to your TBA structure
        return (address(0), 0); // Placeholder
    }

    function _handleAssetTransfer(address newTBA, bytes calldata params)
        internal
    {
        // Decode transfer parameters
        (address[] memory tokens, uint256[] memory amounts) = abi.decode(
            params,
            (address[], uint256[])
        );

        // Transfer each token
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).safeTransfer(newTBA, amounts[i]);
        }
    }

    // Admin functions
    function setSupportedChain(uint256 chainId, bool supported) 
        external 
        onlyOwner 
    {
        supportedChains[chainId] = supported;
        emit ChainStatusUpdated(chainId, supported);
    }

    function setImplementation(address newImplementation) 
        external 
        onlyOwner 
    {
        implementation = newImplementation;
        emit ImplementationUpdated(newImplementation);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }
}