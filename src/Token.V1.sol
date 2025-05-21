pragma solidity ^0.8.0;

import {ISender} from "./IOATS.sol";
import {IGateway} from "@analog-gmp/interfaces/IGateway.sol";
import {IGmpReceiver} from "@analog-gmp/interfaces/IGmpReceiver.sol";

import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Capped} from "@openzeppelin/token/ERC20/extensions/ERC20Capped.sol";

/// @notice Example of an OATS-compliant Sender token with fixed cap,
/// working on burn/mint model.
contract Token is ISender, IGmpReceiver, Ownable, ERC20Burnable, ERC20Capped {
    /// @notice GMP gateway
    IGateway private immutable _gateway;
    /// @notice Supported networks with token contract addresses
    mapping(uint16 => address) public networks;

    uint256 private constant GAS_LIMIT = 100_000;

    struct TransferCmd {
        address from;
        address to;
        uint256 amount;
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

    /// @inheritdoc ISender
    function cost(uint16 networkId) external view returns (uint256) {
        return _gateway.estimateMessageCost(networkId, 96, GAS_LIMIT);
    }

    /// @inheritdoc ISender
    function send(uint16 networkId, address recipient, uint256 amount) external payable returns (bytes32 msgId) {
        address targetToken = networks[networkId];
        require(targetToken != address(0), "Unknown token on target network");

        _burn(msg.sender, amount);

        bytes memory message = abi.encode(TransferCmd({from: msg.sender, to: recipient, amount: amount}));
        return _gateway.submitMessage{value: msg.value}(targetToken, networkId, GAS_LIMIT, message);
    }

    /// @inheritdoc IGmpReceiver
    function onGmpReceived(bytes32 id, uint128 networkId, bytes32 source, uint64, bytes calldata data)
        external
        payable
        returns (bytes32)
    {
        require(msg.sender == address(_gateway), "Unauthorized: only the gateway can call this method");
        require(networks[uint16(networkId)] == address(uint160(uint256(source))), "Transfer from unknown network");

        TransferCmd memory cmd = abi.decode(data, (TransferCmd));

        _mint(cmd.to, cmd.amount);

        return id;
    }

    /// @inheritdoc ERC20
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Capped) {
        super._update(from, to, value);
    }
}
