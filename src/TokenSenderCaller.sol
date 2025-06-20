pragma solidity ^0.8.0;

import {ISenderCaller, ICallee, Utils} from "./IOATS.sol";
import {IGateway} from "gmp-2.0.0/src/IGateway.sol";
import {IGmpReceiver} from "gmp-2.0.0/src/IGmpReceiver.sol";

import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Capped} from "@openzeppelin/token/ERC20/extensions/ERC20Capped.sol";

/// @notice Example of an OATS-compliant SenderCaller token with fixed cap,
/// working on burn/mint model.
contract Token is ISenderCaller, IGmpReceiver, Ownable, ERC20Burnable, ERC20Capped {
    /// @notice GMP gateway
    IGateway private immutable _gateway;
    /// @notice Supported networks with token contract addresses
    mapping(uint16 => address) public networks;

    struct TransferCmd {
        address from;
        address to;
        uint256 amount;
        address callee;
        bytes caldata;
    }

    constructor(string memory name, string memory symbol, address owner, uint256 cap, address gateway)
        ERC20(name, symbol)
        Ownable(owner)
        ERC20Capped(cap)
    {
        _gateway = IGateway(gateway);
        _mint(owner, cap / 2);
    }

    /// @notice Set supported network
    function set_network(uint16 networkId, address token) public onlyOwner {
        networks[networkId] = token;
    }

    /// @inheritdoc ISenderCaller
    function cost(uint16 networkId, uint64 gasLimit, bytes memory caldata) external view returns (uint256) {
        TransferCmd memory Default;
        Default.caldata = caldata;
        bytes memory message = abi.encode(Default);

        return _gateway.estimateMessageCost(networkId, message.length, gasLimit);
    }

    /// @inheritdoc ISenderCaller
    function sendAndCall(
        uint16 networkId,
        address recipient,
        uint256 amount,
        uint64 gasLimit,
        address callee,
        bytes memory caldata
    ) external payable returns (bytes32 msgId) {
        address targetToken = networks[networkId];
        require(targetToken != address(0), Utils.UnknownToken(targetToken));

        _burn(msg.sender, amount);

        bytes memory message =
            abi.encode(TransferCmd({from: msg.sender, to: recipient, amount: amount, callee: callee, caldata: caldata}));

        return _gateway.submitMessage{value: msg.value}(targetToken, networkId, gasLimit, message);
    }

    /// @inheritdoc IGmpReceiver
    function onGmpReceived(bytes32 id, uint128 networkId, bytes32 source, uint64, bytes calldata data)
        external
        payable
        returns (bytes32)
    {
        require(msg.sender == address(_gateway), Utils.UnauthorizedGW(msg.sender));
        require(
            networks[uint16(networkId)] == address(uint160(uint256(source))), Utils.UnknownNetwork(uint16(networkId))
        );

        TransferCmd memory cmd = abi.decode(data, (TransferCmd));

        _mint(cmd.to, cmd.amount);

        // Make callback if needed
        if (cmd.callee != address(0)) {
            if (cmd.callee.code.length == 0) {
                emit Utils.InvalidCallee(cmd.callee);
            } else {
                try ICallee(cmd.callee).onTransferReceived(cmd.from, cmd.to, cmd.amount, cmd.caldata) {
                    emit Utils.CallSucceed();
                } catch {
                    emit Utils.CallFailed();
                }
            }
        }

        return id;
    }

    /// @inheritdoc ERC20
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Capped) {
        super._update(from, to, value);
    }
}
