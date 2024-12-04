// src/core/ERC6551Registry.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IERC6551Registry.sol";

contract ERC6551Registry is IERC6551Registry {
    error InitializationFailed();

    function createAccount(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt,
        bytes calldata initData
    ) external returns (address) {
        bytes32 bytecodeHash = keccak256(
            abi.encodePacked(
                hex"3d602d80600a3d3981f3363d3d373d3d3d363d73",
                implementation,
                hex"5af43d82803e903d91602b57fd5bf3"
            )
        );

        bytes32 salt_ = keccak256(
            abi.encode(chainId, tokenContract, tokenId, salt)
        );

        address account = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            address(this),
                            salt_,
                            bytecodeHash
                        )
                    )
                )
            )
        );

        if (account.code.length == 0) {
            account = address(new ERC6551AccountProxy{salt: salt_}(implementation));
            if (initData.length > 0) {
                (bool success, ) = account.call(initData);
                if (!success) revert InitializationFailed();
            }
        }

        return account;
    }

    function account(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt
    ) external view returns (address) {
        bytes32 bytecodeHash = keccak256(
            abi.encodePacked(
                hex"3d602d80600a3d3981f3363d3d373d3d3d363d73",
                implementation,
                hex"5af43d82803e903d91602b57fd5bf3"
            )
        );

        bytes32 salt_ = keccak256(
            abi.encode(chainId, tokenContract, tokenId, salt)
        );

        return address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            address(this),
                            salt_,
                            bytecodeHash
                        )
                    )
                )
            )
        );
    }
}