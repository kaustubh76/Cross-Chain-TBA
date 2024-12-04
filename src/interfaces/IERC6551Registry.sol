// src/interfaces/IERC6551Registry.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC6551Registry {
    event AccountCreated(
        address account,
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt
    );

    function createAccount(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt,
        bytes calldata initData
    ) external returns (address);

    function account(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt
    ) external view returns (address);
}

// src/interfaces/IERC6551Account.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC6551Account {
    function token()
        external
        view
        returns (uint256 chainId, address tokenContract, uint256 tokenId);
        
    function executeCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory);
}