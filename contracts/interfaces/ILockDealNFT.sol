// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IProvider.sol";
import  "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ILockDealNFT is IERC721Enumerable {
    function split(
        uint256 poolId,
        uint256 ratio,
        address newOwner
    ) external returns (uint256 newPoolId, bool isFinal);
    function approvedProviders(address provider) external view returns (bool);
    function mintAndTransfer(
        address owner,
        address token,
        address from,
        uint256 amount,
        IProvider provider
    ) external returns (uint256 poolId);
    function copyVaultId(uint256 fromPoolId, uint256 toPoolId) external;
    function mintForProvider(address owner, IProvider provider) external returns (uint256 poolId);
    function withdrawFromProvider(address from, uint256 poolId) external;
    function transferFromProvider(address from, uint256 poolId) external;
    function getData(uint256 poolId) external view returns (BasePoolInfo memory poolInfo);
    function updateProviderMetadata(uint256 poolId) external;
    function tokenOf(uint256 poolId) external view returns (address token);
    function exist(uint256 poolId) external view returns (bool);
    function poolIdToProvider(uint256 poolId) external view returns (IProvider provider);
    function getWithdrawableAmount(uint256 poolId) external view returns (uint256 withdrawalAmount);

    struct BasePoolInfo {
        IProvider provider;
        uint256 poolId;
        uint256 vaultId;
        address owner;
        address token;
        uint256[] params;
    }
}
