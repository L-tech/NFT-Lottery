// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";
const ticketFee = ethers.BigNumber.from("0.1").mul(
  ethers.BigNumber.from(10).pow(18)
);
const maxPlayers = 50;
const subscriptionId = 1460;

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  const constructorArgs = [ticketFee, maxPlayers, subscriptionId];

  // We get the contract to deploy
  const NFTLottery = await ethers.getContractFactory("NftLottery");
  const nftLottery = await NFTLottery.deploy(...constructorArgs);

  await nftLottery.deployed();
  //   await hre.run("verify:verify", {
  //     address: "0x006089929469ec0489a143C0d71f52C7d0201CCf",
  //     constructorArguments: constructorArgs,
  //   });

  console.log("Greeter deployed to:", nftLottery.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
