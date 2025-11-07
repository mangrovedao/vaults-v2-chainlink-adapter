// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockFeed {
  int256 internal _answer;
  uint256 internal _updatedAt;
  uint256 internal _decimals;

  bool internal _shouldRevert;

  error FeedCallRevert();

  function latestRoundData()
    public
    view
    returns (uint256 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint256 answeredInRound)
  {
    _revertIfNeeded();
    roundId = 1;
    startedAt = 0;
    answeredInRound = 1;
    answer = _answer;
    updatedAt = _updatedAt;
  }

  function _revertIfNeeded() internal view {
    if (_shouldRevert) {
      revert FeedCallRevert();
    }
  }

  function decimals() public view returns (uint256) {
    _revertIfNeeded();
    return _decimals;
  }

  function setData(int256 answer, uint256 updatedAt, uint256 decimals_) public {
    _answer = answer;
    _updatedAt = updatedAt;
    _decimals = decimals_;
  }

  function setShouldRevert(bool shouldRevert) public {
    _shouldRevert = shouldRevert;
  }
}
