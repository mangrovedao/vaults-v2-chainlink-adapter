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

  struct ValueParams {
    uint256 baseBalance;
    uint256 quoteBalance;
    uint8 baseDecimals;
    uint8 quoteDecimals;
    int256 baseAnswer;
    int256 quoteAnswer;
    uint8 baseFeedDecimals;
    uint8 quoteFeedDecimals;
    uint8 vaultDecimals;
    uint256 totalSupply;
    uint256 expectedValue;
    uint256 expectedPrice;
  }

  function _setValues(ValueParams memory values) internal {
    baseFeed.setData(values.baseAnswer, 0, values.baseFeedDecimals);
    quoteFeed.setData(values.quoteAnswer, 0, values.quoteFeedDecimals);
    MockVault(vault).setDecimals(values.vaultDecimals, values.baseDecimals, values.quoteDecimals);
    MockVault(vault).setTotalBalances(values.baseBalance, values.quoteBalance);
    MockVault(vault).setTotalSupply(values.totalSupply);
  }

  function fixtureValues() public pure returns (ValueParams[] memory values) {
    values = new ValueParams[](2);
    values[0] = ValueParams({
      baseBalance: 1 ether,
      quoteBalance: 1 ether,
      baseDecimals: 18,
      quoteDecimals: 18,
      baseAnswer: 1e6,
      quoteAnswer: 1e6,
      baseFeedDecimals: 6,
      quoteFeedDecimals: 6,
      vaultDecimals: 18,
      totalSupply: 2 ether,
      expectedValue: 2e6,
      expectedPrice: 1e6
    });

    values[1] = ValueParams({
      baseBalance: 3.5 ether,
      quoteBalance: 2600e6,
      baseDecimals: 18,
      quoteDecimals: 6,
      baseAnswer: 3500e8,
      quoteAnswer: 1e6,
      baseFeedDecimals: 8,
      quoteFeedDecimals: 6,
      vaultDecimals: 18,
      totalSupply: 5 ether,
      expectedValue: 14850e8,
      expectedPrice: 2970e8
    });
  }

  function tableValuesTest(ValueParams memory values) public {
    _setValues(values);

    (, uint256 baseMultiplier, uint256 quoteMultiplier, uint256 baseDivider, uint256 quoteDivider,) =
      InitialParameters.initialParameters(address(vault), address(baseFeed), address(quoteFeed));

    uint256 value = V2VaultPricing.value(
      address(vault), values.baseAnswer, values.quoteAnswer, baseMultiplier, quoteMultiplier, baseDivider, quoteDivider
    );

    assertEq(value, values.expectedValue);
  }

  function tablePriceTest(ValueParams memory values) public {
    _setValues(values);

    (
      ,
      uint256 baseMultiplier,
      uint256 quoteMultiplier,
      uint256 baseDivider,
      uint256 quoteDivider,
      uint256 sharesMultiplier
    ) = InitialParameters.initialParameters(address(vault), address(baseFeed), address(quoteFeed));

    (int256 price,) = V2VaultPricing.price(
      address(vault),
      address(baseFeed),
      address(quoteFeed),
      baseMultiplier,
      quoteMultiplier,
      baseDivider,
      quoteDivider,
      sharesMultiplier
    );
    assertEq(uint256(price), values.expectedPrice);
  }

  function testFuzz_pricing(ValueParams memory values) public {
    values.baseDecimals = uint8(bound(values.baseDecimals, 0, 21));
    values.quoteDecimals = uint8(bound(values.quoteDecimals, 0, 21));
    values.vaultDecimals = uint8(bound(values.vaultDecimals, 0, 21));

    values.baseBalance = uint256(bound(values.baseBalance, 0, 100e9 * 10 ** values.baseDecimals));
    values.quoteBalance = uint256(bound(values.quoteBalance, 0, 100e9 * 10 ** values.quoteDecimals));
    values.totalSupply = uint256(bound(values.totalSupply, 0, 100e9 * 10 ** values.vaultDecimals));

    values.baseFeedDecimals = uint8(bound(values.baseFeedDecimals, 0, 21));
    values.quoteFeedDecimals = uint8(bound(values.quoteFeedDecimals, 0, 21));

    values.baseAnswer = int256(bound(uint256(values.baseAnswer), 1, 1e6 * 10 ** values.baseFeedDecimals));
    values.quoteAnswer = int256(bound(uint256(values.quoteAnswer), 1, 1e6 * 10 ** values.quoteFeedDecimals));

    _setValues(values);

    (
      ,
      uint256 baseMultiplier,
      uint256 quoteMultiplier,
      uint256 baseDivider,
      uint256 quoteDivider,
      uint256 sharesMultiplier
    ) = InitialParameters.initialParameters(address(vault), address(baseFeed), address(quoteFeed));

    uint256 value = V2VaultPricing.value(
      address(vault), values.baseAnswer, values.quoteAnswer, baseMultiplier, quoteMultiplier, baseDivider, quoteDivider
    );

    (int256 price,) = V2VaultPricing.price(
      address(vault),
      address(baseFeed),
      address(quoteFeed),
      baseMultiplier,
      quoteMultiplier,
      baseDivider,
      quoteDivider,
      sharesMultiplier
    );

    uint256 baseValue = values.baseBalance * uint256(values.baseAnswer) * baseMultiplier / baseDivider;
    uint256 quoteValue = values.quoteBalance * uint256(values.quoteAnswer) * quoteMultiplier / quoteDivider;
    values.expectedValue = baseValue + quoteValue;
    values.expectedPrice = values.totalSupply == 0
      ? uint256(values.quoteAnswer) * quoteMultiplier
      : values.expectedValue * sharesMultiplier / values.totalSupply;

    assertEq(value, values.expectedValue);
    assertEq(uint256(price), values.expectedPrice);
  }
}
