pragma solidity ^0.8.0;

import {Token} from "../src/Token.sol";
import {IGateway} from "@analog-gmp/interfaces/IGateway.sol";
import {ERC20Capped} from "@openzeppelin/token/ERC20/extensions/ERC20Capped.sol";
import {IERC20Errors} from "@openzeppelin/token/ERC20/ERC20.sol";
import {Test, console} from "forge-std/Test.sol";

contract TokenTest is Test {
    Token public token;
    // Anvil 1st dev account
    address constant OWNER = 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496;
    address constant GATEWAY = address(0x42);
    uint256 constant CAP = 1_000_000;
    uint16 constant NETWORK_A = 1;
    uint16 constant NETWORK_B = 2;
    address constant TOKEN_A = address(0x01);
    address constant TOKEN_B = address(0x02);
    address constant USER_A = address(0x03);
    address constant USER_B = address(0x04);

    // Mocked responses
    uint256 constant COST = 42;

    struct TransferCmd {
        address from;
        address to;
        uint256 amount;
    }

    function setUp() public {
        token = new Token("Omni Token", "OT", OWNER, CAP, GATEWAY);
        // Mock message cost
        vm.mockCall(GATEWAY, abi.encodeWithSelector(IGateway.estimateMessageCost.selector), abi.encode(COST));
        // Mock submit message
        vm.mockCall(
            GATEWAY, abi.encodeWithSelector(IGateway.submitMessage.selector), abi.encode(bytes32(uint256(0xff)))
        );
    }

    function test_Cost() public view {
        assertEq(token.cost(NETWORK_A), COST);
    }

    function test_Recieve() public {
        assertEq(token.balanceOf(OWNER), CAP / 2);
        assertEq(token.totalSupply(), CAP / 2);
        assertEq(token.balanceOf(USER_A), 0);

        bytes memory data = abi.encode(TransferCmd({from: USER_B, to: USER_A, amount: 100500}));
        bytes32 token_b = bytes32(uint256(uint160(TOKEN_B)));

        vm.expectRevert(bytes("Unauthorized: only the gateway can call this method"));
        token.onGmpReceived(bytes32(uint256(0xff)), NETWORK_B, token_b, 0, data);

        vm.prank(GATEWAY);
        vm.expectRevert(bytes("Transfer from unknown network"));
        token.onGmpReceived(bytes32(uint256(0xff)), NETWORK_B, token_b, 0, data);

        vm.prank(OWNER);
        token.set_network(NETWORK_B, TOKEN_B);

        vm.prank(GATEWAY);
        token.onGmpReceived(bytes32(uint256(0xff)), NETWORK_B, token_b, 0, data);

        assertEq(token.balanceOf(USER_A), 100500);
        assertEq(token.totalSupply(), CAP / 2 + 100500);

        data = abi.encode(TransferCmd({from: USER_B, to: USER_A, amount: CAP / 2}));
        vm.prank(GATEWAY);
        vm.expectPartialRevert(ERC20Capped.ERC20ExceededCap.selector);
        token.onGmpReceived(bytes32(uint256(0xff)), NETWORK_B, token_b, 0, data);
    }

    function test_Send() public {
        assertEq(token.balanceOf(OWNER), CAP / 2);
        assertEq(token.balanceOf(USER_A), 0);

        vm.prank(USER_A);
        vm.expectRevert(bytes("Unknown token on target network"));
        token.send(NETWORK_B, USER_B, 100500);

        vm.prank(OWNER);
        token.set_network(NETWORK_B, TOKEN_B);

        vm.prank(USER_A);
        vm.expectPartialRevert(IERC20Errors.ERC20InsufficientBalance.selector);
        token.send(NETWORK_B, USER_B, 100500);

        vm.prank(OWNER);
        token.transfer(USER_A, 100500);

        vm.prank(USER_A);
        token.send(NETWORK_B, USER_B, 100500);
        assertEq(token.balanceOf(USER_A), 0);
        assertEq(token.totalSupply(), CAP / 2 - 100500);
    }
}
