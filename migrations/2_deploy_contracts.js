
var BurialStokvelAccount = artifacts.require("BurialStokvelAccount")

module.exports = function (deployer, network, accounts) {

  deployer.deploy(BurialStokvelAccount, 2, 2);
};