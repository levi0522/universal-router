// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {Constants} from '../libraries/Constants.sol';
import {PaymentsImmutables} from '../modules/PaymentsImmutables.sol';
import {SafeTransferLib} from 'solmate/src/utils/SafeTransferLib.sol';
import {ERC20} from 'solmate/src/tokens/ERC20.sol';
import {ERC721} from 'solmate/src/tokens/ERC721.sol';
import {ERC1155} from 'solmate/src/tokens/ERC1155.sol';
import {Fee} from '../modules/Fee.sol';

/// @title Payments contract
/// @notice Performs various operations around the payment of ETH and tokens
abstract contract Payments is PaymentsImmutables, Fee {
    using SafeTransferLib for ERC20;
    using SafeTransferLib for address;

    error InsufficientToken();
    error InsufficientETH();
    error InvalidBips();
    error InvalidSpender();
    error InvalidFeeType(uint256 feeType);

    uint256 internal constant FEE_BIPS_BASE = 10_000;

    /// @notice Pays an amount of ETH or ERC20 to a recipient
    /// @param token The token to pay (can be ETH using Constants.ETH)
    /// @param recipient The address that will receive the payment
    /// @param value The amount to pay
    function pay(address token, address recipient, uint256 value, bool isFee, uint8 feeType) internal {
        if (token == Constants.ETH) {
            if (!isFee) {
                recipient.safeTransferETH(value);
                return;
            }

            // Get the fee amount.
            // Note that the fee amount is rounded down in favor of the creator.
            uint256 feeAmount;
            if (feeType == 0) {
                if (FAST_TRADE_FEE_BPS == 0) {
                    ERC20(token).safeTransfer(recipient, value);
                    return;
                }
                feeAmount = (value * FAST_TRADE_FEE_BPS) / FEE_BASE_BPS;
            } else if (feeType == 1) {
                if (SNIPER_FEE_BPS == 0) {
                    ERC20(token).safeTransfer(recipient, value);
                    return;
                }
                feeAmount = (value * SNIPER_FEE_BPS) / FEE_BASE_BPS;
            } else if (feeType == 2) {
                if (LIMIT_FEE_BPS == 0) {
                    ERC20(token).safeTransfer(recipient, value);
                    return;
                }
                feeAmount = (value * LIMIT_FEE_BPS) / FEE_BASE_BPS;
            } else {
                revert InvalidFeeType(feeType);
            }

            uint256 payoutAmount;
            unchecked {
                payoutAmount = value - feeAmount;
            }

            // Transfer the fee amount to the fee recipient.
            if (feeAmount > 0) {
                FEE_RECIPIENT.safeTransferETH(feeAmount);
            }
            recipient.safeTransferETH(payoutAmount);
        } else {
            if (value == Constants.CONTRACT_BALANCE) {
                value = ERC20(token).balanceOf(address(this));
            }

            if (!isFee) {
                ERC20(token).safeTransfer(recipient, value);
                return;
            }

            // Get the fee amount.
            // Note that the fee amount is rounded down in favor of the creator.
            uint256 feeAmount;
            if (feeType == 0) {
                if (FAST_TRADE_FEE_BPS == 0) {
                    ERC20(token).safeTransfer(recipient, value);
                    return;
                }
                feeAmount = (value * FAST_TRADE_FEE_BPS) / FEE_BASE_BPS;
            } else if (feeType == 1) {
                if (SNIPER_FEE_BPS == 0) {
                    ERC20(token).safeTransfer(recipient, value);
                    return;
                }
                feeAmount = (value * SNIPER_FEE_BPS) / FEE_BASE_BPS;
            } else if (feeType == 2) {
                if (LIMIT_FEE_BPS == 0) {
                    ERC20(token).safeTransfer(recipient, value);
                    return;
                }
                feeAmount = (value * LIMIT_FEE_BPS) / FEE_BASE_BPS;
            } else {
                revert InvalidFeeType(feeType);
            }

            uint256 payoutAmount;
            unchecked {
                payoutAmount = value - feeAmount;
            }

            // Transfer the fee amount to the fee recipient.
            if (feeAmount > 0) {
                ERC20(token).safeTransfer(FEE_RECIPIENT, feeAmount);
            }

            ERC20(token).safeTransfer(recipient, payoutAmount);
        }
    }

    /// @notice Pays a proportion of the contract's ETH or ERC20 to a recipient
    /// @param token The token to pay (can be ETH using Constants.ETH)
    /// @param recipient The address that will receive payment
    /// @param bips Portion in bips of whole balance of the contract
    function payPortion(address token, address recipient, uint256 bips) internal {
        if (bips == 0 || bips > FEE_BIPS_BASE) revert InvalidBips();
        if (token == Constants.ETH) {
            uint256 balance = address(this).balance;
            uint256 amount = (balance * bips) / FEE_BIPS_BASE;
            recipient.safeTransferETH(amount);
        } else {
            uint256 balance = ERC20(token).balanceOf(address(this));
            uint256 amount = (balance * bips) / FEE_BIPS_BASE;
            ERC20(token).safeTransfer(recipient, amount);
        }
    }

    /// @notice Sweeps all of the contract's ERC20 or ETH to an address
    /// @param token The token to sweep (can be ETH using Constants.ETH)
    /// @param recipient The address that will receive payment
    /// @param amountMinimum The minimum desired amount
    function sweep(address token, address recipient, uint256 amountMinimum) internal {
        uint256 balance;
        if (token == Constants.ETH) {
            balance = address(this).balance;
            if (balance < amountMinimum) revert InsufficientETH();
            if (balance > 0) recipient.safeTransferETH(balance);
        } else {
            balance = ERC20(token).balanceOf(address(this));
            if (balance < amountMinimum) revert InsufficientToken();
            if (balance > 0) ERC20(token).safeTransfer(recipient, balance);
        }
    }

    /// @notice Wraps an amount of ETH into WETH
    /// @param recipient The recipient of the WETH
    /// @param amount The amount to wrap (can be CONTRACT_BALANCE)
    function wrapETH(address recipient, uint256 amount, bool isFee, uint8 feeType) internal {
        if (amount == Constants.CONTRACT_BALANCE) {
            amount = address(this).balance;
        } else if (amount > address(this).balance) {
            revert InsufficientETH();
        }
        if (amount > 0) {
            WETH9.deposit{value: amount}();
            if (recipient != address(this)) {
                if (!isFee) {
                    WETH9.transfer(recipient, amount);
                    return;
                }

                uint256 feeAmount;
                if (feeType == 0) {
                    if (FAST_TRADE_FEE_BPS == 0) {
                        WETH9.transfer(recipient, amount);
                        return;
                    }
                    feeAmount = (amount * FAST_TRADE_FEE_BPS) / FEE_BASE_BPS;
                } else if (feeType == 1) {
                    if (SNIPER_FEE_BPS == 0) {
                        WETH9.transfer(recipient, amount);
                        return;
                    }
                    feeAmount = (amount * SNIPER_FEE_BPS) / FEE_BASE_BPS;
                } else if (feeType == 2) {
                    if (LIMIT_FEE_BPS == 0) {
                        WETH9.transfer(recipient, amount);
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

                if (feeAmount > 0) {
                    WETH9.transfer(FEE_RECIPIENT, feeAmount);
                }

                WETH9.transfer(recipient, payoutAmount);
            }
        }
    }

    /// @notice Unwraps all of the contract's WETH into ETH
    /// @param recipient The recipient of the ETH
    /// @param amountMinimum The minimum amount of ETH desired
    function unwrapWETH9(address recipient, uint256 amountMinimum) internal {
        uint256 value = WETH9.balanceOf(address(this));
        if (value < amountMinimum) {
            revert InsufficientETH();
        }
        if (value > 0) {
            WETH9.withdraw(value);
            if (recipient != address(this)) {
                recipient.safeTransferETH(value);
            }
        }
    }
}
