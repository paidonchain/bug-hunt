// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// Bug Hunt #002, reference fix. Compare with Wallet.sol.
contract WalletFixed {
    address public owner;

    constructor() payable {
        owner = msg.sender;
    }

    function pay(address payable to, uint256 amount) external {
        require(msg.sender == owner, "not owner");
        to.transfer(amount);
    }

    receive() external payable {}
}
