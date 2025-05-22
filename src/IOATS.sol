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

/// @notice Interface for making GMP-based token transfer + contract call across chains.
interface ISenderCaller {
    function cost(uint16 networkId, bytes memory caldata) external view returns (uint256);

    function sendAndCall(uint16 networkId, address recipient, uint256 amount, address callee, bytes memory caldata)
        external
        payable
        returns (bytes32 msgId);
}

/// @notice Callee to be called upon x-chain token transfer delivery
interface ICallee {
    function onTransferReceived(address from, address to, uint256 amount, bytes calldata caldata) external;
}

library Utils {
    /**
     * @dev onGmpRecieved() caller is not the gateway
     * @param caller Address of the callback caller
     */
    error UnauthorizedGW(address caller);
    /**
     * @dev Unknown source network
     * @param networkId of the source network
     */
    error UnknownNetwork(uint16 networkId);
    /**
     * @dev Unknown token on target network
     * @param token Address of the token
     */
    error UnknownToken(address token);
    /**
     * @dev Callback callee address is wrong.
     * @param callee Address of the contract to be called.
     */
    error InvalidCallee(address callee);
}
