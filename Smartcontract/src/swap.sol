// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
contract Swapper is Ownable, ReentrancyGuard {
    // Token information
    struct Token {
         AggregatorV3Interface tokenpricefeed;
        address tokenAddress; // Address of the token (0x0 for ETH)
        uint256 decimal;      // Number of decimals (18 for ETH, USDT, DAI, RTL)
        string name;          // Token name (e.g., "USDT")
    }

    // Liquidity pool for a token pair
    struct LiquidityPool {
        uint256 token1Id;      // First token ID
        uint256 token2Id;      // Second token ID
        uint256 token1Balance; // Balance of token1
        uint256 token2Balance; // Balance of token2
    }

    // Hardcoded prices (in USD for ETH, USDT, DAI; in ETH for RTL, 18 decimals)
    
    mapping(uint256 => uint256) public tokenPrice;
    uint256 public constant ETH_PRICE_USD = 1755 * 10**18; // $1755
    uint256 public constant USDT_PRICE_USD = 1 * 10**18;   // $1
    uint256 public constant DAI_PRICE_USD = 1 * 10**18;    // $1
    uint256 public constant RTL_PRICE_ETH = 0.0003 * 10**18; // 0.05 ETH
    uint256 public constant SLIPPAGE_TOLERANCE = 98;

    // Token data
    mapping(uint256 => Token) public tokens;
    uint256 public tokenCount;

    // Liquidity pools
    mapping(bytes32 => LiquidityPool) public pools;
    mapping(bytes32 => bool) public poolExists;

    // Events
    event SwapExecuted(
        address indexed user,
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 fromAmount,
        uint256 toAmount
    );
    event LiquidityAdded(
        address indexed provider,
        uint256 token1Id,
        uint256 token2Id,
        uint256 token1Amount,
        uint256 token2Amount
    );
    event LiquidityRemoved(
        address indexed provider,
        uint256 token1Id,
        uint256 token2Id,
        uint256 token1Amount,
        uint256 token2Amount
    );

    constructor() Ownable(msg.sender) {
        // Initialize tokens
        tokens[0] = Token({
            tokenpricefeed: AggregatorV3Interface(0x91f3Ff344623aDC499eC6A34fC6311e8Abbf7880),
            tokenAddress: address(0),
            decimal: 18,
            name: "ETH"
        });
        tokenPrice[0] = ETH_PRICE_USD;

        tokens[1] = Token({
              tokenpricefeed: AggregatorV3Interface(0xAE17aC6B7565176B9dDAD32E0dFFdC52A221b351 ),
            tokenAddress: 0xA4A6888685FaECa07b5E42E00A05F92Ad3b921cA, // USDT address
            decimal: 18,
            name: "USDT"
        });
        tokenPrice[1] = USDT_PRICE_USD;

        tokens[2] = Token({
             tokenpricefeed: AggregatorV3Interface(0x7a0335B768C855792F225626F18de5291f142Ec9),
            tokenAddress: 0xE2608d2d22e59ebF715114e976bDC8Aa85891c1B, // DAI address
            decimal: 18,
            name: "DAI"
        });
        tokenPrice[2] = DAI_PRICE_USD;

        tokens[3] = Token({
             tokenpricefeed: AggregatorV3Interface(0xB5d3e4080dF612d33E78A523c9F4d3362ee2EC48),
            tokenAddress: 0x326e042259c7cf517Ca303f6Cbe732d33331645E, // RTL address
            decimal: 18,
            name: "RTL"
        });
        tokenPrice[3] = RTL_PRICE_ETH;

        tokenCount = 4;
    }

    // Helper function to calculate swap amount
    function _calculateSwapAmount(
        uint256 _fromTokenId,
        uint256 _toTokenId,
        uint256 _amountToSwap,
        uint256 _fromDecimal,
        uint256 _toDecimal
    ) internal view returns (uint256) {
        uint256 fromPrice = tokenPrice[_fromTokenId];
        uint256 toPrice = tokenPrice[_toTokenId];
        require(fromPrice > 0 && toPrice > 0, "Invalid price data");

        uint256 amountToReceive;
        if (_fromTokenId == 3) { // RTL as fromToken
            if (_toTokenId == 0) { // RTL to ETH
                amountToReceive = (_amountToSwap * fromPrice) / 10**18;
            } else { // RTL to USDT/DAI
                uint256 ethValue = (_amountToSwap * fromPrice) / 10**18; // RTL in ETH
                amountToReceive = (ethValue * ETH_PRICE_USD) / toPrice; // ETH to USD
            }
        } else if (_toTokenId == 3) { // USDT/DAI/ETH to RTL
            if (_fromTokenId == 0) { // ETH to RTL
                amountToReceive = (_amountToSwap * 10**18) / toPrice;
            } else { // USDT/DAI to RTL
                uint256 ethValue = (_amountToSwap * fromPrice) / ETH_PRICE_USD; // USD to ETH
                amountToReceive = (ethValue * 10**18) / toPrice; // ETH to RTL
            }
        } else { // ETH/USDT/DAI to ETH/USDT/DAI
            amountToReceive = (_amountToSwap * fromPrice) / toPrice;
        }

        return (amountToReceive * 10**_toDecimal) / 10**_fromDecimal;
    }

  // Swap tokens for tokens
    function swapTokensForTokens(
        uint256 _fromTokenId,
        uint256 _toTokenId,
        uint256 _amountToSwap
    ) external nonReentrant returns (bool) {
        require(_fromTokenId < tokenCount && _toTokenId < tokenCount, "Invalid token ID");
        require(_fromTokenId != 0 && _toTokenId != 0, "Use ETH swap functions for ETH");
        require(_fromTokenId != _toTokenId, "Cannot swap same token");
        require(_amountToSwap > 0, "Invalid amount");

        Token memory fromToken = tokens[_fromTokenId];
        Token memory toToken = tokens[_toTokenId];

        // Check allowance
        require(
            IERC20(fromToken.tokenAddress).allowance(msg.sender, address(this)) >= _amountToSwap,
            "Insufficient allowance"
        );

        // Check liquidity pool
        bytes32 pairId = keccak256(abi.encodePacked(_fromTokenId, _toTokenId));
        require(poolExists[pairId], "Liquidity pool does not exist");
        LiquidityPool storage pool = pools[pairId];

        // Calculate amount to receive
        uint256 amountToReceive = _calculateSwapAmount(
            _fromTokenId,
            _toTokenId,
            _amountToSwap,
            fromToken.decimal,
            toToken.decimal
        );

        // Apply slippage tolerance
        uint256 minAmountOut = (amountToReceive * SLIPPAGE_TOLERANCE) / 100;
        require(amountToReceive >= minAmountOut, "Slippage too high");

        // Check liquidity
        uint256 toTokenBalance = (_toTokenId == pool.token1Id) ? pool.token1Balance : pool.token2Balance;
        require(toTokenBalance >= amountToReceive, "Insufficient liquidity");

        // Transfer tokens
        require(
            IERC20(fromToken.tokenAddress).transferFrom(msg.sender, address(this), _amountToSwap),
            "From token transfer failed"
        );
        require(
            IERC20(toToken.tokenAddress).transfer(msg.sender, amountToReceive),
            "To token transfer failed"
        );

        // Update pool balances
        if (_fromTokenId == pool.token1Id) {
            pool.token1Balance += _amountToSwap;
            pool.token2Balance -= amountToReceive;
        } else {
            pool.token1Balance -= amountToReceive;
            pool.token2Balance += _amountToSwap;
        }

        emit SwapExecuted(msg.sender, _fromTokenId, _toTokenId, _amountToSwap, amountToReceive);
        return true;
    }

    // Swap ETH for tokens
    function swapEthForTokens(
        uint256 _tokenId
    ) external payable nonReentrant returns (bool) {
        require(_tokenId < tokenCount, "Invalid token ID");
        require(_tokenId != 0, "Cannot swap to ETH");
        require(msg.value > 0, "Invalid ETH amount");

        Token memory token = tokens[_tokenId];

        // Calculate amount to receive
        uint256 amountToReceive = _calculateSwapAmount(
            0, // ETH
            _tokenId,
            msg.value,
            18, // ETH decimals
            token.decimal
        );

        // Apply slippage tolerance
        uint256 minAmountOut = (amountToReceive * SLIPPAGE_TOLERANCE) / 100;
        require(amountToReceive >= minAmountOut, "Slippage too high");

        // Check liquidity
        require(
            IERC20(token.tokenAddress).balanceOf(address(this)) >= amountToReceive,
            "Insufficient liquidity"
        );

        // Transfer tokens
        require(
            IERC20(token.tokenAddress).transfer(msg.sender, amountToReceive),
            "Token transfer failed"
        );

        emit SwapExecuted(msg.sender, 0, _tokenId, msg.value, amountToReceive);
        return true;
    }

    // Swap tokens for ETH
    function swapTokensForEth(
        uint256 _tokenId,
        uint256 _amountToSwap
    ) external nonReentrant returns (bool) {
        require(_tokenId < tokenCount, "Invalid token ID");
        require(_tokenId != 0, "Cannot swap from ETH");
        require(_amountToSwap > 0, "Invalid token amount");

        Token memory token = tokens[_tokenId];

        // Check allowance
        require(
            IERC20(token.tokenAddress).allowance(msg.sender, address(this)) >= _amountToSwap,
            "Insufficient allowance"
        );

        // Calculate amount to receive
        uint256 amountToReceive = _calculateSwapAmount(
            _tokenId,
            0, // ETH
            _amountToSwap,
            token.decimal,
            18 // ETH decimals
        );

        // Apply slippage tolerance
        uint256 minAmountOut = (amountToReceive * SLIPPAGE_TOLERANCE) / 100;
        require(amountToReceive >= minAmountOut, "Slippage too high");

        // Check liquidity
        require(
            address(this).balance >= amountToReceive,
            "Insufficient ETH liquidity"
        );

        // Transfer tokens
        require(
            IERC20(token.tokenAddress).transferFrom(msg.sender, address(this), _amountToSwap),
            "Token transfer failed"
        );

        // Transfer ETH
        payable(msg.sender).transfer(amountToReceive);

        emit SwapExecuted(msg.sender, _tokenId, 0, _amountToSwap, amountToReceive);
        return true;
    }

    // Add liquidity to a token pair
    function addLiquidity(
        uint256 _token1Id,
        uint256 _token2Id,
        uint256 _token1Amount,
        uint256 _token2Amount
    ) external payable {
        require(_token1Id < tokenCount && _token2Id < tokenCount, "Invalid token ID");
        require(_token1Id != _token2Id, "Cannot create pool with same token");
        require(_token1Amount > 0 && _token2Amount > 0, "Invalid amount");

        bytes32 pairId = keccak256(abi.encodePacked(_token1Id, _token2Id));
        LiquidityPool storage pool = pools[pairId];

        // Transfer tokens or ETH
        if (_token1Id != 0) {
            require(
                IERC20(tokens[_token1Id].tokenAddress).transferFrom(msg.sender, address(this), _token1Amount),
                "Token1 transfer failed"
            );
        } else {
            require(msg.value == _token1Amount, "Incorrect ETH amount");
        }

        if (_token2Id != 0) {
            require(
                IERC20(tokens[_token2Id].tokenAddress).transferFrom(msg.sender, address(this), _token2Amount),
                "Token2 transfer failed"
            );
        } else {
            require(msg.value == _token2Amount, "Incorrect ETH amount");
        }

        // Initialize or update pool
        if (!poolExists[pairId]) {
            pool.token1Id = _token1Id;
            pool.token2Id = _token2Id;
            poolExists[pairId] = true;
        }
        pool.token1Balance += _token1Amount;
        pool.token2Balance += _token2Amount;

        emit LiquidityAdded(msg.sender, _token1Id, _token2Id, _token1Amount, _token2Amount);
    }

    // Remove liquidity (simplified, assumes full withdrawal)
    function removeLiquidity(uint256 _token1Id, uint256 _token2Id) external nonReentrant {
        require(_token1Id < tokenCount && _token2Id < tokenCount, "Invalid token ID");
        bytes32 pairId = keccak256(abi.encodePacked(_token1Id, _token2Id));
        require(poolExists[pairId], "Liquidity pool does not exist");

        LiquidityPool storage pool = pools[pairId];
        uint256 token1Amount = pool.token1Balance;
        uint256 token2Amount = pool.token2Balance;

        require(token1Amount > 0 && token2Amount > 0, "No liquidity to remove");

        // Transfer tokens or ETH
        if (_token1Id != 0) {
            require(
                IERC20(tokens[_token1Id].tokenAddress).transfer(msg.sender, token1Amount),
                "Token1 transfer failed"
            );
        } else {
            payable(msg.sender).transfer(token1Amount);
        }

        if (_token2Id != 0) {
            require(
                IERC20(tokens[_token2Id].tokenAddress).transfer(msg.sender, token2Amount),
                "Token2 transfer failed"
            );
        } else {
            payable(msg.sender).transfer(token2Amount);
        }

        // Reset pool
        pool.token1Balance = 0;
        pool.token2Balance = 0;

        emit LiquidityRemoved(msg.sender, _token1Id, _token2Id, token1Amount, token2Amount);
    }

    // Add new token (only owner)
   function addToken(
    address _tokenAddress,
    uint256 _decimal,
    string memory _name,
    AggregatorV3Interface _priceFeed // Add this argument to match the Token's constructor
) external onlyOwner {
    tokens[tokenCount] = Token({
        tokenpricefeed: _priceFeed,  // Use the new variable instead of hardcoding it later
        tokenAddress: _tokenAddress,
        decimal: _decimal,
        name: _name
    });
  tokenPrice[tokenCount] = getHardcodedPrice(_priceFeed); // Add this line to update prices for newly added tokens
    tokenCount++;
}

// Helper function to calculate the price of a new token (only owner)
function getHardcodedPrice(AggregatorV3Interface _pricefeed) internal pure  returns(uint256){
  return uint256(0);
}



    receive() external payable {}
}