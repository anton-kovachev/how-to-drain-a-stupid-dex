// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Dex} from "../src/Dex.sol";
import {SwappableToken} from "../src/SwappableToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DexTest is Test {
    uint256 constant INITIAL_SUPPLY = 1000 ether;
    uint256 constant STARTING_DEX_BALANCE = 100 ether;
    uint256 constant STARTING_USER_BALANCE = 10 ether;

    address public owner = makeAddr("owner");
    address public user = makeAddr("user");

    Dex dex;
    SwappableToken token1;
    SwappableToken token2;

    function setUp() public {
        vm.startPrank(owner);
        dex = new Dex();
        token1 = new SwappableToken(
            address(dex),
            "Token 1",
            "TK1",
            INITIAL_SUPPLY
        );
        token2 = new SwappableToken(
            address(dex),
            "Token 2",
            "TK2",
            INITIAL_SUPPLY
        );

        dex.setTokens(address(token1), address(token2));
        dex.approve(address(dex), type(uint256).max);

        dex.addLiquidity(address(token1), STARTING_DEX_BALANCE);
        dex.addLiquidity(address(token2), STARTING_DEX_BALANCE);

        token1.transfer(user, STARTING_USER_BALANCE);
        token2.transfer(user, STARTING_USER_BALANCE);
        vm.stopPrank();
    }

    function testMultiSwap() public {
        // Swap 10 TK1 for TK2
        vm.startPrank(user);

        address tokenFrom = address(token1);
        address tokenTo = address(token2);

        dex.approve(address(dex), type(uint256).max);

        console2.log("Token From: ", tokenFrom);
        console2.log("Token To: ", tokenTo);
        console2.log("Initial Dex Balances:");
        console2.log("Token 1:", token1.balanceOf(address(dex)));
        console2.log("Token 2:", token2.balanceOf(address(dex)));

        console2.log("Initial User Balances:");
        console2.log("Token 1:", token1.balanceOf(user));
        console2.log("Token 2:", token2.balanceOf(user));

        while (
            token1.balanceOf(address(dex)) > 0 &&
            token2.balanceOf(address(dex)) > 0
        ) {
            uint256 amountToSwap = IERC20(tokenFrom).balanceOf(user);
            uint256 amountToReceive = dex.getSwapPrice(
                tokenFrom,
                tokenTo,
                amountToSwap
            );

            if (IERC20(tokenTo).balanceOf(address(dex)) < amountToReceive) {
                amountToSwap = dex.getSwapPrice(
                    tokenTo,
                    tokenFrom,
                    IERC20(tokenTo).balanceOf(address(dex))
                );
            }

            dex.swap(tokenFrom, tokenTo, amountToSwap);
            (tokenFrom, tokenTo) = (tokenTo, tokenFrom);

            console2.log("Token From: ", tokenFrom);
            console2.log("Token To: ", tokenTo);
            console2.log("Current Dex Balances:");
            console2.log("Token 1:", token1.balanceOf(address(dex)));
            console2.log("Token 2:", token2.balanceOf(address(dex)));

            console2.log("Current User Balances:");
            console2.log("Token 1:", token1.balanceOf(user));
            console2.log("Token 2:", token2.balanceOf(user));
        }
        vm.stopPrank();

        console2.log("Token From: ", tokenFrom);
        console2.log("Token To: ", tokenTo);
        console2.log("End Dex Balances:");
        console2.log("Token 1:", token1.balanceOf(address(dex)));
        console2.log("Token 2:", token2.balanceOf(address(dex)));

        console2.log("End User Balances:");
        console2.log("Token 1:", token1.balanceOf(user));
        console2.log("Token 2:", token2.balanceOf(user));
    }
}
