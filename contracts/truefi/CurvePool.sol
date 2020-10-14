// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {TruePool, IERC20} from "./TruePool.sol";
import {ICurvePool} from "./interface/ICurvePool.sol";

contract CurvePool is TruePool {
    using SafeMath for uint256;

    ICurvePool public curvePool;

    uint8 constant N_TOKENS = 4;
    uint8 constant TUSD_INDEX = 3;

    constructor(ICurvePool _curve, IERC20 _currencyToken) public TruePool(_currencyToken, "CurveTUSDPool", "CurTUSD") {
        curvePool = _curve;
        currencyToken().approve(address(curvePool), uint256(-1));
        curvePool.token().approve(address(curvePool), uint256(-1));
    }

    function join(uint256 amount) external override {
        require(currencyToken().transferFrom(msg.sender, address(this), amount));

        uint256[N_TOKENS] memory amounts = [0, 0, 0, amount];
        uint256 minTokenAmount = curvePool.curve().calc_token_amount(amounts, true).mul(99).div(100);

        uint256 balanceBefore = curvePool.token().balanceOf(address(this));
        curvePool.add_liquidity(amounts, minTokenAmount);
        uint256 balanceAfter = curvePool.token().balanceOf(address(this));
        _mint(msg.sender, balanceAfter.sub(balanceBefore));
    }

    function exit(uint256 amount) external override {
        require(amount <= balanceOf(msg.sender), "CurvePool: Cannot withdraw amount bigger than available balance");

        uint256 minTokenAmount = curvePool.calc_withdraw_one_coin(amount, TUSD_INDEX).mul(99).div(100);

        uint256 balanceBefore = currencyToken().balanceOf(address(this));
        curvePool.remove_liquidity_one_coin(amount, TUSD_INDEX, minTokenAmount);
        uint256 balanceAfter = currencyToken().balanceOf(address(this));
        require(currencyToken().transfer(msg.sender, balanceAfter.sub(balanceBefore)));
        _burn(msg.sender, amount);
    }

    function borrow(uint256 amount) external override {
        // TODO
    }

    function repay(uint256 amount) external override {
        // TODO
    }

    function value() external override view returns (uint256) {
        return curvePool.calc_withdraw_one_coin(1 ether, TUSD_INDEX);
    }
}