// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Script } from "forge-std/Script.sol";
import { ERC20 } from "../src/ERC20.sol";

contract DeployERC20 is Script {
    function run() external returns (ERC20 token){
        vm.startBroadcast();
        token = new ERC20("Kyber Network Crystal", "KNC");
        vm.stopBroadcast();
        
        return token;
    }
}