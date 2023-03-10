// SPDX-License-Identifier: GPL-v3.0

pragma solidity ^0.8.15;

import './Feedbase.sol';

contract Medianizer {
    address   public owner;
    uint256   public quorum;
    address[] public sources;
    Feedbase  public feedbase;

    constructor(address fb) {
        owner = msg.sender;
        feedbase = Feedbase(fb);
    }

    function setOwner(address newOwner) public {
        require(msg.sender == owner, 'ERR_OWNER');
        owner = newOwner;
    }

    function setSources(address[] calldata newSources) public {
        require(msg.sender == owner, 'ERR_OWNER');
        sources = newSources;
    }

    function setQuorum(uint newQuorum) public {
        require(msg.sender == owner, 'ERR_OWNER');
        quorum = newQuorum;
    }

    function poke(bytes32 tag) public {
        bytes32[] memory data = new bytes32[](sources.length);
        uint256 minttl = type(uint256).max;
        uint256 count = 0;

        for(uint256 i = 0; i < sources.length; i++) {
            (bytes32 val, uint256 _ttl) = feedbase.pull(sources[i], tag);
            if (block.timestamp > _ttl) {
                continue;
            }
            if (count == 0 || val >= data[count - 1]) {
                data[count] = val;
            } else {
                uint256 j = 0;
                while (val >= data[j]) {
                    j++;
                }
                for(uint256 k = count; k > j; k--) {
                    data[k] = data[k - 1];
                }
                data[j] = val;
            }
            count++;
        }
        require(count > 0, 'ERR_COUNT');

        bytes32 median;
        if (count % 2 == 0) {
            uint256 val1 = uint256(data[(count / 2) - 1]);
            uint256 val2 = uint256(data[count / 2]);
            median = bytes32((val1 + val2) / 2);
        } else {
            median = data[(count - 1) / 2];
        }

        feedbase.push(tag, median, minttl);
    }
}
