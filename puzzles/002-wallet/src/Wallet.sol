// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// Bug Hunt #002: an owner-only wallet. How can a stranger move the funds?
contract Wallet {
    address public owner;

    constructor() payable {
        owner = msg.sender;
    }

    function pay(address payable to, uint256 amount) external {
        require(tx.origin == owner, "not owner");
        to.transfer(amount);
    }

    receive() external payable {}
}
