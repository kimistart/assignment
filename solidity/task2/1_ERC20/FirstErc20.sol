// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract FirstERC20 {

    mapping(address=>uint) public balanceOf; //账户余额
    mapping(address=>mapping(address=>uint)) public allowance;
    uint public totalSupply;

    string public name;
    string public symbol;
    uint public decimals = 18;

    event Transfer(address sender,address to,uint amount);
    event Approval(address sender,address spender,uint amount);

    constructor(string memory _name,string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    //代币转账
    function transfer(address recipient,uint amount) public returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender,recipient, amount);
        return true;
    }

    //代币授权
    function approve(address spender,uint amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender,spender,amount);
        return true;
    }

    //授权转账
    /**
    **sender：授权方  recipient：接收方  msg.sender：被授权方
    **/
    function transferFrom(address sender,address recipient,uint amount) public returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(uint amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }
}