const WineProduction = artifacts.require("WineProduction");

module.exports = function (deployer) {
  deployer.deploy(WineProduction);
};
