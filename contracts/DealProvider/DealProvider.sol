// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";
import "./DealProviderModifiers.sol";
import "../Provider/BasicProvider.sol";

contract DealProvider is DealProviderModifiers, BasicProvider {
    constructor(address _nftContract) {
        require(_nftContract != address(0x0), "invalid address");
        lockDealNFT = LockDealNFT(_nftContract);
    }

    /// @dev use revert only for permissions
    function withdraw(
        uint256 poolId
    ) public override onlyNFT returns (uint256 withdrawnAmount, bool isFinal) {
        (withdrawnAmount, isFinal) = _withdraw(poolId, poolIdToDeal[poolId].leftAmount);
    }

    function _withdraw(
        uint256 poolId,
        uint256 amount
    ) internal override returns (uint256 withdrawnAmount, bool isFinal) {
        if (poolIdToDeal[poolId].leftAmount >= amount) {
            poolIdToDeal[poolId].leftAmount -= amount;
            withdrawnAmount = amount;
            isFinal = poolIdToDeal[poolId].leftAmount == 0;
            emit TokenWithdrawn(
                poolId,
                lockDealNFT.ownerOf(poolId),
                withdrawnAmount,
                poolIdToDeal[poolId].leftAmount
            );
        }
    }

    function split(
        uint256 oldPoolId,
        uint256 newPoolId,
        uint256 splitAmount
    )
        public
        override
        onlyProvider
        invalidSplitAmount(poolIdToDeal[oldPoolId].leftAmount, splitAmount)
    {
        poolIdToDeal[oldPoolId].leftAmount -= splitAmount;
        poolIdToDeal[newPoolId].leftAmount = splitAmount;
        poolIdToDeal[newPoolId].token = poolIdToDeal[oldPoolId].token;
        emit PoolSplit(
            oldPoolId,
            lockDealNFT.ownerOf(oldPoolId),
            newPoolId,
            lockDealNFT.ownerOf(newPoolId),
            poolIdToDeal[oldPoolId].leftAmount,
            poolIdToDeal[newPoolId].leftAmount
        );
    }

    ///@param params[0] = amount
    function _registerPool(
        uint256 poolId,
        address owner,
        address token,
        uint256[] memory params
    ) internal override validParamsLength(params.length, currentParamsTargetLenght) {
        poolIdToDeal[poolId].leftAmount = params[0];
        poolIdToDeal[poolId].token = token;
        emit NewPoolCreated(BasePoolInfo(poolId, owner, token), params);
    }

    function getData(uint256 poolId) external override view returns (BasePoolInfo memory poolInfo, uint256[] memory params) {
        address token = poolIdToDeal[poolId].token;
        uint256 leftAmount = poolIdToDeal[poolId].leftAmount;
        address owner = lockDealNFT.exist(poolId) ? lockDealNFT.ownerOf(poolId) : address(0);
        poolInfo = BasePoolInfo(poolId, owner, token);
        params = new uint256[](1);
        params[0] = leftAmount; // leftAmount
    }
}
