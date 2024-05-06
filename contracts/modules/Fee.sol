// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {IWETH9} from '../interfaces/external/IWETH9.sol';
import {IAllowanceTransfer} from 'permit2/src/interfaces/IAllowanceTransfer.sol';

struct FeeParameters {
    address feeRecipient;

    uint256 feeBps;

    uint256 feeBpsBase;
}

contract Fee {
    /// @dev fee recipient address
    address internal FEE_RECIPIENT;

    /// @dev fee bps
    uint256 internal FEE_BPS;

    /// @dev fee base
    uint256 internal FEE_BPS_BASE;

    constructor(FeeParameters memory params) {
        FEE_RECIPIENT = params.feeRecipient;
        FEE_BPS = params.feeBps;
        FEE_BPS_BASE = params.feeBpsBase;
    }
}
