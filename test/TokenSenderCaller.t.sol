pragma solidity ^0.8.0;

import {Token} from "../src/TokenSenderCaller.sol";
import {Utils} from "../src/IOATS.sol";
import {IGateway} from "@analog-gmp/interfaces/IGateway.sol";
import {ERC20Capped} from "@openzeppelin/token/ERC20/extensions/ERC20Capped.sol";
import {IERC20Errors} from "@openzeppelin/token/ERC20/ERC20.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

contract TokenSenderCallerTest is Test {
    Token public token;

    address constant OWNER = address(0x01);
    address constant USER = address(0x02);
    address constant TOKEN = address(0x03);
    address constant CALLEE = address(0x04);
    address constant GATEWAY = address(0x42);

    uint256 constant CAP = 1_000_000;
    uint256 constant AMOUNT = 100500;

    uint16 constant NETWORK = 2;
    bytes32 constant MSG_ID = bytes32(uint256(0xff));
    // Mocked response
    uint256 constant COST = 42;

    function setUp() public {
        token = new Token("Omni Token", "OT", OWNER, CAP, GATEWAY);
        // Mock message cost
        vm.mockCall(GATEWAY, abi.encodeWithSelector(IGateway.estimateMessageCost.selector), abi.encode(COST));
        // Mock submit message
        vm.mockCall(GATEWAY, abi.encodeWithSelector(IGateway.submitMessage.selector), abi.encode(MSG_ID));
    }

    function test_Cost() public view {
        assertTrue(false, "TBD");
    }

    function test_SendAndCall() public view {
        assertTrue(false, "TBD");
    }

    function test_Receive() public view {
        assertTrue(false, "TBD");
    }
}
