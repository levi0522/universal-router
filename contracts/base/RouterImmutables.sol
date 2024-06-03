// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

struct RouterParameters {
    address feeRecipient;
    uint256 fastTradeFeeBps;
    uint256 sniperFeeBps;
    uint256 limitFeeBps;
    uint256 feeBaseBps;
    address permit2;
    address weth9;
    address v2Factory;
    address v3Factory;
    bytes32 pairInitCodeHash;
    bytes32 poolInitCodeHash;
}
