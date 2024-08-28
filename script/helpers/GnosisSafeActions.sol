// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {IGnosisProxy} from "../interfaces/IGnosisProxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GnosisSafeActions is Script {

    address gnosisProxy;
    address yldrPool;
    bytes32 private constant SAFE_TX_TYPEHASH = 0xbb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8;
    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH = 0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218;
    bytes32 public domainSeparator;

    constructor () {
        gnosisProxy = 0xc4Bc01a52Fc3B98202E1A229904fAcecBEB4aA0E;
        yldrPool = 0x54aD657851b6Ae95bA3380704996CAAd4b7751A3;
        uint256 chainId = IGnosisProxy(gnosisProxy).getChainId();
        domainSeparator = keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, chainId, gnosisProxy));
    }

    function deposit(
        address asset_,
        uint256 amount_,
        address onBehalfOf_,
        uint16 referralCode_
    ) public {
        bytes memory signature = _signDeposit(asset_, amount_, onBehalfOf_, referralCode_);
        bool success = IGnosisProxy(gnosisProxy).execTransaction(
            yldrPool,
            0,
            _encodeDeposit(
                asset_,
                amount_,
                onBehalfOf_,
                referralCode_
            ),
            0,
            0,
            0,
            0,
            address(0),
            address(0),
            signature
        );
        require(success, "failed");
    }

    function withdraw(
        address asset_,
        uint256 amount_,
        address onBehalfOf_
    ) public {
        bytes memory signature = _signWithdraw(asset_, amount_, onBehalfOf_);
        bool success = IGnosisProxy(gnosisProxy).execTransaction(
            yldrPool,
            0,
            _encodeWithdraw(
                asset_,
                amount_,
                onBehalfOf_
            ),
            0,
            0,
            0,
            0,
            address(0),
            address(0),
            signature
        );
        require(success, "failed");
    }

    function transfer(
        address asset_,
        address to_,
        uint256 amount_
    ) public {
        bytes memory signature = _signTransfer(asset_, to_, amount_);
        bool success = IGnosisProxy(gnosisProxy).execTransaction(
            asset_,
            0,
            _encodeTransfer(
                to_,
                amount_
            ),
            0,
            0,
            0,
            0,
            address(0),
            address(0),
            signature
        );
        require(success, "failed");
    }

    function approve(
        address asset_,
        address spender_,
        uint256 amount_
    ) public {
        bytes memory signature = _signApprove(asset_, spender_, amount_);
        bool success = IGnosisProxy(gnosisProxy).execTransaction(
            asset_,
            0,
            _encodeApprove(spender_, amount_),
            0,
            0,
            0,
            0,
            address(0),
            address(0),
            signature
        );
        require(success, "failed");
    }

    function _signDeposit(
        address asset_,
        uint256 amount_,
        address onBehalfOf_,
        uint16 referralCode_
    ) private view returns (bytes memory) {
        bytes memory txHashData = IGnosisProxy(gnosisProxy).encodeTransactionData(
                    yldrPool,
                    0,
                    _encodeDeposit(
                        asset_,
                        amount_,
                        onBehalfOf_,
                        referralCode_
                    ),
                    0,
                    0,
                    0,
                    0,
                    address(0),
                    address(0),
                    IGnosisProxy(gnosisProxy).nonce()
                );
        bytes32 txHash = keccak256(txHashData);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xe8ec3b9145a126a22a1bc0cedc016d5649b2ef4e3bd7d7fc52f06137744ffa61, txHash);
        address signer = ecrecover(txHash, v, r, s);
        require(signer != address(0), "invalid signer");
        return abi.encodePacked(r,s,v);
    }

    function _signWithdraw(
        address asset_,
        uint256 amount_,
        address onBehalfOf_
    ) private view returns (bytes memory) {
        bytes memory txHashData = IGnosisProxy(gnosisProxy).encodeTransactionData(
                    yldrPool,
                    0,
                    _encodeWithdraw(
                        asset_,
                        amount_,
                        onBehalfOf_
                    ),
                    0,
                    0,
                    0,
                    0,
                    address(0),
                    address(0),
                    IGnosisProxy(gnosisProxy).nonce()
                );
        bytes32 txHash = keccak256(txHashData);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xe8ec3b9145a126a22a1bc0cedc016d5649b2ef4e3bd7d7fc52f06137744ffa61, txHash);
        address signer = ecrecover(txHash, v, r, s);
        require(signer != address(0), "invalid signer");
        return abi.encodePacked(r,s,v);
    }

    function _signTransfer(
        address asset_,
        address to_,
        uint256 amount_
    ) private view returns (bytes memory) {
        bytes memory txHashData = IGnosisProxy(gnosisProxy).encodeTransactionData(
                    asset_,
                    0,
                    _encodeTransfer(
                        to_,
                        amount_
                    ),
                    0,
                    0,
                    0,
                    0,
                    address(0),
                    address(0),
                    IGnosisProxy(gnosisProxy).nonce()
                );
        bytes32 txHash = keccak256(txHashData);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xe8ec3b9145a126a22a1bc0cedc016d5649b2ef4e3bd7d7fc52f06137744ffa61, txHash);
        address signer = ecrecover(txHash, v, r, s);
        require(signer != address(0), "invalid signer");
        return abi.encodePacked(r,s,v);
    }

    function _signApprove(
        address asset_,
        address spender_,
        uint256 amount_
    ) private view returns (bytes memory) {
        bytes memory txHashData = IGnosisProxy(gnosisProxy).encodeTransactionData(
                    asset_,
                    0,
                    _encodeApprove(spender_, amount_),
                    0,
                    0,
                    0,
                    0,
                    address(0),
                    address(0),
                    IGnosisProxy(gnosisProxy).nonce()
                );
        bytes32 txHash = keccak256(txHashData);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xe8ec3b9145a126a22a1bc0cedc016d5649b2ef4e3bd7d7fc52f06137744ffa61, txHash);
        address signer = ecrecover(txHash, v, r, s);
        require(signer != address(0), "invalid signer");
        return abi.encodePacked(r,s,v);
    }

    function _encodeDeposit(
        address asset_,
        uint256 amount_,
        address onBehalfOf_,
        uint16 referralCode_
    ) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(0x617ba037), asset_, amount_, onBehalfOf_, referralCode_);
    }

    function _encodeWithdraw(
        address asset_,
        uint256 amount_,
        address onBehalfOf_
    ) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(0x69328dec), asset_, amount_, onBehalfOf_);
    }

    function _encodeTransfer(
        address to_,
        uint256 amount_
    ) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(IERC20.transfer.selector, to_, amount_);
    }

    function _encodeApprove(
        address spender_,
        uint256 amount_
    ) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(0x095ea7b3), spender_, amount_);
    }
}
