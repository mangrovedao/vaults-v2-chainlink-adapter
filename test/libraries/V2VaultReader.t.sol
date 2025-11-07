// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {V2VaultReader} from "../../src/libraries/V2VaultReader.sol";
import {MockVault} from "../../src/mocks/MockVault.sol";

contract V2VaultReaderSubject {
  using V2VaultReader for address;

  function totalBalances(address vault) public view returns (uint256 baseBalance, uint256 quoteBalance) {
    return vault.totalBalances();
  }

  function description(address vault) public view returns (string memory desc) {
    return vault.description();
  }

  function market(address vault) public view returns (address base, address quote) {
    return vault.market();
  }
}

contract V2VaultReaderTest is Test {
  MockVault vault;
  V2VaultReaderSubject subject;

  function setUp() public {
    vault = new MockVault();
    subject = new V2VaultReaderSubject();
  }

  function test_totalBalancesReturns0WhenEmpty() public {
    vm.expectRevert();
    subject.totalBalances(address(0xdeadbeef));
  }

  function testFuzzTotalBalances(uint256 baseBalance, uint256 quoteBalance) public {
    vault.setTotalBalances(baseBalance, quoteBalance);
    (uint256 baseBalance_, uint256 quoteBalance_) = subject.totalBalances(address(vault));
    assertEq(baseBalance_, baseBalance);
    assertEq(quoteBalance_, quoteBalance);
  }

  function testFuzzDescription(string memory name) public {
    vault.setName(name);
    assertEq(subject.description(address(vault)), string.concat("Feed: ", name));
  }

  function test_markets() public view {
    (address base, address quote) = subject.market(address(vault));
    (address base_, address quote_,) = vault.market();
    assertEq(base, base_);
    assertEq(quote, quote_);
  }

  function test_marketsReturns0WhenEmpty() public {
    vm.expectRevert();
    (address base, address quote) = subject.market(address(0xdeadbeef));
  }

  function test_bubblesUpRevert() public {
    vault.setShouldRevert(true);
    vm.expectRevert(MockVault.VaultCallRevert.selector);
    subject.totalBalances(address(vault));
    vm.expectRevert(MockVault.VaultCallRevert.selector);
    subject.description(address(vault));
    vm.expectRevert(MockVault.VaultCallRevert.selector);
    subject.market(address(vault));
  }

  function test_returnsInvalidReturnZEROData() public {
    vault.setInvalidReturnData(true);

    vault.setName("name");
    vault.setTotalBalances(100, 200);

    vm.expectRevert();
    subject.totalBalances(address(vault));
    vm.expectRevert();
    subject.description(address(vault));
    vm.expectRevert();
    subject.market(address(vault));
  }
}
