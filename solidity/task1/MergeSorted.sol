// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract MergeSorted {
    function MergeSortedArray(uint[] calldata arr1 ,uint[] calldata arr2) pure public returns(uint[] memory mergedArr) {
        uint len1 = arr1.length;
        uint len2 = arr2.length;

        mergedArr = new uint[](len1+len2);

        uint i = 0;
        uint j = 0;
        uint k = 0;

        while (i<len1 && j<len2) {
            if(arr1[i]<arr2[j]) {
                mergedArr[k] = arr1[i];
                i++;
            }else {
                mergedArr[k] = arr2[j];
                j++;
            }
            k++;
        }

        while(i<len1) {
            mergedArr[k] = arr1[i];
            i++;
            k++;
        }

        while(j<len2) {
            mergedArr[k] = arr2[j];
            j++;
            k++;
        }
    }
}