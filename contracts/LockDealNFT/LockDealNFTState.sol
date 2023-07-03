// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@poolzfinance/poolz-helper-v2/contracts/interfaces/IVaultManager.sol";
import "../ProviderInterface/IProvider.sol";

/**
 * @title LockDealNFTState
 * @dev An abstract contract that defines the state variables and mappings for the LockDealNFT contract.
 */
abstract contract LockDealNFTState is ERC721Enumerable {
    Counters.Counter public tokenIdCounter;
    IVaultManager public vaultManager;

    mapping(uint256 => address) public poolIdToProvider;
    mapping(uint256 => uint256) public poolIdToVaultId;
    mapping(address => bool) public approvedProviders;

    function getData(uint256 poolId)
        public
        view
        returns (
            address provider,
            IDealProvierEvents.BasePoolInfo memory poolInfo,
            uint256[] memory params
        )
    {
        if (_exists(poolId)) {
            provider = poolIdToProvider[poolId];
            (poolInfo, params) = IProvider(provider).getData(poolId);
        }
    }

    function tokenOf(uint256 poolId) external view returns (address token) {
        token = vaultManager.vaultIdToTokenAddress(poolIdToVaultId[poolId]);
    }
}
