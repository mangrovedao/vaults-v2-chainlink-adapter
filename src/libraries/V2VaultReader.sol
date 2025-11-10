// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibString} from "lib/solady/src/utils/LibString.sol";
import {IMangroveVaultV2} from "../interfaces/IMangroveVaultV2.sol";

/**
 * @title V2VaultReader
 * @dev Utility library for reading key data from a V2-style vault contract
 *
 * Methods:
 *  - totalBalances: Reads the vault's current balances for both base and quote assets.
 *  - description: Extracts the user-facing name/description of the vault, prepending a label.
 *  - market: Retrieves the addresses of base and quote assets of the vault.
 */
library V2VaultReader {
  using LibString for string;

  /**
   * @notice Reads the current vault balances for the base and quote assets.
   * @param vault Address of the vault contract.
   * @return baseBalance The vault's current balance of the base asset.
   * @return quoteBalance The vault's current balance of the quote asset.
   *
   * @dev Assumes the vault implements totalBalances() -> (uint256 baseBalance, uint256 quoteBalance).
   *      Uses direct call (no try/catch), and reverts on failure.
   */
  function totalBalances(address vault) internal view returns (uint256 baseBalance, uint256 quoteBalance) {
    (baseBalance, quoteBalance) = IMangroveVaultV2(vault).totalBalances();
  }

  /**
   * @notice Gets a descriptive string for the vault, prefixed for display.
   * @param vault The vault address.
   * @return desc A string of the form "Feed: <vault name>".
   *
   * @dev Calls name() on the vault to extract the contract's descriptive name.
   *      Returns it with "Feed: " prepended for display or feed labeling.
   *      May revert if vault does not implement the expected name() function.
   */
  function description(address vault) internal view returns (string memory desc) {
    desc = string("Feed: ").concat(IMangroveVaultV2(vault).name());
  }

  /**
   * @notice Gets the vault's base and quote asset addresses.
   * @param vault Address of the vault contract.
   * @return base The address of the base asset/token.
   * @return quote The address of the quote asset/token.
   *
   * @dev Calls market() on the vault, which must return (address base, address quote).
   *      Useful for retrieving asset addresses when composing on top of vaults.
   */
  function market(address vault) internal view returns (address base, address quote) {
    (base, quote,) = IMangroveVaultV2(vault).market();
  }
}
