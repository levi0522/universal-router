// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {DeployUniversalRouter} from '../DeployUniversalRouter.s.sol';
import {RouterParameters} from 'contracts/base/RouterImmutables.sol';

contract DeploySepolia is DeployUniversalRouter {
    function setUp() public override {
        params = RouterParameters({
            feeRecipient: 0x464c7Bb0d5DA8189fD140f153535932d291F7f97,
            feeBps: 5,
            feeBaseBps: 10000,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            weth9: 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14,
            v2Factory: 0xce71f5957f481A77161F368AD6dFc61d694Cf171,
            v3Factory: 0x0227628f3F023bb0B980b67D528571c95c6DaC1c,
            pairInitCodeHash: 0xaae7dc513491fb17b541bd4a9953285ddf2bb20a773374baecc88c4ebada0767,
            poolInitCodeHash: 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54
        });

        unsupported = 0x5302086A3a25d473aAbBd0356eFf8Dd811a4d89B;
    }
}
