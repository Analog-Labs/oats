pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {Token} from "../src/Token.V1.sol";

contract DeployScript is Script {
    Token public token;

    function setUp() public {}

    function run() public {
        address deployer = vm.envAddress("DEPLOYER");
        string memory name = vm.envString("TOKEN_NAME");
        string memory symbol = vm.envString("TOKEN_SYMBOL");
        uint256 cap = vm.envUint("TOKEN_CAP");
        address gateway = vm.envAddress("GATEWAY");

        vm.startBroadcast(deployer);

        token = new Token(name, symbol, deployer, cap, gateway);

        vm.stopBroadcast();
    }
}
