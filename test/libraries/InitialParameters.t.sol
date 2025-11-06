// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {InitialParameters} from "../../src/libraries/InitialParameters.sol";
import {MockVault} from "../../src/mocks/MockVault.sol";
import {MockToken} from "../../src/mocks/MockToken.sol";
import {MockFeed} from "../../src/mocks/MockFeed.sol";

contract InitialParametersTest is Test {
  MockVault vault;
  MockFeed baseFeed;
  MockFeed quoteFeed;

  function setUp() public {
    vault = new MockVault();
    baseFeed = new MockFeed();
    quoteFeed = new MockFeed();
  }

  function testFuzz_decimalsMultiplier(uint8 baseDecimals, uint8 quoteDecimals, uint8 vaultDecimals) public {
    baseDecimals = uint8(bound(baseDecimals, 0, 21));
    quoteDecimals = uint8(bound(quoteDecimals, 0, 21));
    vaultDecimals = uint8(bound(vaultDecimals, 0, 21));

    MockVault(vault).setDecimals(vaultDecimals, baseDecimals, quoteDecimals);

    (uint256 baseDivider, uint256 quoteDivider, uint256 sharesMultiplier) =
      InitialParameters.decimalsMultiplier(address(vault));

    (address base, address quote,) = MockVault(vault).market();

    assertEq(baseDivider, 10 ** MockToken(base).decimals());
    assertEq(quoteDivider, 10 ** MockToken(quote).decimals());

    assertEq(sharesMultiplier, 10 ** MockVault(vault).decimals());
  }

  function testFuzz_feedDecimals(uint8 baseFeedDecimals, uint8 quoteFeedDecimals) public {
    baseFeedDecimals = uint8(bound(baseFeedDecimals, 0, 21));
    quoteFeedDecimals = uint8(bound(quoteFeedDecimals, 0, 21));

    baseFeed.setData(0, 0, baseFeedDecimals);
    quoteFeed.setData(0, 0, quoteFeedDecimals);

    (uint8 decimals,,,,,) = InitialParameters.initialParameters(address(vault), address(baseFeed), address(quoteFeed));

    uint8 expectedDecimals = baseFeedDecimals > quoteFeedDecimals ? baseFeedDecimals : quoteFeedDecimals;

    assertEq(decimals, expectedDecimals);
  }

  function testFuzz_mulitpliers(uint8 baseFeedDecimals, uint8 quoteFeedDecimals) public {
    baseFeedDecimals = uint8(bound(baseFeedDecimals, 0, 21));
    quoteFeedDecimals = uint8(bound(quoteFeedDecimals, 0, 21));

    baseFeed.setData(0, 0, baseFeedDecimals);
    quoteFeed.setData(0, 0, quoteFeedDecimals);

    (uint8 decimals, uint256 baseMultiplier, uint256 quoteMultiplier,,,) =
      InitialParameters.initialParameters(address(vault), address(baseFeed), address(quoteFeed));

    uint256 expectedBaseMultiplier = 10 ** (decimals - baseFeedDecimals);
    uint256 expectedQuoteMultiplier = 10 ** (decimals - quoteFeedDecimals);

    assertEq(baseMultiplier, expectedBaseMultiplier);
    assertEq(quoteMultiplier, expectedQuoteMultiplier);
  }

  function testFuzz_dividers(
    uint8 baseDecimals,
    uint8 quoteDecimals,
    uint8 vaultDecimals,
    uint8 baseFeedDecimals,
    uint8 quoteFeedDecimals
  ) public {
    baseDecimals = uint8(bound(baseDecimals, 0, 21));
    quoteDecimals = uint8(bound(quoteDecimals, 0, 21));
    vaultDecimals = uint8(bound(vaultDecimals, 0, 21));
    baseFeedDecimals = uint8(bound(baseFeedDecimals, 0, 21));
    quoteFeedDecimals = uint8(bound(quoteFeedDecimals, 0, 21));

    baseFeed.setData(0, 0, baseFeedDecimals);
    quoteFeed.setData(0, 0, quoteFeedDecimals);
    MockVault(vault).setDecimals(vaultDecimals, baseDecimals, quoteDecimals);

    (,,, uint256 baseDivider, uint256 quoteDivider, uint256 sharesMultiplier) =
      InitialParameters.initialParameters(address(vault), address(baseFeed), address(quoteFeed));

    uint256 expectedBaseDivider = 10 ** baseDecimals;
    uint256 expectedQuoteDivider = 10 ** quoteDecimals;
    uint256 expectedSharesMultiplier = 10 ** vaultDecimals;

    assertEq(baseDivider, expectedBaseDivider);
    assertEq(quoteDivider, expectedQuoteDivider);
    assertEq(sharesMultiplier, expectedSharesMultiplier);
  }
}
