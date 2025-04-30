pragma solidity ^0.8.0;

import {Token} from "../src/Token.sol";
import {IGateway} from "@analog-gmp/interfaces/IGateway.sol";
import {Test, console} from "forge-std/Test.sol";

contract TokenTest is Test {
    Token public token;
    // Anvil 1st dev account
    address constant OWNER = 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496;
    address constant GATEWAY = address(0x01);
    uint256 constant CAP = 1_000_000;
    uint16 constant NETWORK_A = 1;
    uint16 constant NETWORK_B = 2;
    // Mocked responses
    uint256 constant COST = 42;

    function setUp() public {
        token = new Token("Omni Token", "OT", OWNER, CAP, address(0x01));
        // Mock message cost
        vm.mockCall(GATEWAY, abi.encodeWithSelector(IGateway.estimateMessageCost.selector), abi.encode(COST));
    }

    function test_Cost() public view {
        assertEq(token.cost(NETWORK_A), COST);
    }
}
