// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {IWETH9} from '../interfaces/external/IWETH9.sol';
import {IAllowanceTransfer} from 'permit2/src/interfaces/IAllowanceTransfer.sol';

struct FeeParameters {
    address feeRecipient;

    uint256 fastTradeFeeBps;

    uint256 sniperFeeBps;

    uint256 limitFeeBps;

    uint256 feeBaseBps;
}

contract Fee {
    /// @dev fee recipient address
    address internal FEE_RECIPIENT;

    /// @dev fee bps
    uint256 internal FAST_TRADE_FEE_BPS;

    uint256 internal SNIPER_FEE_BPS;

    uint256 internal LIMIT_FEE_BPS;

    /// @dev fee base
    uint256 internal FEE_BASE_BPS;

    constructor(FeeParameters memory params) {
        FEE_RECIPIENT = params.feeRecipient;
        FAST_TRADE_FEE_BPS = params.fastTradeFeeBps;
        SNIPER_FEE_BPS = params.sniperFeeBps;
        LIMIT_FEE_BPS = params.limitFeeBps;
        FEE_BASE_BPS = params.feeBaseBps;
    }
}
