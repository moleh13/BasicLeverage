// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./IERC20.sol";

contract Core {
    
    /* ========== CONSTANT VARIABLES ========== */

    address public BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    /* ========== STATE VARIABLES ========== */
    
    uint public lendedAmount;
    uint public borrowedAmount;
    uint public utilization;
    uint public exchangeRate;
    uint public lastUpdated;
    uint public totalhAmountLend;
    uint public totalhAmountBorrow;

    mapping(address => bool) public isLeveraged;
    mapping(address => uint) public hAmountByUser;
    mapping(address => uint) public borrowedhAmountByUser;
    mapping(address => uint) public totalLeveragedAmountByUser;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _BUSD) {
        exchangeRate = 1e18; // 1.00
        lastUpdated = block.timestamp;
        BUSD = _BUSD;
    }

    /* ========== LENDER ========== */

    function lend(uint _amount) public {
        // update exchange rate
        updateExchangeRate();

        // transfer BUSD from user to core contract
        IERC20(BUSD).transferFrom(msg.sender, address(this), _amount);

        // increase hAmount of user
        uint hAmount = (_amount * 1e18) / exchangeRate;
        hAmountByUser[msg.sender] += hAmount;

        // increase total hAmount
        totalhAmountLend += hAmount;

        // update lended / borrowed amount
        lendedAmount = (totalhAmountLend * exchangeRate) / 1e18;
        borrowedAmount = (totalhAmountBorrow * exchangeRate) / 1e18;

        // update utilization after lending
        utilization = (borrowedAmount / lendedAmount) * 1e18;
    }

    function withdraw(uint _amount) public {
        // update exchange rate
        updateExchangeRate();

        // check if the user has enough amount
        uint lendedAmountOfUser = (hAmountByUser[msg.sender] * exchangeRate) / 1e18;
        require(_amount <= lendedAmountOfUser, "There is no enough lended amount by user");
        
        // decrease hAmount of user
        uint hAmount = (_amount * 1e18) / exchangeRate;
        hAmountByUser[msg.sender] -= hAmount;

        // send BUSD from contract to user
        IERC20(BUSD).transfer(msg.sender, _amount);

        // decrease total hAmount
        totalhAmountLend -= hAmount;

        // update lended / borrowed amount
        lendedAmount = (totalhAmountLend * exchangeRate) / 1e18;
        borrowedAmount = (totalhAmountBorrow * exchangeRate) / 1e18;

        // update utilization after withdrawing
        utilization = (borrowedAmount / lendedAmount) * 1e18;       
    }
    /* ========== LEVERAGER ========== */

    function openPosition(uint _amount) public payable {
        // update exchange rate
        updateExchangeRate();

        // check if he sends correct msg.value amount
        require(msg.value == _amount, "You have to send BNB as amount you have entered");

        // update statement of the user
        isLeveraged[msg.sender] = true;

        // calculate BUSD amount
        uint BorrowedBUSDAMount = 2 * _amount * (getPriceOfBNB() / 1e8);
        
        // trade BUSD with BNB
        trade(BorrowedBUSDAMount);

        // increase borrowed hAmount
        uint hAmount = (BorrowedBUSDAMount * 1e18) / exchangeRate;
        totalhAmountBorrow += hAmount;

        // increase borrowed hAmount of user
        borrowedhAmountByUser[msg.sender] += hAmount;

        // update leveraged amount of user
        totalLeveragedAmountByUser[msg.sender] += _amount * 3;

        // update lended amount, borrowed amount, and utilization
        updateLendedAmountBorrowedAmountAndUtilization();
    }



    /* ========== HELPERS ========== */

    function updateExchangeRate() public {
        uint interestRate = utilization;
        uint interestRatePerSecond = interestRate / 31536000;
        uint passedTimed = block.timestamp - lastUpdated;
        lastUpdated = block.timestamp;
        exchangeRate += interestRatePerSecond * passedTimed;
    }

    function updateLendedAmountBorrowedAmountAndUtilization() public {
        lendedAmount = (totalhAmountLend * exchangeRate) / 1e18;
        borrowedAmount = (totalhAmountBorrow * exchangeRate) / 1e18;
        utilization = (borrowedAmount * 1e18) / lendedAmount ;
    }

    function trade(uint _amount) public {

    }

    function getPriceOfBNB() public pure returns (uint) {
        return 300 * 1e8;
    }

    function sendBNB() public payable {}
}