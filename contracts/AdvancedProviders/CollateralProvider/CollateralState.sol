// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../SimpleProviders/LockProvider/LockDealState.sol";

abstract contract CollateralState is LockDealState {
    function getParams(uint256 poolId) public view override returns (uint256[] memory params) {
        (, , uint256 mainCoinHolderId) = getInnerIds(poolId);
        if (lockDealNFT.exist(mainCoinHolderId)) {
            params = new uint256[](2);
            params[0] = provider.getParams(mainCoinHolderId)[0];
            params[1] = poolIdToTime[poolId];
        }
    }

    function currentParamsTargetLenght() public pure override(IProvider, ProviderState) returns (uint256) {
        return 2;
    }

    function getInnerIds(
        uint256 poolId
    ) internal pure returns (uint256 mainCoinCollectorId, uint256 tokenHolderId, uint256 mainCoinHolderId) {
        mainCoinCollectorId = poolId + 1;
        tokenHolderId = poolId + 2;
        mainCoinHolderId = poolId + 3;
    }

    function getWithdrawableAmount(uint256 poolId) public view override returns (uint256 withdrawalAmount) {
        if (lockDealNFT.poolIdToProvider(poolId) == this) {
            (uint256 mainCoinCollectorId, , uint256 mainCoinHolderId) = getInnerIds(poolId);
            withdrawalAmount = lockDealNFT.getWithdrawableAmount(mainCoinCollectorId);
            if (poolIdToTime[poolId] <= block.timestamp) {
                withdrawalAmount += lockDealNFT.getWithdrawableAmount(mainCoinHolderId);
            }
        }
    }
}
