pragma solidity ^0.8.0;

import {IOmnichain} from "./IOmnichain.sol";
import {IGateway} from "@analog-gmp/interfaces/IGateway.sol";

// TODO see BasicERC20 example
contract Token is IOmnichain {
    IGateway private immutable _gateway;

    constructor(IGateway gateway) {
        _gateway = gateway;
    }

    function cost(uint16 networkId) external view returns (uint256) {
        return _gateway.estimateMessageCost(networkId, 96, 100000);
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
