// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// Bug Hunt #003, reference fix. Compare with Treasury.sol.
contract TreasuryFixed {
    address public owner;

    constructor() payable {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(owner).transfer(amount);
    }

    receive() external payable {}
}
