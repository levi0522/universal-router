// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

import {Constants} from '../libraries/Constants.sol';
import {RouterImmutables} from '../base/RouterImmutables.sol';
import {SafeTransferLib} from 'solmate/utils/SafeTransferLib.sol';
import {ERC20} from 'solmate/tokens/ERC20.sol';
import {ERC721} from 'solmate/tokens/ERC721.sol';
import {ERC1155} from 'solmate/tokens/ERC1155.sol';

abstract contract Payments is RouterImmutables {
    using SafeTransferLib for ERC20;
    using SafeTransferLib for address;

    error InsufficientToken();
    error InsufficientETH();
    error InvalidBips();

    uint256 internal constant FEE_BIPS_BASE = 10_000;

    /// @param token The token to pay (can be ETH using Constants.ETH)
    /// @param recipient The entity that will receive payment
    /// @param value The amount to pay
    function pay(address token, address recipient, uint256 value) internal {
        if (token == Constants.ETH) {
            recipient.safeTransferETH(value);
        } else {
            if (value == Constants.CONTRACT_BALANCE) {
                value = ERC20(token).balanceOf(address(this));
            }

            // pay with tokens already in the contract (for the exact input multihop case)
            ERC20(token).safeTransfer(recipient, value);
        }
    }

    /// @param token The token to pay (can be ETH using Constants.ETH)
    /// @param recipient The entity that will receive payment
    /// @param bips Portion in bips of whole balance of the contract
    function payPortion(address token, address recipient, uint256 bips) internal {
        if (bips == 0 || bips > 10_000) revert InvalidBips();
        if (token == Constants.ETH) {
            uint256 balance = address(this).balance;
            uint256 amount = (balance * bips) / FEE_BIPS_BASE;
            recipient.safeTransferETH(amount);
        } else {
            uint256 balance = ERC20(token).balanceOf(address(this));
            uint256 amount = (balance * bips) / FEE_BIPS_BASE;
            // pay with tokens already in the contract (for the exact input multihop case)
            ERC20(token).safeTransfer(recipient, amount);
        }
    }

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

    function sweepERC721(address token, address recipient, uint256 id) internal {
        ERC721(token).safeTransferFrom(address(this), recipient, id);
    }

    function sweepERC1155(address token, address recipient, uint256 id, uint256 amountMinimum) internal {
        uint256 balance = ERC1155(token).balanceOf(address(this), id);
        if (balance < amountMinimum) revert InsufficientToken();
        ERC1155(token).safeTransferFrom(address(this), recipient, id, balance, bytes(''));
    }

    function wrapETH(address recipient, uint256 amount) internal {
        if (amount == Constants.CONTRACT_BALANCE) {
            amount = address(this).balance;
        } else if (amount > address(this).balance) {
            revert InsufficientETH();
        }
        if (amount > 0) {
            WETH9.deposit{value: amount}();
            WETH9.transfer(recipient, amount);
        }
    }

    function unwrapWETH9(address recipient, uint256 amountMinimum) internal {
        uint256 value = WETH9.balanceOf(address(this));
        if (value < amountMinimum) {
            revert InsufficientETH();
        }
        if (value > 0) {
            WETH9.withdraw(value);
            recipient.safeTransferETH(value);
        }
    }
}
