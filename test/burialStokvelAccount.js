const BurialStokvelAccount = artifacts.require("./BurialStokvelAccount.sol");

contract("BurialStokvelAccount", accounts => {

  const owners = [accounts[0], accounts[1]];
  let burialStokvelAccountInstance;


  before(async () => {
    burialStokvelAccountInstance = await BurialStokvelAccount.deployed();
  });

  describe("Setting up the stokvel", async () => {
    it("...the owners should be account 1 and 2.", async () => {

      // Get contibution value
      const account1 = await burialStokvelAccountInstance.owners(0);
      const account2 = await burialStokvelAccountInstance.owners(1);

      assert.equal(account1, accounts[0], "The value for account1 was not stored.");
      assert.equal(account2, accounts[1], "The value account2 was not stored.");

    });

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

  describe("Enrolling in stokvel", async () => {
    it("...account 3 should be enrolled with balance equal to contrribution", async () => {

      //const contribution = web3.utils.toBN(2);
      const contribution = 2;

      await burialStokvelAccountInstance.enroll({ from: accounts[2], value: contribution });
      const enrolled = await burialStokvelAccountInstance.isMember(accounts[2]);

      assert.equal(enrolled, true, "The account 2 was not enrolled");

      const balance = await burialStokvelAccountInstance.balance.call();

      assert.equal(balance, 2, "The balance should be 2");

    });
  });

  describe("Submitting request to stokvel", async () => {
    it("...first transaction ID should be zero", async () => {

      const result = await burialStokvelAccountInstance.submitRequest(1, { from: accounts[2] });

      const expectedEventResult = { transactionId: 0 };

      const logID = result.logs[0].args.transactionId;

      assert.equal(expectedEventResult.transactionId, logID, "The transaction ID should be 0");

    });

    it("...second transaction ID should be 1", async () => {

      const result = await burialStokvelAccountInstance.submitRequest(1, { from: accounts[2] });

      const expectedEventResult = { transactionId: 1 };

      const logID = result.logs[0].args.transactionId;

      assert.equal(expectedEventResult.transactionId, logID, "The transaction ID should be 0");

    });
  });



});

