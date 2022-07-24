// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./Leveraged.sol";

contract Lending is Leveraged {
    mapping(address => uint) public balances;
    mapping(address => uint) public debts;
    uint public utilization;
    uint public ETH_PRICE = 1200;
    address payable public LEVERAGED;

    constructor(address payable _LEVERAGED) {
        LEVERAGED = _LEVERAGED;
    }

    function lend(uint _amount) public payable {
        require(msg.value == _amount);
        balances[msg.sender] += _amount;
    }

    function withdraw(uint _amount) public payable {
        require(balances[msg.sender] >= _amount);
        bool sent = payable(msg.sender).send(_amount);
        require(sent, "Failed to send Ether");
    }

    function leverageMe(uint _amount) public payable {
        require(msg.value == _amount);
        uint debtAmount = _amount * 2 * ETH_PRICE;
        debts[msg.sender] += debtAmount;
        // Here will be the function that converts 2400 USDT to 2 ETH in 1inch.
        bool sent = LEVERAGED.send(_amount * 3);
        require(sent, "Failed to send Ether");
        Leveraged.addPosition(_amount * 3, msg.sender);
    }
}