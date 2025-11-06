// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {V2VaultReader} from "../../src/libraries/V2VaultReader.sol";
import {MockVault} from "../../src/mocks/MockVault.sol";

contract V2VaultReaderTest is Test {
  MockVault vault;

  function setUp() public {
    vault = new MockVault();
  }

  function test_totalBalancesReturns0WhenEmpty() public view {
    (uint256 baseBalance, uint256 quoteBalance) = V2VaultReader.totalBalances(address(0xdeadbeef));
    assertEq(baseBalance, 0);
    assertEq(quoteBalance, 0);
  }

  function testFuzzTotalBalances(uint256 baseBalance, uint256 quoteBalance) public {
    vault.setTotalBalances(baseBalance, quoteBalance);
    (uint256 baseBalance_, uint256 quoteBalance_) = V2VaultReader.totalBalances(address(vault));
    assertEq(baseBalance_, baseBalance);
    assertEq(quoteBalance_, quoteBalance);
  }

  function testFuzzDescription(string memory name) public {
    vault.setName(name);
    assertEq(V2VaultReader.description(address(vault)), string.concat("Feed: ", name));
  }

  function test_markets() public view {
    (address base, address quote) = V2VaultReader.market(address(vault));
    (address base_, address quote_,) = vault.market();
    assertEq(base, base_);
    assertEq(quote, quote_);
  }

  function test_marketsReturns0WhenEmpty() public view {
    (address base, address quote) = V2VaultReader.market(address(0xdeadbeef));
    assertEq(base, address(0));
    assertEq(quote, address(0));
  }
}
