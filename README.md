# OATS: Omnichain Analog Token Standard

## Spec

See: 

+ [ERD](https://hackmd.io/bg0DTqWjSFOf7lV_7KyiOA),
+ [analog-spec](https://github.com/Analog-Labs/analog-spec/blob/master/src/products/OATS.md).

## Docs 

To generate Solidity docs as an mdbook, run: 

``` shell
forge doc -b
```

## Token Guide
_(If you want to make you token omni-chain):_

Implement (either one of, or both) the following interface(s) in your token contract:

- [ISender](src/IOATS.sol#L6) if you want your token be cross-chain transferrable.  
  See [TokenSender](src/TokenSender.sol) example for reference implementation, along with its [test](test/TokenSender.t.sol).

- [ISenderCaller](src/IOATS.sol#L20) if you want your token be cross-chain transferrable and call some external contract on the destination network upon such a transfer delivery.  
  See [TokenSenderCaller](src/TokenSenderCaller.sol) example for reference implementation, along with its [test](test/TokenSenderCaller.t.sol).
  

## Integration Guide
_(If you want your contract be called upon x-chain token transfer):_

Implement [ICallee](src/IOATS.sol#L30) interface in your contract. The `onTransferReceived()` callback function will be called by GMP Gateway once the tokens are delivered to target network. 

> [!IMPORTANT]  
> The caller of `onTransferReceived()` **MUST be checked** to be the token contract you want to integrate with.

> [!NOTE]  
> In case `onTransferReceived()` execution fails, GMP message is still considered delivered, and token transfer **is not reverted**. 
> Caller contract emits specific [events](src/IOATS.sol#L57) reflecting the callback execution outcome.

See [Callee](test/TokenSenderCaller.t.sol) example contract in the test for reference implementation.
