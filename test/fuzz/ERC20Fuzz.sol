// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test, console } from "forge-std/Test.sol";
import { ERC20 } from "../../src/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract testERC20Fuzz is Test {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    string public constant NAME = "Kyber Network Crystal";
    string public constant SYMBOL = "KNC";

    address public OWNER = makeAddr("Kyber DAO");
    address public alice = makeAddr("Alice");
    address public bob = makeAddr("Bob");
    address public mark = makeAddr("Mark");

    uint256 public constant INITIAL_AMOUNT = 1000 ether;

    ERC20 token;

    modifier fund(address _account, uint256 _amount) {
        vm.prank(OWNER);
        token.transfer(_account, _amount);
        _;
    }

    function setUp() external {
        vm.prank(OWNER);
        token = new ERC20(NAME, SYMBOL);
    }

    function testTransfer(address _to, uint256 _amount) external {
        vm.assume(_to != address(0));
        _amount = bound(_amount, 0, token.balanceOf(OWNER));


        uint256 _totalSupply = token.totalSupply();
        uint256 _prevOwnerBalance = token.balanceOf(OWNER);
        uint256 _prevReceiverBalance = token.balanceOf(_to);

        vm.startPrank(OWNER);
        
        vm.expectEmit();
        emit Transfer(OWNER, _to, _amount);

        bool success = token.transfer(_to, _amount);
        assert(success);
        vm.stopPrank();

        assert(token.totalSupply() == _totalSupply);

        if (_to == OWNER) {
            assert(token.balanceOf(OWNER) == _prevOwnerBalance);
        } else {
            assert(token.balanceOf(OWNER) == _prevOwnerBalance - _amount);
            assert(token.balanceOf(_to) == _prevReceiverBalance + _amount);
        }
    }

    function testCantTransferWithExceedBalance(address _to, uint256 _amount) public {
        vm.assume(_to != address(0));
     
        _amount = bound(_amount, token.balanceOf(OWNER) + 1, type(uint256).max);

        vm.startPrank(OWNER);

        vm.expectRevert(
            abi.encodeWithSelector(
                ERC20.ERC20InsufficientBalance.selector,
                OWNER, 
                token.balanceOf(OWNER),
                _amount
            )
        );

        bool success = token.transfer(_to, _amount);
        assert(success == false);

        vm.stopPrank();
        

    }




}