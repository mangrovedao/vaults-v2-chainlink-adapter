// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AggregatorV2V3Interface} from "./interfaces/chainlink/AggregatorV2V3Interface.sol";
import {ChainlinkConsumer} from "./libraries/ChainlinkConsumer.sol";
import {LibString} from "lib/solady/src/utils/LibString.sol";
import {V2VaultReader} from "./libraries/V2VaultReader.sol";
import {InitialParameters} from "./libraries/InitialParameters.sol";
import {V2VaultPricing} from "./libraries/V2VaultPricing.sol";

/**
 * @title VaultsV2Feed
 * @dev Chainlink AggregatorV3-style price-feed adapter for a V2-style vault
 *
 * Exposes the price of a vault share (in USD or other base currency) by reading on-chain balances,
 * feed prices, and normalizing values to standard decimals, conforming to the Chainlink aggregator interfaces.
 *
 * Features:
 *  - Aggregates base/quote price feeds and vault balances to compute a unified share price.
 *  - Implements the AggregatorV2V3Interface, supporting Chainlink-style round/answer accessors.
 *  - All responses are for a singleton "round" (id = 1) which reflects the current on-chain state.
 *
 * Immutables are memoized for gas efficiency. All computation delegates to minimal arithmetic and
 * library helpers to safely compose vault and feed data.
 */
contract VaultsV2Feed is AggregatorV2V3Interface {
  using LibString for string;
  using ChainlinkConsumer for address;
  using V2VaultReader for address;

  /// @notice Error thrown when a requested roundId is not supported (only '1' is valid)
  error InvalidRoundId();

  /// @notice Number of decimals used in computed answers (matches standardization configuration)
  uint8 internal immutable DECIMALS;

  /// @notice Multiplier to scale base asset price feed answer to unified decimals
  uint256 internal immutable BASE_MULTIPLIER;
  /// @notice Multiplier to scale quote asset price feed answer to unified decimals
  uint256 internal immutable QUOTE_MULTIPLIER;

  /// @notice Divider to normalize base token balance to its declared decimals
  uint256 internal immutable BASE_DIVIDER;
  /// @notice Divider to normalize quote token balance to its declared decimals
  uint256 internal immutable QUOTE_DIVIDER;

  /// @notice Multiplier to normalize vault shares to their declared decimals
  uint256 internal immutable SHARES_MULTIPLIER;

  /// @notice Chainlink base asset feed address (e.g., asset/USD)
  address public immutable BASE_FEED_ADDRESS;
  /// @notice Chainlink quote asset feed address (e.g., asset/USD)
  address public immutable QUOTE_FEED_ADDRESS;

  /// @notice Address of the target Vault V2 contract
  address public immutable VAULT_V2_ADDRESS;

  /**
   * @notice Initializes the VaultsV2Feed contract, precomputing all normalization coefficients.
   * @param vaultV2Address Address of the V2 vault to source balances/metadata from
   * @param baseFeedAddress Address of the Chainlink feed for the base asset
   * @param quoteFeedAddress Address of the Chainlink feed for the quote asset
   *
   * @dev
   *  - Immutable normalization values (decimals, multipliers, dividers) are computed at construction
   *    for constant-time, gas-efficient computation in all views.
   */
  constructor(address vaultV2Address, address baseFeedAddress, address quoteFeedAddress) {
    VAULT_V2_ADDRESS = vaultV2Address;
    BASE_FEED_ADDRESS = baseFeedAddress;
    QUOTE_FEED_ADDRESS = quoteFeedAddress;

    (DECIMALS, BASE_MULTIPLIER, QUOTE_MULTIPLIER, BASE_DIVIDER, QUOTE_DIVIDER, SHARES_MULTIPLIER) =
      InitialParameters.initialParameters(VAULT_V2_ADDRESS, BASE_FEED_ADDRESS, QUOTE_FEED_ADDRESS);
  }

  /**
   * @notice Gets the decimals (precision) for this price feed
   * @return The decimal count used for the share price answers
   */
  function decimals() external view returns (uint8) {
    return DECIMALS;
  }

  /**
   * @notice Gets a descriptive string for this feed, e.g. "Feed: VaultName"
   * @return desc A human-readable identifier string
   */
  function description() external view returns (string memory desc) {
    return VAULT_V2_ADDRESS.description();
  }

  /**
   * @notice Returns the feed version (always 1; for interface compatibility)
   * @return Version constant
   */
  function version() external pure returns (uint256) {
    return 1;
  }

  /**
   * @notice Get historical round data for the AggregatorV3 interface (only roundId=1 is valid)
   * @param _roundId Must be 1 (representing the current round)
   * @return roundId Always 1
   * @return answer Latest computed vault share price (see `latestRoundData()`)
   * @return startedAt Always 0
   * @return updatedAt Timestamp of the latest feed update (oldest of base/quote feeds)
   * @return answeredInRound Always 1
   *
   * @dev Reverts if any roundId other than 1 is supplied.
   */
  function getRoundData(uint80 _roundId)
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
  {
    if (_roundId != 1) revert InvalidRoundId();
    return latestRoundData();
  }

  /**
   * @notice Gets the most recent data for the singleton round (AggregatorV3 interface)
   * @return roundId Always 1
   * @return answer The latest calculated vault share price (see V2VaultPricing.price)
   * @return startedAt Always 0 (no real "startedAt" concept)
   * @return updatedAt Timestamp of most recent update from underlying feeds
   * @return answeredInRound Always 1
   */
  function latestRoundData()
    public
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
  {
    (answer, updatedAt) = V2VaultPricing.price(
      VAULT_V2_ADDRESS,
      BASE_FEED_ADDRESS,
      QUOTE_FEED_ADDRESS,
      BASE_MULTIPLIER,
      QUOTE_MULTIPLIER,
      BASE_DIVIDER,
      QUOTE_DIVIDER,
      SHARES_MULTIPLIER
    );
    roundId = 1;
    startedAt = 0;
    answeredInRound = 1;
  }

  /**
   * @notice Returns the latest computed vault share price (AggregatorV2-style)
   * @return answer The current vault share price in unified decimals
   */
  function latestAnswer() public view returns (int256 answer) {
    (answer,) = V2VaultPricing.price(
      VAULT_V2_ADDRESS,
      BASE_FEED_ADDRESS,
      QUOTE_FEED_ADDRESS,
      BASE_MULTIPLIER,
      QUOTE_MULTIPLIER,
      BASE_DIVIDER,
      QUOTE_DIVIDER,
      SHARES_MULTIPLIER
    );
  }

  /**
   * @notice Returns the timestamp of the oldest update among the two feeds
   * @return updatedAt Timestamp (seconds) for latest price update
   */
  function latestTimestamp() public view returns (uint256 updatedAt) {
    (,, updatedAt) = V2VaultPricing.answers(BASE_FEED_ADDRESS, QUOTE_FEED_ADDRESS);
  }

  /**
   * @notice Returns the integer round ID of the latest round (always 1)
   * @return Always 1, since this feed supports only a constant singleton round
   */
  function latestRound() external pure returns (uint256) {
    return 1;
  }

  /**
   * @notice Gets the answer for a specified round (must be round 1)
   * @param roundId Round ID (must be 1)
   * @return answer The current vault share price
   * @dev Reverts if roundId != 1
   */
  function getAnswer(uint256 roundId) external view returns (int256) {
    if (roundId != 1) revert InvalidRoundId();
    return latestAnswer();
  }

  /**
   * @notice Gets the updatedAt timestamp for a specified round (must be round 1)
   * @param roundId Round ID (must be 1)
   * @return updatedAt Timestamp of last answer update
   * @dev Reverts if roundId != 1
   */
  function getTimestamp(uint256 roundId) external view returns (uint256) {
    if (roundId != 1) revert InvalidRoundId();
    return latestTimestamp();
  }
}
