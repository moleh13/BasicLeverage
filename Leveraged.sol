// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract Leveraged {
    mapping(address => uint) public positions;
    address payable public LENDING;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function setLending(address payable _LENDING) public {
        require(msg.sender == owner);
        LENDING = _LENDING;
    }

    function addPosition(uint _amount, address _leverageUser) public {
        require(msg.sender == LENDING);
        positions[_leverageUser] += _amount;
    }

    receive() external payable {}
}