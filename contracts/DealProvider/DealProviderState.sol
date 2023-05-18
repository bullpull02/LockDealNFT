// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";
import "./IDealProvierEvents.sol";

/// @title DealProviderState contract
/// @notice Contains storage variables, structures
contract DealProviderState is IDealProvierEvents {
    LockDealNFT public nftContract;
    mapping(uint256 => Deal) public poolIdToDeal;
}
