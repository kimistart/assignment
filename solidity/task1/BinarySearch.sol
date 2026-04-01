// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract BinarySearch {
    function binarySearch(uint[] calldata sortedArr ,uint target) pure public returns(uint index) {
        uint left = 0;
        uint right = sortedArr.length - 1;

        if(sortedArr.length == 0) {
            return type(uint).max;
        }

        while(left <= right) {
            uint mid = left + (right - left)/2;

            if(sortedArr[mid] == target) {
                return mid;
            } else if (sortedArr[mid] < target) {
                left = mid + 1;
            } else {
                right = mid -1;
            }
        }

        return type(uint).max;
    }
}