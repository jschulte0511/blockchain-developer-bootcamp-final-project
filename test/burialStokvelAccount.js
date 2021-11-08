const BurialStokvelAccount = artifacts.require("./BurialStokvelAccount.sol");

contract("BurialStokvelAccount", accounts => {

  const owners = [accounts[0], accounts[1]];
  let burialStokvelAccountInstance;


  before(async () => {
    burialStokvelAccountInstance = await BurialStokvelAccount.deployed();
  });

  describe("Setting up the stokvel", async () => {
    it("...the contibution should be 10.", async () => {

      // Get contibution value
      const contribution = await burialStokvelAccountInstance.contribution.call();

      assert.equal(contribution, 10, "The value 10 for contribution was not stored.");
    });

    it("...the number of required confirmations should be 2.", async () => {

      // Get contibution value
      const required = await burialStokvelAccountInstance.required.call();

      assert.equal(required, 2, "The value 2 for owners was not stored.");
    });
  });
});
