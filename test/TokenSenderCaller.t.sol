pragma solidity ^0.8.0;

import {Token} from "../src/TokenSenderCaller.sol";
import {Utils, ICallee} from "../src/IOATS.sol";
import {IGateway} from "@analog-gmp/interfaces/IGateway.sol";
import {ERC20Capped} from "@openzeppelin/token/ERC20/extensions/ERC20Capped.sol";
import {IERC20Errors} from "@openzeppelin/token/ERC20/ERC20.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

contract TokenSenderCallerTest is Test {
    Token public token;
    Callee public callee;

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
        callee = new Callee();
        // Mock message cost
        vm.mockCall(GATEWAY, abi.encodeWithSelector(IGateway.estimateMessageCost.selector), abi.encode(COST));
        // Mock submit message
        vm.mockCall(GATEWAY, abi.encodeWithSelector(IGateway.submitMessage.selector), abi.encode(MSG_ID));
    }

    function test_Recieve() public {
        assertEq(token.balanceOf(OWNER), CAP / 2);
        assertEq(token.totalSupply(), CAP / 2);
        assertEq(token.balanceOf(USER), 0);

        Token.TransferCmd memory cmd =
            Token.TransferCmd({from: OWNER, to: USER, amount: AMOUNT, callee: address(0), caldata: new bytes(0)});

        bytes memory data = abi.encode(cmd);
        bytes32 token_b = bytes32(uint256(uint160(TOKEN)));

        vm.expectPartialRevert(Utils.UnauthorizedGW.selector);
        token.onGmpReceived(MSG_ID, NETWORK, token_b, 0, data);

        vm.prank(GATEWAY);
        vm.expectPartialRevert(Utils.UnknownNetwork.selector);
        token.onGmpReceived(MSG_ID, NETWORK, token_b, 0, data);

        vm.prank(OWNER);
        token.set_network(NETWORK, TOKEN);

        // NO CALL
        vm.startPrank(GATEWAY);
        token.onGmpReceived(MSG_ID, NETWORK, token_b, 0, data);

        assertEq(token.balanceOf(USER), AMOUNT);
        assertEq(token.totalSupply(), CAP / 2 + AMOUNT);
        assertEq(callee.total(), 0);

        // INVALID CALL
        cmd.callee = address(1);
        data = abi.encode(cmd);
        vm.expectPartialRevert(Utils.InvalidCallee.selector);
        token.onGmpReceived(MSG_ID, NETWORK, token_b, 0, data);
        assertEq(token.balanceOf(USER), AMOUNT);
        assertEq(token.totalSupply(), CAP / 2 + AMOUNT);
        assertEq(callee.total(), 0);

        // VALID CALL
        cmd.callee = address(callee);
        data = abi.encode(cmd);
        token.onGmpReceived(MSG_ID, NETWORK, token_b, 0, data);
        assertEq(token.balanceOf(USER), AMOUNT * 2);
        assertEq(token.totalSupply(), CAP / 2 + AMOUNT * 2);
        assertEq(callee.total(), AMOUNT);

        // CAP EXCEEDED
        data = abi.encode(
            Token.TransferCmd({from: OWNER, to: USER, amount: CAP / 2, callee: address(callee), caldata: new bytes(0)})
        );
        vm.expectPartialRevert(ERC20Capped.ERC20ExceededCap.selector);
        token.onGmpReceived(MSG_ID, NETWORK, token_b, 0, data);
    }
}

contract Callee is ICallee {
    uint256 public total;

    function onTransferReceived(address, address, uint256 amount, bytes calldata) external {
        total += amount;
    }
}
