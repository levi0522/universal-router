// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

// Command implementations
import {Dispatcher} from './base/Dispatcher.sol';
import {RouterParameters} from './base/RouterImmutables.sol';
import {PaymentsImmutables, PaymentsParameters} from './modules/PaymentsImmutables.sol';
import {UniswapImmutables, UniswapParameters} from './modules/uniswap/UniswapImmutables.sol';
import {Commands} from './libraries/Commands.sol';
import {IUniversalRouter} from './interfaces/IUniversalRouter.sol';
import {Ownable} from 'permit2/lib/openzeppelin-contracts/contracts/access/Ownable.sol';
import {Fee, FeeParameters} from './modules/Fee.sol';

contract UniversalRouter is IUniversalRouter, Dispatcher, Ownable {

    event FeeRecipientUpdated(address indexed msgSender, address feeRecipient);
    event FastTradeFeeBpsUpdated(address indexed msgSender, uint256 fastTradeFeeBps);
    event SniperFeeBpsUpdated(address indexed msgSender, uint256 sniperFeeBps);
    event LimitFeeBpsUpdated(address indexed msgSender, uint256 limitFeeBps);
    event FeeBaseBpsUpdated(address indexed msgSender, uint256 feeBaseBps);

    error InvalidFastTradeFeeBps(uint256 fastTradeFeeBps);
    error InvalidSniperFeeBps(uint256 sniperFeeBps);
    error InvalidLimitFeeBps(uint256 limitFeeBps);
    error InvalidFeeBase(uint256 feeBase);
    error FeeRecipientAddressCannotBeZeroAddress();
    error FeeRecipientAddressCannotBeZeroAddress1();

    modifier checkDeadline(uint256 deadline) {
        if (block.timestamp > deadline) revert TransactionDeadlinePassed();
        _;
    }

    constructor(RouterParameters memory params)
        UniswapImmutables(
            UniswapParameters(params.v2Factory, params.v3Factory, params.pairInitCodeHash, params.poolInitCodeHash)
        )
        PaymentsImmutables(PaymentsParameters(params.permit2, params.weth9))
        Fee(FeeParameters(params.feeRecipient, params.fastTradeFeeBps, params.sniperFeeBps, params.limitFeeBps, params.feeBaseBps))
    {}

    /// @inheritdoc IUniversalRouter
    function execute(bytes calldata commands, bytes[] calldata inputs, uint256 deadline)
        external
        payable
        checkDeadline(deadline)
    {
        execute(commands, inputs);
    }

    /// @inheritdoc Dispatcher
    function execute(bytes calldata commands, bytes[] calldata inputs) public payable override isNotLocked {
        bool success;
        bytes memory output;
        uint256 numCommands = commands.length;
        if (inputs.length != numCommands) revert LengthMismatch();

        // loop through all given commands, execute them and pass along outputs as defined
        for (uint256 commandIndex = 0; commandIndex < numCommands;) {
            bytes1 command = commands[commandIndex];

            bytes calldata input = inputs[commandIndex];

            (success, output) = dispatch(command, input);

            if (!success && successRequired(command)) {
                revert ExecutionFailed({commandIndex: commandIndex, message: output});
            }

            unchecked {
                commandIndex++;
            }
        }
    }

    function successRequired(bytes1 command) internal pure returns (bool) {
        return command & Commands.FLAG_ALLOW_REVERT == 0;
    }

    function feeRecipient() external view returns (address) {
        return FEE_RECIPIENT;
    }

    function fastTradeFeeBps() external view returns (uint256) {
        return FAST_TRADE_FEE_BPS;
    }

    function sniperFeeBps() external view returns (uint256) {
        return SNIPER_FEE_BPS;
    }

    function limitFeeBps() external view returns (uint256) {
        return LIMIT_FEE_BPS;
    }

    function feeBaseBps() external view returns (uint256) {
        return FEE_BASE_BPS;
    }

    function setFeeRecipient(address feeRecipient) external onlyOwner {
        if (feeRecipient == address(0)) {
            revert FeeRecipientAddressCannotBeZeroAddress();
        }
        FEE_RECIPIENT = feeRecipient;
         emit FeeRecipientUpdated(msg.sender, feeRecipient);
    }

    function setFastTradeFeeBps(uint256 feeBps) external onlyOwner {
        if (feeBps > FEE_BASE_BPS) {
            revert InvalidFastTradeFeeBps(feeBps);
        }
        FAST_TRADE_FEE_BPS = feeBps;
        emit FastTradeFeeBpsUpdated(msg.sender, feeBps);
    }

    function setSniperFeeBps(uint256 feeBps) external onlyOwner {
        if (feeBps > FEE_BASE_BPS) {
            revert InvalidSniperFeeBps(feeBps);
        }
        SNIPER_FEE_BPS = feeBps;
        emit SniperFeeBpsUpdated(msg.sender, feeBps);
    }

    function setLimitFeeBps(uint256 feeBps) external onlyOwner {
        if (feeBps > FEE_BASE_BPS) {
            revert InvalidSniperFeeBps(feeBps);
        }
        LIMIT_FEE_BPS = feeBps;
        emit SniperFeeBpsUpdated(msg.sender, feeBps);
    }

     function setFeeBaseBps(uint256 feeBaseBps) external onlyOwner {
        if (feeBaseBps < FAST_TRADE_FEE_BPS && feeBaseBps < SNIPER_FEE_BPS && feeBaseBps < LIMIT_FEE_BPS) {
            revert InvalidFeeBase(feeBaseBps);
        }
        FEE_BASE_BPS = feeBaseBps;
         emit FeeBaseBpsUpdated(msg.sender, feeBaseBps);
    }

    /// @notice To receive ETH from WETH and NFT protocols
    receive() external payable {}
}
