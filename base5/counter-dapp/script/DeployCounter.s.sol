// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";

contract DeployCounterScript is Script {

    function setUp() public {}

    function run() public returns (address) {

        // 如果要部署到本地链，可以使用以下方式获取地址
        // address deployer = vm.envAddress("DEPLOYER_ADDRESS");

        console.log("Deploying Counter token...");

        vm.startBroadcast();

        // 部署合约
        Counter cc = new Counter();

        vm.stopBroadcast();

        console.log("Counter deployed at:", address(cc));

        return address(cc);
    }
}