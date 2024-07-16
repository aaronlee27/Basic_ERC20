// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test, console } from "forge-std/Test.sol";
import { ERC20 } from "../../src/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract testERC20Unit is Test {
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

    function testOwner() public view {
        assert(token.owner() == OWNER);
    }

    function testMintMaxSupplyAfterConstructor() public view {
        // OWNER HAS 1 BILLION TOKEN IN THEIR WALLET
        assert(token.balanceOf(OWNER) == token.getMaxSupply());
    }

    ////////////////////////////////////////////////////
    ////////// ERC20 TRANSFER //////////////////////////
    ////////////////////////////////////////////////////

    function testCanTransfer() public fund(alice, INITIAL_AMOUNT) fund(bob, INITIAL_AMOUNT){
        uint256 _amount = 100 ether;
        uint256 _oldSupply = token.totalSupply();

        vm.startPrank(alice);

        vm.expectEmit();
        emit Transfer(alice, bob, _amount);

        bool success = token.transfer(bob, _amount);

        vm.stopPrank();

        // Check function returns true
        // Check balance of both alice and bob
        // Check totalSupply doesn't change
        // check emit event

        assert(success == true);
        assert(token.balanceOf(alice) == INITIAL_AMOUNT - _amount);
        assert(token.balanceOf(bob) == INITIAL_AMOUNT + _amount);
        assert(token.totalSupply() == _oldSupply);

        console.log("Balance of Alice is: ", token.balanceOf(alice));
        console.log("Balance of Bob is: ", token.balanceOf(bob));
        console.log("Total Supply is: ", token.totalSupply());
    }

    function testCantTransferWhenAmountInsufficent() public fund(alice, INITIAL_AMOUNT) {
        uint256 _amount = 1500 ether;
        
        vm.startPrank(alice);

        vm.expectRevert(
            abi.encodeWithSelector(
                ERC20.ERC20InsufficientBalance.selector, 
                alice,
                INITIAL_AMOUNT,
                _amount
            )
        );

        bool success = token.transfer(bob, _amount);
        vm.stopPrank();

        assert(success == false);
    }
    
    function testCantTransferWhenSenderIsZeroAddress() public {
        vm.startPrank(address(0));

        vm.expectRevert(
            abi.encodeWithSelector(
                ERC20.ERC20InvalidSender.selector,
                address(0)
            )
        );

        token.transfer(bob, 100 ether);

        vm.stopPrank();
    }

    function testCantTransferWhenReceiverIsZeroAddress() public fund(alice, INITIAL_AMOUNT) {
        uint256 _amount = 100 ether;

        vm.startPrank(alice);

        vm.expectRevert(
            abi.encodeWithSelector(
                ERC20.ERC20InvalidReceiver.selector,
                address(0)
            )
        );

        token.transfer(address(0), _amount);

        vm.stopPrank();
    }

    ////////////////////////////////////////////////////
    ////////// ERC20 APPROVE ///////////////////////////
    ////////////////////////////////////////////////////

    function testApprove() public fund(alice, INITIAL_AMOUNT) {
        uint256 amountApprove = 100 ether;
        
        vm.startPrank(alice);

        vm.expectEmit();
        emit Approval(alice, mark, amountApprove);

        bool success = token.approve(mark, amountApprove);
        assert(success);

        vm.stopPrank();

        // check allowance

        assert(token.allowance(alice, mark) == amountApprove);
    }
    
    ////////////////////////////////////////////////////
    ////////// ERC20 TRANSFERFROM //////////////////////
    ////////////////////////////////////////////////////
    
    function testTranferFrom() public fund(alice, INITIAL_AMOUNT) {
        uint256 amountApprove = 100 ether;
        uint256 amountToSend = 30 ether;
        uint256 _oldSupply = token.totalSupply();

        vm.startPrank(alice);

        vm.expectEmit();
        emit Approval(alice, mark, amountApprove);

        bool success = token.approve(mark, amountApprove);
        assert(success);

        vm.stopPrank();

        vm.startPrank(mark);

        vm.expectEmit();
        emit Transfer(alice, bob, amountToSend);
        
        success = token.transferFrom(alice, bob, amountToSend);
        assert(success);

        vm.stopPrank();

        // check success is true
        // check balance of alice
        // check balance of bob
        // check allowance of alice to mark
        // check total supply

        console.log(token.balanceOf(alice));
        console.log(token.balanceOf(bob));
        console.log(token.allowance(alice, mark));
        console.log(token.totalSupply());


        assert(success);
        assert(token.balanceOf(alice) == INITIAL_AMOUNT - amountToSend);
        assert(token.balanceOf(bob) == amountToSend);
        assert(token.allowance(alice, mark) == amountApprove - amountToSend);
        assert(token.totalSupply() == _oldSupply);
    }

    function testCantTransferFromIfAllowanceInsufficient() public fund(alice, INITIAL_AMOUNT) {
        uint256 amountApprove = 100 ether;
        uint256 amountToSend = 300 ether;

        vm.startPrank(alice);

        vm.expectEmit();
        emit Approval(alice, mark, amountApprove);

        bool success = token.approve(mark, amountApprove);
        assert(success);

        vm.stopPrank();

        vm.startPrank(mark);

        vm.expectRevert(
            abi.encodeWithSelector(
                ERC20.ERC20InsufficientAllowance.selector,
                mark,
                amountApprove,
                amountToSend
            )
        );
        
        success = token.transferFrom(alice, bob, amountToSend);
        assert(success == false);

        vm.stopPrank();
    }

    function testCantTransferFromIfBalanceInSufficient() public fund(alice, INITIAL_AMOUNT) {
        uint256 amountApprove = 1500 ether;
        uint256 amountToSend = 1200 ether;

        vm.startPrank(alice);

        vm.expectEmit();
        emit Approval(alice, mark, amountApprove);

        bool success = token.approve(mark, amountApprove);
        assert(success);

        vm.stopPrank();

        vm.startPrank(mark);

        vm.expectRevert(abi.encodeWithSelector(
            ERC20.ERC20InsufficientBalance.selector,
            alice,
            INITIAL_AMOUNT,
            amountToSend
        ));
        
        success = token.transferFrom(alice, bob, amountToSend);
        assert(success == false);

        vm.stopPrank();
    }

    ////////////////////////////////////////////////////
    ////////// ERC20 BURN /////////////////////////////
    ////////////////////////////////////////////////////

    function testCanBurn() public fund(alice, INITIAL_AMOUNT) {
        uint256 _amountToBurn = 100 ether;
        uint256 _oldSupply = token.totalSupply();
        
        vm.startPrank(alice);

        vm.expectEmit();
        emit Transfer(alice, address(0), _amountToBurn);

        token.burn(_amountToBurn);

        vm.stopPrank();

        // Check the balance
        // Check the supply

        assert(token.balanceOf(alice) == INITIAL_AMOUNT - _amountToBurn);
        assert(token.totalSupply() == _oldSupply - _amountToBurn);
    }

    function testCantBurnThatExceedBalance() public fund(alice, INITIAL_AMOUNT) {
        uint256 _amountToBurn = 1500 ether;
        
        vm.startPrank(alice);

        vm.expectRevert(
            abi.encodeWithSelector(
                ERC20.ERC20InsufficientBalance.selector,
                alice,
                INITIAL_AMOUNT,
                _amountToBurn
            )
        );

        token.burn(_amountToBurn);

        vm.stopPrank();
    }

    function testCanBurnAllToken() public {
        uint256 _amountToBurn = 1e9 ether;
        uint256 _oldSupply = token.totalSupply();

        assert(_oldSupply == 1e9 ether);

        vm.startPrank(OWNER);

        vm.expectEmit();
        emit Transfer(OWNER, address(0), _amountToBurn);
        token.burn(_amountToBurn);

        vm.stopPrank();

        assert(token.totalSupply() == 0);
    }

    ////////////////////////////////////////////////////
    ////////// ERC20 MINT /////////////////////////////
    ////////////////////////////////////////////////////

    function testCanMintWithOwner() public fund(alice, INITIAL_AMOUNT) {
        // burn for alice
        uint256 _amountToMint = 100 ether;
        uint256 _firstSupply = token.totalSupply();
        
        vm.startPrank(alice);

        token.burn(_amountToMint);

        vm.stopPrank();

        assert(token.totalSupply() == _firstSupply - _amountToMint);

        vm.startPrank(OWNER);

        vm.expectEmit();
        emit Transfer(address(0), mark, _amountToMint);

        token.mint(mark, _amountToMint);

        vm.stopPrank();

        // check balance of Mark and totalSupply
        assert(token.totalSupply() == _firstSupply);
        assert(token.balanceOf(mark) == _amountToMint);

    }

    function testCantMintWithNotOwner() public {
        uint256 _amountToMint = 100 ether;

        vm.startPrank(alice);

        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                alice
            )
        );

        token.mint(alice, _amountToMint);

        vm.stopPrank();
    }

    function testCantMintMoreThanMaxSupply() public {
        uint256 _amountToMint = 1;

        vm.startPrank(OWNER);

        vm.expectRevert(
            abi.encodeWithSelector(
                ERC20.ERC20CantMintMoreThanMaxSupply.selector
            )
        );

        token.mint(mark, _amountToMint);

        vm.stopPrank();
    }

    function testCantMintToAddressZero() public fund(alice, INITIAL_AMOUNT) {
        uint256 _amountToMint = 100 ether;
        uint256 _firstSupply = token.totalSupply();
        
        vm.startPrank(alice);

        token.burn(_amountToMint);

        vm.stopPrank();

        assert(token.totalSupply() == _firstSupply - _amountToMint);

        vm.startPrank(OWNER);

        vm.expectRevert(
            abi.encodeWithSelector(
                ERC20.ERC20InvalidReceiver.selector,
                address(0)
            )
        );

        token.mint(address(0), _amountToMint);

        vm.stopPrank();
    }

    function testName() public view {
        assert(keccak256(abi.encode(token.name())) == keccak256(abi.encode(NAME)));
    }

    function testSymbol() public view {
        assert(keccak256(abi.encode(token.symbol())) == keccak256(abi.encode(SYMBOL)));
    }

    function testDecimals() public view {
        assert(token.decimals() == 18);
    }

    function testPrintOwner() public view {
        console.log("Owner is: ", token.owner());
    }

}
