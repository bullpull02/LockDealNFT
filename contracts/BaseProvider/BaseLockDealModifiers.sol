// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseLockDealState.sol";

contract BaseLockDealModifiers is BaseLockDealState {
    modifier validParamsLength(uint256 paramsLength, uint256 minLength) {
        _validParamsLength(paramsLength, minLength);
        _;
    }

    modifier onlyProvider() {
        _onlyProvider();
        _;
    }

    modifier onlyNFT() {
        _onlyNFT();
        _;
    }

    function _onlyNFT() internal view {
        require(
            msg.sender == address(lockDealNFT),
            "only NFT contract can call this function"
        );
    }

    function _validParamsLength(
        uint256 paramsLength,
        uint256 minLength
    ) private pure {
        require(paramsLength >= minLength, "invalid params length");
    }

    function _onlyProvider() private view {
        require(
            dealProvider.lockDealNFT().approvedProviders(msg.sender),
            "invalid provider address"
        );
    }
}
