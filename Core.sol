// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./IERC20.sol";
import "./PriceOracle.sol";


contract Core {
    
    /* ========== CONSTANT VARIABLES ========== */

    address public BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    AggregatorV3Interface internal priceFeed;

    /* ========== STATE VARIABLES ========== */
    
    uint public lendedAmount;
    uint public borrowedAmount;
    uint public utilization;
    uint public exchangeRate;
    uint public lastUpdated;
    uint public totalhAmountLend;
    uint public totalhAmountBorrow;
    uint public BNBPrice;

    mapping(address => bool) public isLeveraged;
    mapping(address => uint) public hAmountByUser;
    mapping(address => uint) public borrowedhAmountByUser;
    mapping(address => uint) public totalLeveragedAmountByUser;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _BUSD, address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
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

        // update lended amount, borrowed amount, and utilization
        updateLendedAmountBorrowedAmountAndUtilization();
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

        // update lended amount, borrowed amount, and utilization
        updateLendedAmountBorrowedAmountAndUtilization();    
 
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
        uint BorrowedBUSDAMount = 2 * _amount * (getLatestPrice() / 1e8);
        
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

    function closePosition() public payable {
        // update exchange rate
        updateExchangeRate();

        // check if user is using leveraging 
        require(isLeveraged[msg.sender] == true);

        // kick him from leveraging
        isLeveraged[msg.sender] = false;

        // calculate remaining
        uint remainingBNB = calculateRemainingPrinciple();
        
        // set his position as 0
        totalLeveragedAmountByUser[msg.sender] = 0;

        // decrease total borrowing 
        totalhAmountBorrow -= borrowedhAmountByUser[msg.sender];

        // set his debt to 0
        borrowedhAmountByUser[msg.sender] = 0;

        // send his BNB
        bool sent = payable(msg.sender).send(remainingBNB);
        require(sent, "Failed to send BNB");

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

    function calculateRemainingPrinciple() public view returns (uint) {
        uint debt = (borrowedhAmountByUser[msg.sender] * exchangeRate) / 1e18;
        uint position = totalLeveragedAmountByUser[msg.sender] * (BNBPrice / 1e8);
        uint BNBAmount = (position - debt) / (BNBPrice / 1e8);
        return BNBAmount;
    }

    function getLatestPrice() public view returns (uint) {
        /*(
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRount
        ) = priceFeed.latestRoundData();
        // For ETH / USD price is scaled up by 1e8
        return uint(price);
        */
        return BNBPrice;
    }

    function setPriceOfBNB(uint _price) public {
        BNBPrice = _price * 1e8;
    }

    function sendBNB() public payable {}
}