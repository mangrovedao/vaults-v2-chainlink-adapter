// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ChainlinkConsumer} from "./ChainlinkConsumer.sol";
import {V2VaultReader} from "./V2VaultReader.sol";
import {FixedPointMathLib} from "lib/solady/src/utils/FixedPointMathLib.sol";
import {SafeTransferLib} from "lib/solady/src/utils/SafeTransferLib.sol";

/**
 * @title V2VaultPricing
 * @dev Library for vault pricing calculations using on-chain market and feed data
 *
 * Provides utilities to compute price and total value of vault shares for a V2-style vault, using Chainlink feeds and vault balances.
 *
 * Key methods:
 *  - answers: Returns the latest answers (prices) and most recent update time from given feeds.
 *  - value: Calculates the USD-denominated value of all assets in a vault, standardizing decimals.
 *  - price: Computes the price per single share of the vault in standardized decimals.
 */
library V2VaultPricing {
  using ChainlinkConsumer for address;
  using V2VaultReader for address;
  using V2VaultPricing for address;
  using SafeTransferLib for address;
  using FixedPointMathLib for uint256;

  /**
   * @notice Retrieves latest price answers and update timestamp for the base and quote feeds
   * @param baseFeed Address of the Chainlink base asset price feed
   * @param quoteFeed Address of the Chainlink quote asset price feed
   * @return baseAnswer Latest answer reported by the base feed
   * @return quoteAnswer Latest answer reported by the quote feed
   * @return updatedAt The minimum (oldest) updatedAt among the two feeds, indicating message freshness
   */
  function answers(address baseFeed, address quoteFeed)
    internal
    view
    returns (int256 baseAnswer, int256 quoteAnswer, uint256 updatedAt)
  {
    uint256 baseUpdatedAt;
    uint256 quoteUpdatedAt;
    (baseAnswer, baseUpdatedAt) = baseFeed.latestRoundData();
    (quoteAnswer, quoteUpdatedAt) = quoteFeed.latestRoundData();
    updatedAt = FixedPointMathLib.min(baseUpdatedAt, quoteUpdatedAt);
  }

  /**
   * @notice Computes the total USD value of all assets held by the vault
   * @param vault The V2 vault address
   * @param baseAnswer The price from the base asset feed (as int256, always positive)
   * @param quoteAnswer The price from the quote asset feed (as int256, always positive)
   * @param baseMultiplier Multiplier to adjust base price answer to standard decimals
   * @param quoteMultiplier Multiplier to adjust quote price answer to standard decimals
   * @param baseDivider The divider to normalize base asset to its own decimals
   * @param quoteDivider The divider to normalize quote asset to its own decimals
   * @return _value The total USD value of the vault (standardized to unified decimals)
   *
   * @dev
   *  - Reads asset balances from the vault.
   *  - Standardizes all arithmetic to fixed unified decimals for price computations.
   */
  function value(
    address vault,
    int256 baseAnswer,
    int256 quoteAnswer,
    uint256 baseMultiplier,
    uint256 quoteMultiplier,
    uint256 baseDivider,
    uint256 quoteDivider
  ) internal view returns (uint256 _value) {
    unchecked {
      // Retrieve the vault balances for the two tokens
      (uint256 baseBalance, uint256 quoteBalance) = vault.totalBalances();

      // Safe cast to uint256 is guaranteed: price feeds should only return strictly-positive values
      // forge-lint: disable-next-item(unsafe-typecast)
      _value = (baseBalance.fullMulDiv(uint256(baseAnswer) * baseMultiplier, baseDivider))
        + (quoteBalance.fullMulDiv(uint256(quoteAnswer) * quoteMultiplier, quoteDivider));
    }
  }

  /**
   * @notice Computes the price per vault share, in standardized decimals
   * @param vault The V2 vault address
   * @param baseFeed The Chainlink feed for the base asset
   * @param quoteFeed The Chainlink feed for the quote asset
   * @param baseMultiplier The multiplier to correct base price decimals
   * @param quoteMultiplier The multiplier to correct quote price decimals
   * @param baseDivider Divider for base asset normalization
   * @param quoteDivider Divider for quote asset normalization
   * @param sharesMultiplier Multiplier for vault shares normalization
   * @return _price The computed vault share price standardized to unified decimals (signed)
   * @return updatedAt The minimum updatedAt between both feeds (reflecting price freshness)
   *
   * @dev
   *  - Computes total USD value of vault and divides by total shares, standardizing all values.
   *  - Returns price as int256 (intended to match Chainlink interfaces).
   */
  function price(
    address vault,
    address baseFeed,
    address quoteFeed,
    uint256 baseMultiplier,
    uint256 quoteMultiplier,
    uint256 baseDivider,
    uint256 quoteDivider,
    uint256 sharesMultiplier
  ) internal view returns (int256 _price, uint256 updatedAt) {
    unchecked {
      uint256 totalSupply = vault.totalSupply();

      int256 baseAnswer;
      int256 quoteAnswer;
      (baseAnswer, quoteAnswer, updatedAt) = answers(baseFeed, quoteFeed);

      if (totalSupply == 0) {
        // casting to 'int256' is safe because quoteMultiplier is a small value
        // forge-lint: disable-next-line(unsafe-typecast)
        return (quoteAnswer * int256(quoteMultiplier), 0);
      }

      uint256 _value = value(vault, baseAnswer, quoteAnswer, baseMultiplier, quoteMultiplier, baseDivider, quoteDivider);

      _price = int256(_value.mulDiv(sharesMultiplier, totalSupply));
    }
  }
}
