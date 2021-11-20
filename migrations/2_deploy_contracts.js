
var BurialStokvelAccount = artifacts.require("BurialStokvelAccount")

module.exports = function (deployer, network, accounts) {

  const owners = [accounts[0], accounts[1]]

  deployer.deploy(BurialStokvelAccount, owners, 2, 10);
};