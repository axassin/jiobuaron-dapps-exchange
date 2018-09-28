const FixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");
const Exhange = artifacts.require("./Exchange.sol")
const Owned = artifacts.require("./Owned")
const SimpleStorage = artifacts.require("./SimpleStorage")

module.exports = function(deployer) {
  deployer.deploy(FixedSupplyToken);
  deployer.deploy(Exhange);
  deployer.deploy(Owned);
  deployer.deploy(SimpleStorage);
};
