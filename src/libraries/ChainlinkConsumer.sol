// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AggregatorV2V3Interface} from "../interfaces/chainlink/AggregatorV2V3Interface.sol";

library ChainlinkConsumer {
  /**
   * @notice The error thrown when the answer is negative or 0, or the decimals are too high
   * @dev bytes4(keccak256("Overflow()")) = 0x35278d12
   */
  error Overflow();

  /**
   * @notice Gets the latest round data from the feed
   * @param feed The address of the feed
   * @return answer The answer
   * @return updatedAt The timestamp of the latest round
   * @dev This function will revert if the answer is negative or 0
   */
  function latestRoundData(address feed) internal view returns (int256 answer, uint256 updatedAt) {
    (, answer,, updatedAt,) = AggregatorV2V3Interface(feed).latestRoundData();
    if (answer <= 0) revert Overflow();
  }

  /**
   * @notice Gets the decimals from the feed
   * @param feed The address of the feed
   * @return _decimals The decimals
   * @dev This function will revert if the decimals are too high
   */
  function decimals(address feed) internal view returns (uint8 _decimals) {
    _decimals = AggregatorV2V3Interface(feed).decimals();
    if (_decimals > 30) revert Overflow();
  }
}
