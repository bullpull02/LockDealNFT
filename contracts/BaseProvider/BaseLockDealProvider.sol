// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/IProvider.sol";
import "./BaseLockDealModifiers.sol";

contract BaseLockDealProvider is BaseLockDealModifiers, ERC20Helper, IProvider {
    constructor(address nft, address provider) {
        dealProvider = DealProvider(provider);
        lockDealNFT = LockDealNFT(nft);
    }

    /// params[0] = amount
    /// params[1] = startTime
    function createNewPool(
        address owner,
        address token,
        uint256[] memory params
    ) public returns (uint256 poolId) {
        poolId = lockDealNFT.mint(owner);
        _registerPool(poolId, params);
        if (!dealProvider.nftContract().approvedProviders(msg.sender)) {
            TransferInToken(token, msg.sender, params[0]);
        }
    }

    /// @dev no use of revert to make sure the loop will work
    function withdraw(
        uint256 poolId
    ) public override returns (uint256 withdrawnAmount) {
        if (startTimes[poolId] >= block.timestamp) {
            withdrawnAmount = dealProvider.withdraw(poolId);
        }
    }

    function split(
        uint256 oldPoolId,
        uint256 newPoolId,
        uint256 splitAmount
    ) public override onlyProvider {
        dealProvider.split(oldPoolId, newPoolId, splitAmount);
        startTimes[newPoolId] = startTimes[oldPoolId];
    }

    function registerPool(
        uint256 poolId,
        uint256[] memory params
    )
        public
        onlyProvider
        
    {
        _registerPool(poolId, params);
    }

    function _registerPool(
        uint256 poolId,
        uint256[] memory params
    ) internal validParamsLength(params.length, getParametersTargetLenght()) {
        startTimes[poolId] = params[1];
        dealProvider.registerPool(poolId, params);
    }

    function getParametersTargetLenght() public view returns (uint256) {
        return
            currentParamsTargetLenght +
            dealProvider.currentParamsTargetLenght();
    }
}
