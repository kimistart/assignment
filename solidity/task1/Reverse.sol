// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Reverse {
    function reverse(string calldata str) external pure returns (string memory result) {
        bytes memory strBytes = bytes(str);

        uint length = strBytes.length;

        bytes memory resultBytes = new bytes(length);

        for (uint i = 0;i<length;i++) {
            resultBytes[length -1 -i] = strBytes[i];
        }

        result = string(resultBytes);
    }
}