// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract RomanToInt{
    function change(string calldata romanStr) public pure returns (uint result) { 
        bytes memory romanBytes = bytes(romanStr);
        uint length = romanBytes.length;

        for(uint i=0;i<length;i++) {
            uint firstByte = getRomanValue(romanBytes[i]);
            uint256 secondByte = (i + 1 < length) ? getRomanValue(romanBytes[i + 1]) : 0;

            if(firstByte < secondByte) {
                result = result + (secondByte - firstByte);
                i++;
            } else {
                result = result + firstByte;
            }
        }
    }

    function getRomanValue(bytes1 roman) pure internal returns (uint result) {
        if(roman == 'I') return 1;
        else if(roman == 'V') return 5;
        else if(roman == 'X') return 10;
        else if(roman == 'L') return 50;
        else if(roman == 'C') return 100;
        else if(roman == 'D') return 500;
        else if(roman == 'M') return 1000;
    }
}