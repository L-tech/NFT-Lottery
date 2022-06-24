import { expect } from "chai";
import { ethers } from "hardhat";

describe("Test all cases for the NFTLottery", function () {
  it("It Should successfully deploy the contract", async function () {
    const NFTLottery = await ethers.getContractFactory("NftLottery");
    const nftLottery = await NFTLottery.deploy(100000000000000000, 50, 1460);
    await nftLottery.deployed();

    expect(await nftLottery.totalFee()).to.equal(0);
  });
});
