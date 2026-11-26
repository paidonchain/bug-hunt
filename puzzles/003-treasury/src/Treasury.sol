// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// Bug Hunt #003: a treasury only the owner can withdraw from. Or so it seems.
contract Treasury {
    address public owner;

    constructor() payable {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function setOwner(address newOwner) external {
        owner = newOwner;
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(owner).transfer(amount);
    }

    receive() external payable {}
}
