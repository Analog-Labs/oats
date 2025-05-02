pragma solidity ^0.8.0;

import {Token} from "../src/Token.sol";
import {IGateway} from "@analog-gmp/interfaces/IGateway.sol";
import {ERC20Capped} from "@openzeppelin/token/ERC20/extensions/ERC20Capped.sol";
import {IERC20Errors} from "@openzeppelin/token/ERC20/ERC20.sol";
import {Test} from "forge-std/Test.sol";

contract TokenTest is Test {
    Token public token;

    address constant OWNER = address(0x01);
    address constant USER = address(0x02);
    address constant TOKEN = address(0x03);
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
        assertEq(token.cost(NETWORK), COST);
    }

    function test_Recieve() public {
        assertEq(token.balanceOf(OWNER), CAP / 2);
        assertEq(token.totalSupply(), CAP / 2);
        assertEq(token.balanceOf(USER), 0);

        bytes memory data = abi.encode(Token.TransferCmd({from: OWNER, to: USER, amount: AMOUNT}));
        bytes32 token_b = bytes32(uint256(uint160(TOKEN)));

        vm.expectRevert(bytes("Unauthorized: only the gateway can call this method"));
        token.onGmpReceived(MSG_ID, NETWORK, token_b, 0, data);

        vm.prank(GATEWAY);
        vm.expectRevert(bytes("Transfer from unknown network"));
        token.onGmpReceived(MSG_ID, NETWORK, token_b, 0, data);

        vm.prank(OWNER);
        token.set_network(NETWORK, TOKEN);

        vm.prank(GATEWAY);
        token.onGmpReceived(MSG_ID, NETWORK, token_b, 0, data);

        assertEq(token.balanceOf(USER), AMOUNT);
        assertEq(token.totalSupply(), CAP / 2 + AMOUNT);

        data = abi.encode(Token.TransferCmd({from: OWNER, to: USER, amount: CAP / 2}));
        vm.prank(GATEWAY);
        vm.expectPartialRevert(ERC20Capped.ERC20ExceededCap.selector);
        token.onGmpReceived(MSG_ID, NETWORK, token_b, 0, data);
    }

    function test_Send() public {
        assertEq(token.balanceOf(OWNER), CAP / 2);
        assertEq(token.balanceOf(USER), 0);

        vm.prank(USER);
        vm.expectRevert(bytes("Unknown token on target network"));
        token.send(NETWORK, OWNER, AMOUNT);

        vm.prank(OWNER);
        token.set_network(NETWORK, TOKEN);

        vm.prank(USER);
        vm.expectPartialRevert(IERC20Errors.ERC20InsufficientBalance.selector);
        token.send(NETWORK, OWNER, AMOUNT);

        vm.prank(OWNER);
        token.transfer(USER, AMOUNT);

        vm.prank(USER);
        token.send(NETWORK, OWNER, AMOUNT);
        assertEq(token.balanceOf(USER), 0);
        assertEq(token.totalSupply(), CAP / 2 - AMOUNT);
    }
}
