// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseProvider/BaseLockDealProvider.sol";
import "poolz-helper-v2/contracts/ERC20Helper.sol";
import "./TimedProviderState.sol";

contract TimedLockDealProvider is ERC20Helper, TimedProviderState {
    constructor(address provider) {
        dealProvider = BaseLockDealProvider(provider);
    }

    function createNewPool(
        address owner,
        address token,
        uint256 amount,
        uint256 startTime,
        uint256 finishTime
    ) public returns (uint256 poolId) {
        require(
            finishTime >= startTime,
            "Finish time should be greater than start time"
        );
        poolId = dealProvider.createNewPool(owner, token, amount, startTime);
        poolIdToTimedDeal[poolId] = TimedDeal(finishTime, 0);
        if (
            !dealProvider.dealProvider().nftContract().approvedProviders(
                msg.sender
            )
        ) {
            TransferInToken(token, msg.sender, amount);
            emit NewPoolCreated(
                IDealProvierEvents.BasePoolInfo(poolId, owner),
                IDealProvierEvents.Deal(token, amount),
                startTime,
                finishTime
            );
        }
    }

    function withdraw(uint256 poolId) public returns (uint256 withdrawnAmount) {
        //if ((msg.sender == dealProvider.nftContract().ownerOf(poolId))) {}
        // Deal storage deal = itemIdToDeal[itemId];
        // TimedDeal storage timedDeal = poolIdToTimedDeal[itemId];
        // require(
        //     msg.sender == nftContract.ownerOf(itemId),
        //     "Not the owner of the item"
        // );
        // require(
        //     block.timestamp >= deal.startTime,
        //     "Withdrawal time not reached"
        // );
        // if (block.timestamp >= timedDeal.finishTime) {
        //     withdrawnAmount = deal.startAmount;
        // } else {
        //     uint256 elapsedTime = block.timestamp - deal.startTime;
        //     uint256 totalTime = timedDeal.finishTime - deal.startTime;
        //     uint256 availableAmount = (deal.startAmount * elapsedTime) /
        //         totalTime;
        //     withdrawnAmount = availableAmount - timedDeal.withdrawnAmount;
        // }
        // require(withdrawnAmount > 0, "No amount left to withdraw");
        // timedDeal.withdrawnAmount += withdrawnAmount;
    }

    function split(
        uint256 itemId,
        uint256 splitAmount,
        address newOwner
    ) public {
        //         Deal storage deal = itemIdToDeal[itemId];
        //         TimedDeal storage timedDeal = poolIdToTimedDeal[itemId];
        //         uint256 leftAmount = deal.startAmount - timedDeal.withdrawnAmount;
        //         require(
        //             leftAmount >= splitAmount,
        //             "Split amount exceeds the available amount"
        //         );
        //         uint256 ratio = (splitAmount * 10 ** 18) / leftAmount;
        //         uint256 newPoolDebitedAmount = (timedDeal.withdrawnAmount * ratio) /
        //             10 ** 18;
        //         uint256 newPoolStartAmount = (deal.startAmount * ratio) / 10 ** 18;
        //         deal.startAmount -= newPoolStartAmount;
        //         timedDeal.withdrawnAmount -= newPoolDebitedAmount;
        //         uint256 newPoolId = _createNewPool(
        //             newOwner,
        //             deal.token,
        //             GetParams(splitAmount, deal.startTime, timedDeal.finishTime)
        //         );
        //         emit PoolSplit(
        //             createBasePoolInfo(itemId, nftContract.ownerOf(itemId), deal.token),
        //             createBasePoolInfo(newPoolId, newOwner, deal.token),
        //             splitAmount
        //         );
        //     }
        //     function GetParams(
        //         uint256 amount,
        //         uint256 startTime,
        //         uint256 finishTime
        //     ) internal pure returns (uint256[] memory params) {
        //         params = new uint256[](3);
        //         params[0] = amount;
        //         params[1] = startTime;
        //         params[2] = finishTime;
        //     }
        //     function _createNewPool(
        //         address owner,
        //         address token,
        //         uint256[] memory params
        //     ) internal override validParams(params, 3) returns (uint256 newItemId) {
        //         // Assuming params[0] is amount, params[1] is startTime, params[2] is finishTime
        //         newItemId = super._createNewPool(
        //             owner,
        //             token,
        //             super.GetParams(params[0], params[1])
        //         );
        //         poolIdToTimedDeal[newItemId] = TimedDeal(params[2], 0);
    }
}
