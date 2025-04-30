pragma solidity ^0.8.0;

import {IOmnichain} from "./IOmnichain.sol";
import {IGateway} from "@analog-gmp/interfaces/IGateway.sol";

import {Ownable} from "@openzeppelin/access/Ownable.sol";

contract Token is IOmnichain, Ownable {
    IGateway private immutable _gateway;
    mapping(uint16 => address) public networks;

    uint256 private constant GAS_LIMIT = 100_000;

    struct TransferCmd {
        address from;
        address to;
        uint256 amount;
    }

    constructor(address owner, IGateway gateway) Ownable(owner) {
        _gateway = gateway;
    }

    function set_network(uint16 networkId, address token) public onlyOwner {
        networks[networkId] = token;
    }

    function cost(uint16 networkId) external view returns (uint256) {
        return _gateway.estimateMessageCost(networkId, 96, GAS_LIMIT);
    }

    function send(uint16 networkid, bytes32 recipient, uint256 amount) external payable returns (bytes32) {
        return 0x00;
    }

    function onGmpReceived(bytes32 id, uint128 network, bytes32 source, uint64 nonce, bytes calldata payload)
        external
        payable
        returns (bytes32)
    {
        return 0x00;
    }
}
