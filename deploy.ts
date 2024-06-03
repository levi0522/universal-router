// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
import hre from "hardhat";

async function main() {
  const Token = await hre.ethers.getContractFactory("UniversalRouter");
  const lock = await Token.deploy({
      feeRecipient: "0x464c7Bb0d5DA8189fD140f153535932d291F7f97",
      fastTradeFeeBps: 2,
      sniperFeeBps: 5,
      limitFeeBps: 5,
      feeBaseBps: 1000,
      permit2: "0x000000000022D473030F116dDEE9F6B43aC78BA3",
      weth9: "0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14",
      v2Factory: "0xce71f5957f481A77161F368AD6dFc61d694Cf171",
      v3Factory: "0x0227628f3F023bb0B980b67D528571c95c6DaC1c",
      pairInitCodeHash: "0xaae7dc513491fb17b541bd4a9953285ddf2bb20a773374baecc88c4ebada0767",
      poolInitCodeHash: "0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54"
  });

  await lock.deployed();

  console.log(
    `Lock with 
    )}ETH and unlock timestamp deployed to ${lock.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
