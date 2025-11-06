// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
    /// @solidity memory-safe-assembly
    assembly {
      mstore(0x00, 0xfeaf968c) // latestRoundData()
      if iszero(staticcall(gas(), feed, 0x1c, 0x04, 0x00, 0x00)) {
        returndatacopy(0x00, 0x00, returndatasize())
        revert(0x00, returndatasize())
      }

      returndatacopy(0x00, 0x20, 0x20) // Copy the answer to the memory
      answer := mload(0x00)

      if iszero(sgt(answer, 0)) {
        mstore(0x00, 0x35278d12) // Overflow()
        revert(0x1c, 0x04)
      }

      returndatacopy(0x00, 0x60, 0x20) // Copy the updatedAt to the memory
      updatedAt := mload(0x00)
    }
  }

  /**
   * @notice Gets the decimals from the feed
   * @param feed The address of the feed
   * @return _decimals The decimals
   * @dev This function will revert if the decimals are too high
   */
  function decimals(address feed) internal view returns (uint8 _decimals) {
    /// @solidity memory-safe-assembly
    assembly {
      mstore(0x00, 0x313ce567) // decimals()
      if iszero(staticcall(gas(), feed, 0x1c, 0x04, 0x00, 0x20)) {
        returndatacopy(0x00, 0x00, returndatasize())
        revert(0x00, returndatasize())
      }

      _decimals := mload(0x00)

      // check for decimals overflow (max 30 decimals)
      if gt(_decimals, 30) {
        mstore(0x00, 0x35278d12) // Overflow()
        revert(0x1c, 0x04)
      }
    }
  }
}
