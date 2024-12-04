// test/CrossChainTransfer.t.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/core/CrossChainTransferManager.sol";
import "../src/core/CrossChainTBA.sol";
import "../src/core/TokenBoundAccountFactory.sol";
import "../src/core/ERC6551Registry.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("Mock", "MCK") {
        _mint(msg.sender, 1000000 * 10**18);
    }
}

contract MockMessageBridge is IMessageBridge {
    event MessageSent(uint256 destinationChain, bytes message);
    
    function sendMessage(uint256 destinationChain, bytes calldata message) 
        external 
        payable 
    {
        emit MessageSent(destinationChain, message);
    }
    
    function receiveMessage(uint256 sourceChain, bytes calldata message) 
        external 
    {
        // Mock implementation
    }
}

contract CrossChainTransferTest is Test {
    CrossChainTransferManager public manager;
    ERC6551Registry public registry;
    CrossChainTBA public implementation;
    TokenBoundAccountFactory public factory;
    MockMessageBridge public bridge;
    MockERC20 public token;
    
    address public owner = address(1);
    address public user = address(2);
    uint256 public constant CHAIN_ID_1 = 1;
    uint256 public constant CHAIN_ID_2 = 2;
    
    event TransferInitiated(
        address indexed fromTBA,
        uint256 indexed destinationChain,
        bytes32 transferId
    );
    
    function setUp() public {
        // Deploy mock contracts
        token = new MockERC20();
        bridge = new MockMessageBridge();
        
        // Deploy core contracts
        implementation = new CrossChainTBA();
        registry = new ERC6551Registry();
        factory = new TokenBoundAccountFactory(address(implementation));
        
        // Deploy manager
        manager = new CrossChainTransferManager(
            address(registry),
            address(bridge),
            address(implementation)
        );
        
        // Setup supported chains
        vm.startPrank(owner);
        manager.setSupportedChain(CHAIN_ID_1, true);
        manager.setSupportedChain(CHAIN_ID_2, true);
        vm.stopPrank();
        
        // Setup user with tokens
        token.transfer(user, 1000 * 10**18);
    }
    
    function testInitiateTransfer() public {
        // Create TBA for user
        vm.startPrank(user);
        address tba = factory.createAccount(user);
        
        // Prepare transfer parameters
        address[] memory tokens = new address[](1);
        tokens[0] = address(token);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100 * 10**18;
        
        bytes memory params = CrossChainUtils.encodeTransferParams(
            tokens,
            amounts
        );
        
        // Expect event emission
        vm.expectEmit(true, true, false, true);
        emit TransferInitiated(tba, CHAIN_ID_2, bytes32(0));
        
        // Initiate transfer
        bytes32 transferId = manager.initiateTransfer(
            tba,
            CHAIN_ID_2,
            params
        );
        
        // Verify transfer was processed
        assertTrue(manager.processedTransfers(transferId));
        vm.stopPrank();
    }
    
    function testCompleteTransfer() public {
        // Setup initial TBA and transfer
        vm.startPrank(user);
        address sourceTBA = factory.createAccount(user);
        
        // Transfer tokens to TBA
        token.transfer(sourceTBA, 100 * 10**18);
        
        // Prepare transfer parameters
        address[] memory tokens = new address[](1);
        tokens[0] = address(token);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100 * 10**18;
        
        bytes memory params = CrossChainUtils.encodeTransferParams(
            tokens,
            amounts
        );
        
        // Complete transfer
        bytes32 transferId = keccak256(
            abi.encodePacked(
                CHAIN_ID_1,
                CHAIN_ID_2,
                sourceTBA,
                user,
                block.timestamp
            )
        );
        
        manager.completeTransfer(
            transferId,
            sourceTBA,
            user,
            CHAIN_ID_1,
            params
        );
        
        // Verify transfer was processed
        assertTrue(manager.processedTransfers(transferId));
        vm.stopPrank();
    }
    
    function testFailUnsupportedChain() public {
        vm.startPrank(user);
        address tba = factory.createAccount(user);
        
        // Try to initiate transfer to unsupported chain
        bytes memory params = "";
        vm.expectRevert("Unsupported chain");
        manager.initiateTransfer(tba, 999, params);
        vm.stopPrank();
    }
}