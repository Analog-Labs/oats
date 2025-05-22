pragma solidity ^0.8.0;

import {Token} from "../src/TokenSenderCaller.sol";
import {Utils, ICallee} from "../src/IOATS.sol";
import {IGateway} from "@analog-gmp/interfaces/IGateway.sol";
import {ERC20Capped} from "@openzeppelin/token/ERC20/extensions/ERC20Capped.sol";
import {IERC20Errors} from "@openzeppelin/token/ERC20/ERC20.sol";
import {Test} from "forge-std/Test.sol";

contract TokenSenderCallerTest is Test {
    Token public token;
    Callee public callee;

    address constant OWNER = address(0x01);
    address constant USER = address(0x02);
    address constant TOKEN = address(0x03);
    address constant GATEWAY = address(0x42);

    uint256 constant CAP = 1_000_000;
    uint256 constant AMOUNT = 100500;

    uint16 constant NETWORK = 2;
    bytes32 constant MSG_ID = bytes32(uint256(0xff));

    function setUp() public {
        token = new Token("Omni Token", "OT", OWNER, CAP, GATEWAY);
        callee = new Callee();
    }

    function test_Recieve() public {
        assertEq(token.balanceOf(OWNER), CAP / 2);
        assertEq(token.totalSupply(), CAP / 2);
        assertEq(token.balanceOf(USER), 0);

        Token.TransferCmd memory cmd =
            Token.TransferCmd({from: OWNER, to: USER, amount: AMOUNT, callee: address(0), caldata: new bytes(0)});

        bytes memory data = abi.encode(cmd);
        bytes32 token_b = bytes32(uint256(uint160(TOKEN)));

        // NOT GATEWAY CB
        vm.expectPartialRevert(Utils.UnauthorizedGW.selector);
        token.onGmpReceived(MSG_ID, NETWORK, token_b, 0, data);

        // NETWORK NOT SET
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

        // INVALID CALL:
        // - should not revert, but emit InvalidCallee event,
        // - should deliver the transfer
        cmd.callee = address(1);
        data = abi.encode(cmd);
        vm.expectEmit(true, false, false, false, address(token));
        emit Utils.InvalidCallee(address(1));
        token.onGmpReceived(MSG_ID, NETWORK, token_b, 0, data);
        assertEq(token.balanceOf(USER), AMOUNT * 2);
        assertEq(token.totalSupply(), CAP / 2 + AMOUNT * 2);
        assertEq(callee.total(), 0);

        // CALL SUCCEED
        cmd.callee = address(callee);
        data = abi.encode(cmd);
        vm.expectEmit(address(token));
        emit Utils.CallSucceed();
        token.onGmpReceived(MSG_ID, NETWORK, token_b, 0, data);
        assertEq(token.balanceOf(USER), AMOUNT * 3);
        assertEq(token.totalSupply(), CAP / 2 + AMOUNT * 3);
        assertEq(callee.total(), AMOUNT);

        // CALL FAILED:
        // - should not revert, but emit callFailed event,
        // - should deliver the transfer
        cmd.from = address(0);
        data = abi.encode(cmd);
        vm.expectEmit(address(token));
        emit Utils.CallFailed();
        token.onGmpReceived(MSG_ID, NETWORK, token_b, 0, data);
        assertEq(token.balanceOf(USER), AMOUNT * 4);
        assertEq(token.totalSupply(), CAP / 2 + AMOUNT * 4);
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

    function onTransferReceived(address from, address, uint256 amount, bytes calldata) external {
        require(from != address(0), "Failed");

        total += amount;
    }
}
