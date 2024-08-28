// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

interface IGnosisProxy {
    function nonce() external view returns(uint256);
    function getChainId() external view returns(uint256);
    function execTransaction(address,uint256,bytes memory,uint8,uint256,uint256,uint256,address,address,bytes memory) external returns(bool);
    function encodeTransactionData(address, uint256, bytes calldata, uint8 , uint256, uint256, uint256, address, address, uint256) external view returns (bytes memory);
    function requiredTxGas(address, uint256, bytes calldata, uint8) external view returns(uint256);
}