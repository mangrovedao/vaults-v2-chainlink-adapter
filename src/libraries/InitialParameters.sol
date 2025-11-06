// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {V2VaultReader} from "./V2VaultReader.sol";
import {ChainlinkConsumer} from "./ChainlinkConsumer.sol";
import {FixedPointMathLib} from "lib/solady/src/utils/FixedPointMathLib.sol";

/**
 * @title InitialParameters
 * @dev Utility library to compute standardization parameters required for vault pricing and share tracking
 */
library InitialParameters {
  using V2VaultReader for address;
  using ChainlinkConsumer for address;

  /**
   * @notice Returns all initial parameters required for pricing vault shares
   * @param vault Address of the vault
   * @param baseFeed Address of the Chainlink base asset feed
   * @param quoteFeed Address of the Chainlink quote asset feed
   * @return decimals The standardized decimals to be used
   * @return baseMultiplier The multiplier for scaling base feed answer to standardized decimals
   * @return quoteMultiplier The multiplier for scaling quote feed answer to standardized decimals
   * @return baseDivider The divider to normalize base token to its decimals
   * @return quoteDivider The divider to normalize quote token to its decimals
   * @return sharesMultiplier The multiplier for normalizing vault shares to its decimals
   *
   * @dev
   *  - `decimals` is set to the max of base/quote feed decimals to preserve precision.
   *  - Multiplier = 10 ** (decimals - feedDecimals) for each feed.
   *  - Dividers for assets/shares as powers of 10 according to token decimals.
   */
  function initialParameters(address vault, address baseFeed, address quoteFeed)
    internal
    view
    returns (
      uint8 decimals,
      uint256 baseMultiplier,
      uint256 quoteMultiplier,
      uint256 baseDivider,
      uint256 quoteDivider,
      uint256 sharesMultiplier
    )
  {
    unchecked {
      // Get number of decimals for price feeds
      uint8 baseFeedDecimals = baseFeed.decimals();
      uint8 quoteFeedDecimals = quoteFeed.decimals();

      // Use the maximum of feed decimals to avoid downscaling precision
      decimals = uint8(FixedPointMathLib.max(baseFeedDecimals, quoteFeedDecimals));

      // Up/downscale Chainlink feeds to the unified decimals
      baseMultiplier = 10 ** (decimals - baseFeedDecimals);
      quoteMultiplier = 10 ** (decimals - quoteFeedDecimals);

      // Compute token and shares denominators
      (baseDivider, quoteDivider, sharesMultiplier) = decimalsMultiplier(vault);
    }
  }

  /**
   * @notice Calculates normalization divisors for vault, base, and quote assets
   * @param vault Address of the vault contract
   * @return baseDivider 10 ** (base token decimals)
   * @return quoteDivider 10 ** (quote token decimals)
   * @return sharesMultiplier 10 ** (vault decimals)
   *
   * @dev Reads decimals from vault.market() tokens and vault directly.
   */
  function decimalsMultiplier(address vault)
    internal
    view
    returns (uint256 baseDivider, uint256 quoteDivider, uint256 sharesMultiplier)
  {
    unchecked {
      // Retrieve base and quote token addresses from the vault
      (address base, address quote) = vault.market();

      // Compute normalization coefficients by respective decimals
      baseDivider = 10 ** base.decimals();
      quoteDivider = 10 ** quote.decimals();
      sharesMultiplier = 10 ** vault.decimals();
    }
  }
}
