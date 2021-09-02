// SPDX-License-Identifier: GPL-v3.0

import '../Feedbase.sol';

import './SelectorProvider.sol';

pragma solidity ^0.8.6;

contract ThresholdCombinator {
  SelectorProvider public gov;
  Feedbase public fb;

  function poke(bytes32 tag, IERC20 cash) public {
    (uint256 quorum, address[] memory sources) = gov.getSelectors();
    uint balance = fb.requested(cash, address(this), tag);
    for( uint i = 0; i < sources.length; i++) {
      fb.request(cash, sources[i], tag, balance / sources.length);
    }
  }

  function push(bytes32 tag, bytes32 hint) public {
    (uint256 quorum, address[] memory sources) = gov.getSelectors();
    require(quorum > sources.length / 2, 'ERR_QUORUM');

    uint256 count;
    uint256 minttl = type(uint256).max;
    for( uint i = 0; i < sources.length; i++ ) {
      (uint256 ttl, bytes32 val) = fb.read(sources[i], tag);
      if (ttl < block.timestamp) {
        continue;
      }
      if (ttl < minttl) {
        minttl = ttl;
      }
      if (val == hint) {
        count++;
        if (count >= quorum) {
          fb.pushFree(tag, minttl, val);
          return;
        }
      }
    }
    require(false, 'ERR_QUORUM');
  }

  function topUp(IERC20 cash, uint amt) public {
    cash.transferFrom(msg.sender, address(this), amt);
    cash.approve(address(fb), amt);
    fb.deposit(cash, amt);
  }
}