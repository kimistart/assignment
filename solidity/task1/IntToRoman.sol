// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract IntToRoman{
    function change(uint integer) public pure returns (string memory romanStr) { 
        uint256[] memory values = new uint256[](13);
        values[0] = 1000;
        values[1] = 900;
        values[2] = 500;
        values[3] = 400;
        values[4] = 100;
        values[5] = 90;
        values[6] = 50;
        values[7] = 40;
        values[8] = 10;
        values[9] = 9;
        values[10] = 5;
        values[11] = 4;
        values[12] = 1;

        string[] memory symbols = new string[](13);
        symbols[0] = "M";
        symbols[1] = "CM";
        symbols[2] = "D";
        symbols[3] = "CD";
        symbols[4] = "C";
        symbols[5] = "XC";
        symbols[6] = "L";
        symbols[7] = "XL";
        symbols[8] = "X";
        symbols[9] = "IX";
        symbols[10] = "V";
        symbols[11] = "IV";
        symbols[12] = "I";

        bytes memory result = new bytes(0);

        for(uint i=0;i<13;i++) {
            while (integer >= values[i]) {
                result = concatBytes(result, bytes(symbols[i]));
                integer -= values[i];
            }

            if(integer == 0) {
                break;
            }
        }

        romanStr = string(result);
    }

    function concatBytes(bytes memory a, bytes memory b) pure internal returns (bytes memory result) {
        result = new bytes(a.length + b.length);
        uint index = 0;

        for(uint i=0;i<a.length;i++) {
            result[index] = a[i];
            index++;
        }

        for(uint i=0;i<b.length;i++) {
            result[index] = b[i];
            index++;
        }
    }
}