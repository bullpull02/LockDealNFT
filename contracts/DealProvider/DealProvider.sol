// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";
import "poolz-helper-v2/contracts/ERC20Helper.sol";
import "./DealProviderModifiers.sol";
import "./IDealProvierEvents.sol";

abstract contract DealProvider is
    IDealProvierEvents,
    DealProviderModifiers,
    ERC20Helper,
    Ownable
{
    constructor(address _nftContract) {
        nftContract = LockDealNFT(_nftContract);
    }

    function createNewPool(
        address owner,
        address token,
        uint256[] memory params
    ) public validParams(msg.sender, 1) returns (uint256 newPoolId) {
        newPoolId = nftContract.totalSupply();
        poolIdToDeal[newPoolId] = Deal(token, params[0]);
        nftContract.mint(owner);
    }

    /// @dev no use of revert to make sure the loop will work
    function withdraw(
        uint256 poolId,
        uint256 withdrawalAmount
    ) public returns (uint256) {
        if (
            withdrawalAmount > 0 &&
            providers[msg.sender].status &&
            withdrawalAmount <= poolIdToDeal[poolId].startAmount
        ) {
            poolIdToDeal[poolId].startAmount -= withdrawalAmount;
            TransferToken(
                poolIdToDeal[poolId].token,
                nftContract.ownerOf(poolId),
                withdrawalAmount
            );
            emit TokenWithdrawn(
                createBasePoolInfo(
                    poolId,
                    nftContract.ownerOf(poolId),
                    poolIdToDeal[poolId].token
                ),
                withdrawalAmount,
                poolIdToDeal[poolId].startAmount
            );
            return withdrawalAmount;
        }
    }

    function getDeal(uint256 poolId) public view returns (address, uint256) {
        return (poolIdToDeal[poolId].token, poolIdToDeal[poolId].startAmount);
    }

    function createBasePoolInfo(
        uint256 poolId,
        address owner,
        address token
    ) internal pure returns (BasePoolInfo memory poolInfo) {
        poolInfo.PoolId = poolId;
        poolInfo.Owner = owner;
        poolInfo.Token = token;
    }

    function setProviderSettings(
        address provider,
        uint256 paramsLength,
        bool status
    ) external onlyOwner {
        providers[provider].status = status;
        providers[provider].paramsLength = paramsLength;
    }
}
