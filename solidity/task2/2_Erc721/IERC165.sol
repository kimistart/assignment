// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IERC165 {

    // 合约是实现了interfaceId的接口，返回true
    function supportsInterface(bytes4 interfaceId) external view returns (bool) ;

}