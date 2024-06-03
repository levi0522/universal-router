pragma solidity ^0.8.17;

import {IAllowanceTransfer} from 'permit2/src/interfaces/IAllowanceTransfer.sol';
import {SafeCast160} from 'permit2/src/libraries/SafeCast160.sol';
import {Payments} from './Payments.sol';
import {Constants} from '../libraries/Constants.sol';

/// @title Payments through Permit2
/// @notice Performs interactions with Permit2 to transfer tokens
abstract contract Permit2Payments is Payments {
    using SafeCast160 for uint256;

    error FromAddressIsNotOwner();

    /// @notice Performs a transferFrom on Permit2
    function permit2TransferFrom(address token, address from, address to, uint256 amount, bool isFee, uint8 feeType) internal {
        if (!isFee) {
            PERMIT2.transferFrom(from, to, amount.toUint160(), token);
            return;
        }
        // Get the fee amount.
        // Note that the fee amount is rounded down in favor of the creator.
        uint256 feeAmount;
        if (feeType == 0) {
            if (FAST_TRADE_FEE_BPS == 0) {
                PERMIT2.transferFrom(from, to, amount.toUint160(), token);
                return;
            }
            feeAmount = (amount * FAST_TRADE_FEE_BPS) / FEE_BASE_BPS;
        } else if (feeType == 1) {
            if (SNIPER_FEE_BPS == 0) {
                PERMIT2.transferFrom(from, to, amount.toUint160(), token);
                return;
            }
            feeAmount = (amount * SNIPER_FEE_BPS) / FEE_BASE_BPS;
        } else if (feeType == 2) {
            if (LIMIT_FEE_BPS == 0) {
                PERMIT2.transferFrom(from, to, amount.toUint160(), token);
                return;
            }
            feeAmount = (amount * LIMIT_FEE_BPS) / FEE_BASE_BPS;
        } else {
            revert InvalidFeeType(feeType);
        }
        uint256 payoutAmount;
        unchecked {
            payoutAmount = amount - feeAmount;
        }
        // Transfer the fee amount to the fee recipient.
        if (feeAmount > 0) {
            PERMIT2.transferFrom(from, FEE_RECIPIENT, feeAmount.toUint160(), token);
        }
        PERMIT2.transferFrom(from, to, payoutAmount.toUint160(), token);
    }

    /// @notice Performs a batch transferFrom on Permit2
    /// @param batchDetails An array detailing each of the transfers that should occur
    function permit2TransferFrom(
        IAllowanceTransfer.AllowanceTransferDetails[] memory batchDetails,
        address owner
    ) internal {
        uint256 batchLength = batchDetails.length;
        for (uint256 i = 0; i < batchLength; ++i) {
            if (batchDetails[i].from != owner) revert FromAddressIsNotOwner();
        }
        PERMIT2.transferFrom(batchDetails);
    }

    /// @notice Either performs a regular payment or transferFrom on Permit2, depending on the payer address
    /// @param token The token to transfer
    /// @param payer The address to pay for the transfer
    /// @param recipient The recipient of the transfer
    /// @param amount The amount to transfer
    function payOrPermit2Transfer(
        address token,
        address payer,
        address recipient,
        uint256 amount,
        bool isFee,
        uint8 feeType
    ) internal {
        if (payer == address(this)) pay(token, recipient, amount, isFee, feeType);
        else permit2TransferFrom(token, payer, recipient, amount, isFee, feeType);
    }
}
