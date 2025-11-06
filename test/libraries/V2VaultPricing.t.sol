// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {V2VaultPricing} from "../../src/libraries/V2VaultPricing.sol";
import {MockVault} from "../../src/mocks/MockVault.sol";
import {MockFeed} from "../../src/mocks/MockFeed.sol";
import {InitialParameters} from "../../src/libraries/InitialParameters.sol";

contract V2VaultPricingTest is Test {
  MockVault vault;
  MockFeed baseFeed;
  MockFeed quoteFeed;

  function setUp() public {
    vault = new MockVault();
    baseFeed = new MockFeed();
    quoteFeed = new MockFeed();
  }

  function testFuzz_answers(int256 baseAnswer, int256 quoteAnswer, uint256 baseUpdatedAt, uint256 quoteUpdatedAt)
    public
  {
    vm.assume(baseAnswer > 0);
    vm.assume(quoteAnswer > 0);
    baseFeed.setData(baseAnswer, baseUpdatedAt, 18);
    quoteFeed.setData(quoteAnswer, quoteUpdatedAt, 18);

    (int256 baseAnswer_, int256 quoteAnswer_, uint256 updatedAt_) =
      V2VaultPricing.answers(address(baseFeed), address(quoteFeed));

    assertEq(baseAnswer_, baseAnswer);
    assertEq(quoteAnswer_, quoteAnswer);
    assertEq(updatedAt_, baseUpdatedAt < quoteUpdatedAt ? baseUpdatedAt : quoteUpdatedAt);
  }

  function testValue() public {}
}
