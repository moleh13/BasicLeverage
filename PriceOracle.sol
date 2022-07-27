// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface AggregatorV3Interface {
    function latestRoundData()
    external
    view
    returns (
        uint80 roundId,
        int answer,
        uint startedAt,
        uint updatedAt,
        uint80 answeredInRound
    );
}