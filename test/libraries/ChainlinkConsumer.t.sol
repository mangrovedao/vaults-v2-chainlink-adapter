// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {ChainlinkConsumer} from "../../src/libraries/ChainlinkConsumer.sol";
import {MockFeed} from "../../src/mocks/MockFeed.sol";

contract ChainlinkConsumerSubject {
  using ChainlinkConsumer for address;

  function latestRoundData(address feed) public view returns (int256 answer, uint256 updatedAt) {
    return feed.latestRoundData();
  }

  function decimals(address feed) public view returns (uint8) {
    return feed.decimals();
  }
}

contract ChainlinkConsumerTest is Test {
  MockFeed mock;
  ChainlinkConsumerSubject subject;

  function setUp() public {
    mock = new MockFeed();
    subject = new ChainlinkConsumerSubject();
  }

  function testFuzzDecimals(uint256 decimals) public {
    mock.setData(0, 0, decimals);
    if (decimals > 30) {
      vm.expectRevert(ChainlinkConsumer.Overflow.selector);
      subject.decimals(address(mock));
    } else {
      assertEq(subject.decimals(address(mock)), decimals);
    }
  }

  function testFuzzLatestRoundData(int256 answer, uint256 updatedAt) public {
    mock.setData(answer, updatedAt, 18);
    if (answer <= 0) {
      vm.expectRevert(ChainlinkConsumer.Overflow.selector);
      subject.latestRoundData(address(mock));
    } else {
      (int256 answer_, uint256 updatedAt_) = subject.latestRoundData(address(mock));
      assertEq(answer_, answer);
      assertEq(updatedAt_, updatedAt);
    }
  }
}
