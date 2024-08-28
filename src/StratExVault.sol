// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {GnosisSafeActions} from "../script/helpers/GnosisSafeActions.sol";
import {SafeProxy} from "../../lib/safe-contracts/contracts/proxies/SafeProxy.sol";
import {IPool} from "./interfaces/IPool.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract StratExVault is ERC4626, Ownable {

    IPool public yldrPool;
    SafeProxy public safeProxy;
    GnosisSafeActions public safeActions;
    mapping(address => bool) public isWhitelisted;

    modifier onlyWhitelisted() {
        require(isWhitelisted[msg.sender], "StratExVault: caller is not whitelisted");
        _;
    }

    constructor(
        IERC20 asset_, 
        IPool yldrPool_, 
        address safeProxy_
    ) ERC20("StratExVault", "SEV") ERC4626(asset_) Ownable(msg.sender) {
        yldrPool = yldrPool_;
        safeProxy = SafeProxy(payable(safeProxy_));
        safeActions = new GnosisSafeActions();
    }

    function setWhitelisted(address account) external onlyOwner {
        isWhitelisted[account] = true;
    }

    function setBlacklisted(address account) external onlyOwner {
        isWhitelisted[account] = false;
    }

    function deposit(
        uint256 assets, 
        address receiver
    ) public override onlyWhitelisted() returns (uint256 shares) {
        shares = previewDeposit(assets);
        super.deposit(assets, receiver);
        safeActions.approve(asset(), address(yldrPool), assets);
        IERC20(asset()).transfer(address(safeProxy), assets);
        safeActions.deposit(asset(), assets, address(safeProxy), 0);
    }

    function mint(
        uint256 shares, 
        address receiver
    ) public override onlyWhitelisted() returns (uint256 assets) {
        assets = previewMint(shares);
        super.mint(shares, receiver);
        safeActions.approve(asset(), address(yldrPool), assets);
        IERC20(asset()).transfer(address(safeProxy), assets);
        safeActions.deposit(asset(), assets, address(safeProxy), 0);
    }

    function withdraw(
        uint256 assets, 
        address receiver, 
        address owner
    ) public override onlyWhitelisted() returns (uint256 shares) {
        shares = previewWithdraw(assets);
        safeActions.withdraw(asset(), assets, address(safeProxy));
        safeActions.transfer(asset(), address(this), assets);
        super.withdraw(assets, receiver, owner);
    }

    function redeem(
        uint256 shares, 
        address receiver, 
        address owner
    ) public override onlyWhitelisted() returns (uint256 assets) {
        safeActions.withdraw(asset(), shares, address(safeProxy));
        safeActions.transfer(asset(), address(this), shares);
        super.redeem(shares, receiver, owner);
        assets = previewRedeem(shares);
    }
}
