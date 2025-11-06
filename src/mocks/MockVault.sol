// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IMangroveVaultV2} from "../interfaces/IMangroveVaultV2.sol";
import {MockToken} from "./MockToken.sol";

contract MockVault is IMangroveVaultV2 {
  string internal _name;

  uint256 internal _baseBalance;
  uint256 internal _quoteBalance;
  address internal _base;
  address internal _quote;
  uint8 internal _decimals;

  constructor() {
    _base = address(new MockToken(18));
    _quote = address(new MockToken(18));
    _decimals = 18;
  }

  function totalBalances() external view returns (uint256 baseBalance, uint256 quoteBalance) {
    return (_baseBalance, _quoteBalance);
  }

  function name() external view returns (string memory) {
    return _name;
  }

  function market() external view returns (address base, address quote, uint256 tickSpacing) {
    return (_base, _quote, 1);
  }

  function setTotalBalances(uint256 baseBalance_, uint256 quoteBalance_) external {
    _baseBalance = baseBalance_;
    _quoteBalance = quoteBalance_;
  }

  function setDecimals(uint8 vaultDecimals_, uint8 baseDecimals_, uint8 quoteDecimals_) external {
    MockToken(_base).setDecimals(baseDecimals_);
    MockToken(_quote).setDecimals(quoteDecimals_);
    _decimals = vaultDecimals_;
  }

  function setName(string memory name_) external {
    _name = name_;
  }

  function decimals() external view returns (uint8) {
    return _decimals;
  }
}
