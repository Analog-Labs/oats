pragma solidity ^0.8.0;

import {IGmpReceiver} from "@analog-gmp/interfaces/IGmpReceiver.sol";

/// @notice Interface for GMP-based token transfers across chains.
interface ISender {
    /// @notice Get GMP message cost for cross-chain tokens transfer
    /// @param networkId Chain Id of the target network
    function cost(uint16 networkId) external view returns (uint256);
    /// @notice Transfer tokens to another network.
    /// Note this is payable, caller should transfer GMP fee amount provided by cost function above
    /// @param networkId Chain Id of the target network
    /// @param recipient address of the recipient account
    /// @param amount amount to transfer
    /// @return msgId GMP message Id
    function send(uint16 networkId, address recipient, uint256 amount) external payable returns (bytes32 msgId);
}

/// @notice Implementor of this interface becomes OATS compliant.
interface IOmnichain is ISender, IGmpReceiver {}
