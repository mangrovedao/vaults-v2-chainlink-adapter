// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMangroveVaultV2 {
  /**
   * @notice Returns the total token balances across both vault and Kandel strategy
   * @return baseBalance The total amount of base tokens (vault + Kandel)
   * @return quoteBalance The total amount of quote tokens (vault + Kandel)
   * @dev This represents the total underlying assets controlled by this management contract
   */
  function totalBalances() external view returns (uint256 baseBalance, uint256 quoteBalance);

  /**
   * @notice Returns the name of the vault token
   * @return The name string of the ERC20 token
   */
  function name() external view returns (string memory);

  /**
   * @notice Returns the market configuration for this Kandel management contract
   * @return base The base token address
   * @return quote The quote token address
   * @return tickSpacing The tick spacing for the market
   * @dev This information defines the trading pair and market parameters
   */
  function market() external view returns (address base, address quote, uint256 tickSpacing);

  /**
   * @notice Returns the decimals of the vault
   * @return The decimals of the vault
   */
  function decimals() external view returns (uint8);
}
