pragma solidity ^0.8.0;

import {IGmpReceiver} from "@analog-gmp/interfaces/IGmpReceiver.sol";

interface ISender {
    function cost(uint16 networkid) external view returns (uint256);
    function send(uint16 networkid, address recipient, uint256 amount) external payable returns (bytes32 msgId);
}

interface IOmnichain is ISender, IGmpReceiver {}
