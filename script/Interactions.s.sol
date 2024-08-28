// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {StratExVault} from "../src/StratExVault.sol";
import {IUSDC} from "./interfaces/IUSDC.sol";
import {IPool} from "../src/interfaces/IPool.sol";
import {SigUtils} from "./helpers/SigUtils.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Safe } from "../../lib/safe-contracts/contracts/Safe.sol";
import { SafeProxy } from "../../lib/safe-contracts/contracts/proxies/SafeProxy.sol";
import { SafeProxyFactory } from "../../lib/safe-contracts/contracts/proxies/SafeProxyFactory.sol";

contract Interactions is Script {

    SigUtils public sigUtils;
    StratExVault public vault;
    IPool public yldrPool;
    IUSDC public usdc;
    address public constant actor = 0x9D388786B2F19d80480e67DaBFce382631264728;
    Safe safeSingleton;
    SafeProxyFactory proxyFactory;
    SafeProxy proxy;

    function setUp() public {
        yldrPool = IPool(0x54aD657851b6Ae95bA3380704996CAAd4b7751A3);
        usdc = IUSDC(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);
        sigUtils = new SigUtils(0x08d11903f8419e68b1b8721bcbe2e9fc68569122a77ef18c216f10b3b5112c78); // DOMAIN_SEPARATOR for USDC
        _deploySafe();
        vault = new StratExVault(usdc, yldrPool, address(proxy));
        vault.setWhitelisted(actor);
    }

    function run() public {
        vm.startBroadcast(actor);
        console.log("Actor balance before deposit: ", usdc.balanceOf(actor));
        _approveWithPermit(actor, address(vault), 250, uint256(0xe8ec3b9145a126a22a1bc0cedc016d5649b2ef4e3bd7d7fc52f06137744ffa61));
        vault.deposit(250, actor);
        console.log("Actor balance after deposit: ", usdc.balanceOf(actor));
        vault.withdraw(250, actor, actor);
        console.log("Actor balance after withdraw: ", usdc.balanceOf(actor));
    }

    function _deploySafe() internal {
        address deployer = vm.addr(uint256(0xe8ec3b9145a126a22a1bc0cedc016d5649b2ef4e3bd7d7fc52f06137744ffa61));
        address[] memory owners = new address[](1);
        owners[0] = vm.addr(uint256(0xe8ec3b9145a126a22a1bc0cedc016d5649b2ef4e3bd7d7fc52f06137744ffa61));
        // owners[1] = vm.addr(1);
        uint256 threshold = 1;

        vm.startBroadcast(deployer);
        safeSingleton = new Safe();
        proxyFactory = new SafeProxyFactory();

        proxy = proxyFactory.createProxyWithNonce(
            address(safeSingleton), 
            abi.encodeWithSelector(
                safeSingleton.setup.selector, 
                owners, 
                threshold, 
                address(0), 
                "", 
                address(0), 
                address(0), 
                0, 
                payable(0)
            ),
            35
        );

        vm.stopBroadcast();

        console.log("Gnosis Safe deployed at:", address(proxy));
    }

    function _approveWithPermit(address from_, address to_, uint256 amount_, uint256 signer_) internal {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: from_,
            spender: to_,
            value: amount_,
            nonce: 0,
            deadline: block.timestamp + 300
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signer_, digest);
        usdc.permit(
            permit.owner,
            permit.spender,
            permit.value,
            permit.deadline,
            v,
            r,
            s
        );
    }
}
