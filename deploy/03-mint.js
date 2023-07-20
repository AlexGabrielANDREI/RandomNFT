const { network, ethers } = require("hardhat");

module.exports = async ({ getNamedAccounts }) => {
  const { deployer } = await getNamedAccounts();
  const chainId = network.config.chainId;
  // Random NFT
  const randomNft = await ethers.getContract("RandomNFT", deployer);
  const mintFee = await randomNft.getMintFee();
  //console.log(mintFee.toString());
  const randomNftMintTx = await randomNft.requestNft({
    value: mintFee.toString(),
  });
  const randomNftMintTxReceipt = await randomNftMintTx.wait(1);
  console.log(randomNftMintTxReceipt);

  const requestId = randomNftMintTxReceipt.events[1].args.requestId.toString();
  const vrfCoordinatorV2Mock = await ethers.getContract(
    "VRFCoordinatorV2Mock",
    deployer
  );

  await vrfCoordinatorV2Mock.fulfillRandomWords(requestId, randomNft.address);

  console.log(`Random NFT index 0 tokenURI: ${await randomNft.tokenURI(0)}`);
};
module.exports.tags = ["all", "mint"];
