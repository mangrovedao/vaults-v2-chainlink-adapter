// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {VaultsV2Feed} from "../src/VaultsV2Feed.sol";
import {MockVault} from "../src/mocks/MockVault.sol";
import {MockFeed} from "../src/mocks/MockFeed.sol";

contract VaultsV2FeedTest is Test {
  function test_parameters() public {
    uint256 time = 100;
    MockVault vault = new MockVault();
    vault.setName("vault");
    MockFeed baseFeed = new MockFeed();
    MockFeed quoteFeed = new MockFeed();
    baseFeed.setData(1e6, time, 6);
    quoteFeed.setData(1e6, time, 6);
    vault.setTotalSupply(2 ether);
    vault.setTotalBalances(1 ether, 1 ether);

    VaultsV2Feed feed = new VaultsV2Feed(address(vault), address(baseFeed), address(quoteFeed));
    assertEq(feed.VAULT_V2_ADDRESS(), address(vault));
    assertEq(feed.BASE_FEED_ADDRESS(), address(baseFeed));
    assertEq(feed.QUOTE_FEED_ADDRESS(), address(quoteFeed));
    assertEq(feed.decimals(), 6);
    assertEq(feed.description(), "Feed: vault");
    assertEq(feed.version(), 1);

    (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
      feed.latestRoundData();
    assertEq(roundId, 1);
    assertEq(answer, 1e6);
    assertEq(startedAt, 0);
    assertEq(updatedAt, time);
    assertEq(answeredInRound, 1);

    assertEq(feed.latestAnswer(), 1e6);
    assertEq(feed.latestTimestamp(), time);
    assertEq(feed.latestRound(), 1);

    (roundId, answer, startedAt, updatedAt, answeredInRound) = feed.getRoundData(1);
    assertEq(roundId, 1);
    assertEq(answer, 1e6);
    assertEq(startedAt, 0);
    assertEq(updatedAt, time);
    assertEq(answeredInRound, 1);

    assertEq(feed.getAnswer(1), 1e6);
    assertEq(feed.getTimestamp(1), time);
  }

  function testFuzz_revertsOnRoundIdNot1(uint80 roundId) public {
    uint256 time = 100;
    MockVault vault = new MockVault();
    vault.setName("vault");
    MockFeed baseFeed = new MockFeed();
    MockFeed quoteFeed = new MockFeed();
    baseFeed.setData(1e6, time, 6);
    quoteFeed.setData(1e6, time, 6);
    vault.setTotalSupply(2 ether);
    vault.setTotalBalances(1 ether, 1 ether);
    VaultsV2Feed feed = new VaultsV2Feed(address(vault), address(baseFeed), address(quoteFeed));

    vm.assume(roundId != 1);
    vm.expectRevert(VaultsV2Feed.InvalidRoundId.selector);
    feed.getAnswer(roundId);
    vm.expectRevert(VaultsV2Feed.InvalidRoundId.selector);
    feed.getTimestamp(roundId);
    vm.expectRevert(VaultsV2Feed.InvalidRoundId.selector);
    feed.getRoundData(uint80(roundId));
  }
}
