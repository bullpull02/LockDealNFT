// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";

/// @title DealProviderState contract
/// @notice Contains storage variables, structures
contract DealProviderState {
    LockDealNFT public nftContract;
    mapping(uint256 => Deal) public poolIdToDeal;
    mapping(address => bool) public providers;

    struct Deal {
        address token;
        uint256 startAmount;
    }
}
