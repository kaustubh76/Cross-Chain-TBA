// src/libraries/CrossChainUtils.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library CrossChainUtils {
    function encodeTransferParams(
        address[] memory tokens,
        uint256[] memory amounts
    ) public pure returns (bytes memory) {
        return abi.encode(tokens, amounts);
    }

    function decodeTransferParams(bytes memory params)
        public
        pure
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        return abi.decode(params, (address[], uint256[]));
    }
}