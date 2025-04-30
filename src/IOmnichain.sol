pragma solidity ^0.8.0;

import {IGmpReceiver} from "@analog-gmp/interfaces/IGmpReceiver.sol";

interface ISender {
    function cost(uint16 networkid) external view returns (uint256);
    function send(uint16 networkid, bytes32 recipient, uint256 amount) external payable returns (bytes32);
}

interface IOmnichain is ISender, IGmpReceiver {}
