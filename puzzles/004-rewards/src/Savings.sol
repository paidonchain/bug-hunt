// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// Bug Hunt #004: a savings box with a one-day cooldown between withdrawals.
contract Savings {
    struct Account {
        uint256 balance;
        uint256 lastWithdraw;
    }

    mapping(address => Account) public accounts;

    function deposit() external payable {
        accounts[msg.sender].balance += msg.value;
    }

    function withdraw() external {
        Account memory acct = accounts[msg.sender];
        require(block.timestamp >= acct.lastWithdraw + 1 days, "cooldown");
        uint256 amount = acct.balance;
        require(amount > 0, "nothing to withdraw");
        acct.balance = 0;
        acct.lastWithdraw = block.timestamp;
        payable(msg.sender).transfer(amount);
    }
}
