// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Dex} from "../src/Dex.sol";
import {DexAttacker} from "../src/DexAttacker.sol";
import {SwappableToken} from "../src/SwappableToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DexAttackerTest is Test {
    uint256 constant INITIAL_SUPPLY = 1000 ether;
    uint256 constant STARTING_DEX_BALANCE = 100 ether;
    uint256 constant STARTING_ATTACKER_BALANCE = 10 ether;

    address public owner = makeAddr("owner");
    address public attacker = makeAddr("attacker");

    Dex dex;
    DexAttacker dexAttacker;
    SwappableToken token1;
    SwappableToken token2;

    function setUp() public {
        vm.startPrank(owner);
        
        // Deploy DEX and tokens
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

        // Setup DEX
        dex.setTokens(address(token1), address(token2));
        dex.approve(address(dex), type(uint256).max);

        // Add liquidity to DEX
        dex.addLiquidity(address(token1), STARTING_DEX_BALANCE);
        dex.addLiquidity(address(token2), STARTING_DEX_BALANCE);

        vm.stopPrank();
    }

    function testDrainDex() public {
        // Deploy attacker contract
        vm.prank(attacker);
        dexAttacker = new DexAttacker(address(dex));

        // Fund the attacker contract with initial tokens
        vm.startPrank(owner);
        token1.transfer(address(dexAttacker), STARTING_ATTACKER_BALANCE);
        token2.transfer(address(dexAttacker), STARTING_ATTACKER_BALANCE);
        vm.stopPrank();

        console2.log("=== INITIAL STATE ===");
        console2.log("DEX Balances:");
        console2.log("Token 1:", token1.balanceOf(address(dex)));
        console2.log("Token 2:", token2.balanceOf(address(dex)));
        console2.log("");
        console2.log("Attacker Contract Balances:");
        console2.log("Token 1:", token1.balanceOf(address(dexAttacker)));
        console2.log("Token 2:", token2.balanceOf(address(dexAttacker)));
        console2.log("");

        // Execute the drain attack
        vm.prank(attacker);
        dexAttacker.drainDex();

        console2.log("=== AFTER ATTACK ===");
        console2.log("DEX Balances:");
        console2.log("Token 1:", token1.balanceOf(address(dex)));
        console2.log("Token 2:", token2.balanceOf(address(dex)));
        console2.log("");
        console2.log("Attacker Contract Balances:");
        console2.log("Token 1:", token1.balanceOf(address(dexAttacker)));
        console2.log("Token 2:", token2.balanceOf(address(dexAttacker)));
        console2.log("");

        // Verify that one of the DEX's token balances is 0
        bool token1Drained = token1.balanceOf(address(dex)) == 0;
        bool token2Drained = token2.balanceOf(address(dex)) == 0;
        
        assertTrue(
            token1Drained || token2Drained,
            "At least one token should be drained from DEX"
        );

        // Verify that the attacker contract has more than the initial balance
        uint256 attackerToken1Balance = token1.balanceOf(address(dexAttacker));
        uint256 attackerToken2Balance = token2.balanceOf(address(dexAttacker));
        
        assertTrue(
            attackerToken1Balance > STARTING_ATTACKER_BALANCE ||
                attackerToken2Balance > STARTING_ATTACKER_BALANCE,
            "Attacker should have gained tokens"
        );

        console2.log("=== ATTACK SUCCESSFUL ===");
        if (token1Drained) {
            console2.log("Token 1 has been completely drained from the DEX!");
        }
        if (token2Drained) {
            console2.log("Token 2 has been completely drained from the DEX!");
        }
    }

    function testWithdrawTokens() public {
        // Deploy attacker contract
        vm.prank(attacker);
        dexAttacker = new DexAttacker(address(dex));

        // Fund the attacker contract
        vm.startPrank(owner);
        token1.transfer(address(dexAttacker), STARTING_ATTACKER_BALANCE);
        token2.transfer(address(dexAttacker), STARTING_ATTACKER_BALANCE);
        vm.stopPrank();

        // Execute the drain attack
        vm.prank(attacker);
        dexAttacker.drainDex();

        // Get balances before withdrawal
        uint256 attackerContractToken1 = token1.balanceOf(address(dexAttacker));
        uint256 attackerContractToken2 = token2.balanceOf(address(dexAttacker));
        
        // Withdraw tokens to attacker's EOA
        vm.startPrank(attacker);
        dexAttacker.withdrawTokens(
            address(token1),
            attacker,
            attackerContractToken1
        );
        dexAttacker.withdrawTokens(
            address(token2),
            attacker,
            attackerContractToken2
        );
        vm.stopPrank();

        console2.log("=== AFTER WITHDRAWAL ===");
        console2.log("Attacker EOA Balances:");
        console2.log("Token 1:", token1.balanceOf(attacker));
        console2.log("Token 2:", token2.balanceOf(attacker));

        // Verify tokens were transferred
        assertEq(
            token1.balanceOf(attacker),
            attackerContractToken1,
            "Token1 should be withdrawn"
        );
        assertEq(
            token2.balanceOf(attacker),
            attackerContractToken2,
            "Token2 should be withdrawn"
        );
        assertEq(
            token1.balanceOf(address(dexAttacker)),
            0,
            "Attacker contract should have 0 Token1"
        );
        assertEq(
            token2.balanceOf(address(dexAttacker)),
            0,
            "Attacker contract should have 0 Token2"
        );
    }

    function testGetTokenBalance() public {
        // Deploy attacker contract
        vm.prank(attacker);
        dexAttacker = new DexAttacker(address(dex));

        // Fund the attacker contract
        vm.startPrank(owner);
        token1.transfer(address(dexAttacker), STARTING_ATTACKER_BALANCE);
        token2.transfer(address(dexAttacker), STARTING_ATTACKER_BALANCE);
        vm.stopPrank();

        // Test getTokenBalance function
        assertEq(
            dexAttacker.getTokenBalance(address(token1)),
            STARTING_ATTACKER_BALANCE,
            "Should return correct Token1 balance"
        );
        assertEq(
            dexAttacker.getTokenBalance(address(token2)),
            STARTING_ATTACKER_BALANCE,
            "Should return correct Token2 balance"
        );
    }
}
