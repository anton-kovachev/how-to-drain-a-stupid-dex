# How to Drain a DEX 🔴

A comprehensive educational project demonstrating a critical price manipulation vulnerability in a simple automated market maker (AMM) decentralized exchange implementation.

## 📋 Table of Contents

- [Business Case](#-business-case)
- [Vulnerability Overview](#-vulnerability-overview)
- [Technical Showcase](#-technical-showcase)
- [Technologies Used](#-technologies-used)
- [Project Structure](#-project-structure)
- [Setup & Installation](#-setup--installation)
- [Usage](#-usage)
- [How the Attack Works](#-how-the-attack-works)
- [Security Lessons](#-security-lessons)
- [Test Results](#-test-results)
- [License](#-license)

## 🎯 Business Case

This project serves as an educational resource for smart contract developers, auditors, and security researchers to understand:

- **Price Manipulation Vulnerabilities**: How naive pricing formulas in AMMs can be exploited
- **Attack Vector Analysis**: Step-by-step demonstration of a realistic DEX drain attack
- **Security Best Practices**: What developers should avoid when building DEX protocols
- **Audit Training**: Practical examples for security auditors to identify similar vulnerabilities

### Real-World Impact

Similar vulnerabilities have led to millions of dollars in losses across DeFi protocols. This project demonstrates:
- How an attacker with minimal initial capital can drain protocol reserves
- The importance of proper price oracle implementation
- Why constant product formulas (like Uniswap's x*y=k) are preferred over linear pricing

## 🔍 Vulnerability Overview

The vulnerable DEX implementation uses a **flawed pricing mechanism**:

```solidity
price = (amount * toTokenBalance) / fromTokenBalance
```

This linear pricing model allows attackers to:
1. Manipulate the price ratio through sequential swaps
2. Extract more value with each iteration
3. Completely drain one token from the liquidity pool

**Severity**: 🔴 Critical - Complete loss of protocol funds

## 🎪 Technical Showcase

### Smart Contracts

#### 1. Vulnerable DEX (`Dex.sol`)
- Simple AMM implementation with flawed pricing
- Basic swap functionality
- Liquidity management
- **Vulnerability**: Linear price calculation without slippage protection

#### 2. SwappableToken (`SwappableToken.sol`)
- ERC20 token implementation
- Custom approval mechanism
- Used as liquidity pool tokens

#### 3. DexAttacker (`DexAttacker.sol`)
- Automated attack contract
- Implements the drain strategy
- Demonstrates real-world exploit execution

### Key Features

- ✅ Complete attack automation via smart contract
- ✅ Comprehensive test suite with detailed logging
- ✅ Gas-optimized attack implementation
- ✅ Educational comments explaining each step
- ✅ Withdrawal functionality for extracted funds

## 🛠 Technologies Used

### Core Stack

- **[Solidity ^0.8.0](https://soliditylang.org/)** - Smart contract programming language
- **[Foundry](https://book.getfoundry.sh/)** - Blazing fast Ethereum development framework
  - **Forge** - Testing framework
  - **Cast** - CLI for smart contract interactions
  - **Anvil** - Local Ethereum node

### Libraries

- **[OpenZeppelin Contracts v5.0.2](https://docs.openzeppelin.com/contracts/)** - Secure smart contract components
  - ERC20 token standard
  - Ownable access control
  - IERC20 interface
- **[forge-std](https://github.com/foundry-rs/forge-std)** - Foundry standard library for testing

### Development Tools

- **VS Code** - Primary IDE
- **Solidity Language Server** - Syntax highlighting and IntelliSense
- **Git** - Version control

## 📁 Project Structure

```
how-to-drain-a-dex/
├── src/
│   ├── Dex.sol                 # Vulnerable DEX implementation
│   ├── SwappableToken.sol      # ERC20 tokens for liquidity pool
│   └── DexAttacker.sol         # Attack contract
├── test/
│   ├── Dex.t.sol              # DEX functionality tests
│   └── DexAttacker.t.sol      # Attack execution tests
├── lib/
│   ├── forge-std/             # Foundry testing library
│   └── openzeppelin-contracts/ # OpenZeppelin contracts
├── foundry.toml               # Foundry configuration
└── README.md                  # This file
```

## 🚀 Setup & Installation

### Prerequisites

- **Git** - Version control
- **Foundry** - Ethereum development toolkit

### Install Foundry

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Clone and Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/how-to-drain-a-dex.git
cd how-to-drain-a-dex

# Install dependencies
forge install

# Build the project
forge build
```

## 💻 Usage

### Run All Tests

```bash
forge test
```

### Run Specific Test with Verbose Output

```bash
# Test the multiswap functionality
forge test --match-test testMultiSwap -vvvv

# Test the attacker contract
forge test --match-test testDrainDex -vvvv
```

### Run Tests for Specific Contract

```bash
# Test DexAttacker contract only
forge test --match-contract DexAttackerTest -vv
```

### Generate Gas Report

```bash
forge test --gas-report
```

### Format Code

```bash
forge fmt
```

## 🎯 How the Attack Works

### Attack Flow

```
Initial State:
- DEX: 100 Token1, 100 Token2
- Attacker: 10 Token1, 10 Token2

Step 1: Swap 10 Token1 → Token2
- DEX: 110 Token1, 90.9 Token2
- Attacker: 0 Token1, 19.09 Token2

Step 2: Swap 19.09 Token2 → Token1
- DEX: 89.17 Token1, 110 Token2
- Attacker: 20.83 Token1, 0 Token2

... (iterations continue) ...

Final State:
- DEX: 0 Token1, 73.33 Token2 ✅ Token1 Drained!
- Attacker: 110 Token1, 36.67 Token2
```

### Attack Algorithm

The `DexAttacker` contract implements this strategy:

1. **Approve DEX** to spend attacker's tokens
2. **Initialize** with `tokenFrom = token1`, `tokenTo = token2`
3. **While loop** continues until one DEX balance reaches 0:
   - Calculate `amountToSwap` (all attacker's `tokenFrom`)
   - Calculate `amountToReceive` using DEX's price formula
   - **Check** if DEX has enough `tokenTo`
     - If not, calculate exact amount to drain remaining balance
   - Execute swap
   - Switch directions: `(tokenFrom, tokenTo) = (tokenTo, tokenFrom)`

### Key Vulnerability Points

```solidity
// ❌ VULNERABLE: Linear pricing without protection
function getSwapPrice(address from, address to, uint256 amount) 
    public view returns (uint256) 
{
    return ((amount * IERC20(to).balanceOf(address(this))) /
            IERC20(from).balanceOf(address(this)));
}

// ✅ BETTER: Use constant product formula (Uniswap v2 style)
// x * y = k (where k remains constant)
```

## 🛡️ Security Lessons

### What Went Wrong

1. **Linear Pricing Model**: The DEX uses a simple ratio that doesn't account for market depth
2. **No Slippage Protection**: No minimum output amount checks
3. **No Price Impact Limits**: Large swaps don't pay higher prices
4. **No Time Locks**: Attackers can execute multiple swaps in one transaction

### Best Practices

✅ **Use Constant Product Formula**: Implement `x * y = k` pricing model  
✅ **Implement Slippage Protection**: Require minimum output amounts  
✅ **Add Price Impact Limits**: Charge more for large swaps  
✅ **Use Time-Weighted Average Prices**: Prevent single-block manipulation  
✅ **Implement Circuit Breakers**: Pause on suspicious activity  
✅ **Regular Security Audits**: Have experts review your code

### Recommended Reading

- [Uniswap V2 Whitepaper](https://uniswap.org/whitepaper.pdf)
- [Curve Finance StableSwap Paper](https://curve.fi/files/stableswap-paper.pdf)
- [Smart Contract Security Best Practices](https://consensys.github.io/smart-contract-best-practices/)

## 📊 Test Results

```bash
Ran 3 tests for test/DexAttacker.t.sol:DexAttackerTest
[PASS] testDrainDex() (gas: 1103473)
[PASS] testGetTokenBalance() (gas: 786749)
[PASS] testWithdrawTokens() (gas: 1101165)

Suite result: ok. 3 passed; 0 failed; 0 skipped
```

### Attack Success Metrics

- **Initial Capital Required**: 10 tokens of each (10% of DEX liquidity)
- **Final Profit**: 100% of one token drained from DEX
- **Gas Cost**: ~1.1M gas
- **Number of Swaps**: ~6-7 iterations until complete drain
- **Success Rate**: 100% ✅

## 📚 Learning Resources

### For Developers

- Understand why constant product AMMs are more secure
- Learn to identify price manipulation vulnerabilities
- Practice defensive programming patterns

### For Auditors

- Use as training material for DEX audits
- Reference example for vulnerability reports
- Demonstrate attack feasibility to clients

### For Researchers

- Study economic attack vectors in DeFi
- Analyze game theory implications
- Explore mitigation strategies

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. Areas for contribution:

- Additional attack variations
- More comprehensive test cases
- Gas optimization improvements
- Documentation enhancements

## ⚠️ Disclaimer

This project is for **EDUCATIONAL PURPOSES ONLY**. 

- ❌ Do NOT use this code to attack real protocols
- ❌ Do NOT deploy these contracts on mainnet
- ⚠️ Attacking real protocols is illegal and unethical
- ✅ Use only for learning and testing on local networks

The authors are not responsible for any misuse of this code.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- OpenZeppelin for secure contract libraries
- Foundry team for excellent development tools
- DeFi security community for vulnerability research

---

**Built with ❤️ for the Ethereum security community**

## 📞 Contact

For questions, suggestions, or security discussions:
- Open an issue on GitHub
- Contribute via Pull Request
- Share your learnings with the community

---

### Quick Commands Reference

```bash
# Build
forge build
# Test specific contracts
forge test --match-contract DexAttackerTest -vv

# Test with maximum verbosity
forge test --match-test testDrainDex -vvvv

# Format code
forge fmt

# Gas report
forge test --gas-report
```

Remember: **Security is not optional. Learn, build safely, and audit thoroughly.** 🔒
