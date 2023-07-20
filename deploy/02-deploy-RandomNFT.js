const { network } = require("hardhat");
const fs = require("fs");
const {
  developmentChains,
  networkConfig,
} = require("../helper-hardhat-config");
require("dotenv").config();

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = network.config.chainId;
  let vrfCoordinatorV2Address, subscriptionId, vrfCoordinatorV2Mock;

  if (developmentChains.includes(network.name)) {
    vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock");
    vrfCoordinatorV2Address = vrfCoordinatorV2Mock.address;
    const transactionResponse = await vrfCoordinatorV2Mock.createSubscription();
    const transactionReceipt = await transactionResponse.wait(1);
    subscriptionId = transactionReceipt.events[0].args.subId;
    log(`id is ${subscriptionId}`);
    //fund the subscription.On a real network token link is required
    await vrfCoordinatorV2Mock.fundSubscription(
      subscriptionId,
      ethers.utils.parseEther("1")
    );
  } else {
    vrfCoordinatorV2Address = networkConfig[chainId]["vrfCoordinator"];
    subscriptionId = networkConfig[chainId]["subscriptionId"];
  }
  const mintFee = networkConfig[chainId]["mintFee"];
  const keyHash = networkConfig[chainId]["keyHash"];
  const callbackGasLimit = networkConfig[chainId]["callbackGasLimit"];

  let filepath1 = "./img/star1.svg";
  let svg1 = fs.readFileSync(filepath1, { encoding: "utf8" });
  let filepath2 = "./img/star2.svg";
  let svg2 = fs.readFileSync(filepath2, { encoding: "utf8" });
  let filepath3 = "./img/star3.svg";
  let svg3 = fs.readFileSync(filepath3, { encoding: "utf8" });

  const imgUris = [svg1, svg2, svg3];
  const args = [
    vrfCoordinatorV2Address,
    subscriptionId,
    keyHash,
    mintFee,
    callbackGasLimit,
    imgUris,
  ];
  //log(imgUris);

  log("----------------------------------------------------");
  log("Deploying RandomNFT SC and waiting for confirmations...");
  const randomNFT = await deploy("RandomNFT", {
    from: deployer,
    args: args, //put price feed address that is needed in the constructor
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1,
  });
  log(`RandomNFT SC deployed at ${randomNFT.address}`);
  if (chainId == 31337) {
    await vrfCoordinatorV2Mock.addConsumer(subscriptionId, randomNFT.address);
  }
};
module.exports.tags = ["all", "randomNFT"];
