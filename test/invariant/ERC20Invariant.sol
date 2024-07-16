// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";
import { CommonBase } from "forge-std/Base.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { StdUtils } from "forge-std/StdUtils.sol";

import { ERC20 } from "../../src/ERC20.sol";

contract Handler is CommonBase, StdCheats, StdUtils {
    ERC20 private token;
    string public constant NAME = "Kyber Network Crystal";
    string public constant SYMBOL = "KNC";

    constructor(ERC20 _token) {
        token = _token;
    }

    function mint(address _to, uint256 _value) public {
        if (token.owner() == address(this))
            token.mint(_to, _value);
    }


    function burn(uint256 _amount) public {
        _amount = bound(_amount, 0, token.balanceOf(address(this)));
        token.burn(_amount);
    }

    function transfer(address _to, uint256 _amount) public {
        if (_to == address(0)) {
            return;
        }
        _amount = bound(_amount, 0, token.balanceOf(address(this)));
        token.transfer(_to, _amount);
    }

    function transferFrom(address _from, address _to, uint256 _amount) public {
        if (_from == address(0) || _to == address(0)){
            return;
        }
        _amount = bound(_amount, 0, token.allowance(_from, address(this)));
        token.transferFrom(_from, _to, _amount);
    }

    function approve(address _spender, uint256 _amount) public {
        token.approve(_spender, _amount);
    }

}

contract ActorManager is CommonBase, StdCheats, StdUtils{ 
    Handler[] public handlers;

    constructor (Handler[] memory _handlers) {
        handlers = _handlers;
    }

    function mint(uint256 _handlerIndex, address _to, uint256 _amount) public {
        uint256 _index = bound(_handlerIndex, 0, handlers.length - 1);
        handlers[_index].mint(_to, _amount);
    }

    function burn(uint256 _handlerIndex, uint256 _amount) public {
        uint256 _index = bound(_handlerIndex, 0, handlers.length - 1);
        handlers[_index].burn(_amount);
    }

    function transfer(uint256 _handlerIndex, address _to, uint256 _amount) public {
        uint256 _index = bound(_handlerIndex, 0, handlers.length - 1);
        handlers[_index].transfer(_to, _amount);
    }

    function transferFrom(uint256 _handlerIndex, address _from, address _to, uint256 _amount) public {
        uint256 _index = bound(_handlerIndex, 0, handlers.length - 1);
        handlers[_index].transferFrom(_from, _to, _amount);
    }

    function approve(uint256 _handlerIndex, address _spender, uint256 _amount) public {
        uint256 _index = bound(_handlerIndex, 0, handlers.length - 1);
        handlers[_index].approve(_spender, _amount);
    }
}

contract testERC20_Invariant_Tests is Test {
    ERC20 public token;
    Handler[] public handlers;
    ActorManager public manager;

    string public constant NAME = "Kyber Network Crystal";
    string public constant SYMBOL = "KNC";
    uint256 public constant INITIAL_AMOUNT = 100000 ether;

    function setUp() external {
        token = new ERC20(NAME, SYMBOL);

        for (uint i = 0; i < 3; i++) {
            Handler handler = new Handler(token);
            handlers.push(handler);
            token.transfer(address(handler), INITIAL_AMOUNT);
        }

        token.transferOwnership(address(handlers[0]));
        manager = new ActorManager(handlers);

        targetContract(address(manager));
    }

    function invariant_not_exceed_supply() public view {
        assert(token.totalSupply() <= token.getMaxSupply());
    }



}