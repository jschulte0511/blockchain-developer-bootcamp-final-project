const BurialStokvelAccount = artifacts.require("./BurialStokvelAccount.sol");
let BN = web3.utils.BN;

contract("BurialStokvelAccount", accounts => {

  const owners = [accounts[0], accounts[1]];
  let burialStokvelAccountInstance;


  before(async () => {
    burialStokvelAccountInstance = await BurialStokvelAccount.deployed();
  });

  describe("Setting up the stokvel", async () => {
    it("...the owners should be account 1 and 2.", async () => {

      // Get contibution value
      const owners = await burialStokvelAccountInstance.getOwners();
      //const account2 = await burialStokvelAccountInstance.owners(1);

      assert.equal(owners[0], accounts[0], "The value for account1 was not stored.");
      assert.equal(owners[1], accounts[1], "The value account2 was not stored.");

    });

    it("...the contibution should be 2.", async () => {

      // Get contibution value
      const contribution = await burialStokvelAccountInstance.contribution.call();

      assert.equal(contribution, 2, "The value 2 for contribution was not stored.");
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

      const result = await burialStokvelAccountInstance.submitRequest(1, "Account 2", { from: accounts[2] });

      const expectedEventResult = { transactionId: 0 };

      const logID = result.logs[0].args.transactionId;

      assert.equal(expectedEventResult.transactionId, logID, "The transaction ID should be 0");

    });

    it("...second transaction ID should be 1", async () => {

      const result = await burialStokvelAccountInstance.submitRequest(1, "Account 2", { from: accounts[2] });

      const expectedEventResult = { transactionId: 1 };

      const logID = result.logs[0].args.transactionId;

      assert.equal(expectedEventResult.transactionId, logID, "The transaction ID should be 1");

    });
  });

  describe("Confirming pending transaction in stokvel", async () => {
    it("...using account 0", async () => {

      const result = await burialStokvelAccountInstance.confirmTransaction(0, { from: accounts[0] });

      const expectedEventResult = { address: accounts[0], transactionId: 0, approved: "false" };

      const logID = result.logs[0].args.transactionId;
      const logSender = result.logs[0].args.sender;
      const logApproved = result.logs[0].args.approved;

      assert.equal(expectedEventResult.transactionId, logID, "The transaction ID should be 0");
      assert.equal(expectedEventResult.address, logSender, "The address should be " + accounts[0]);
      assert.equal(expectedEventResult.approved, logApproved, "The value of approved should be false");

      const { name, value, destination } = await burialStokvelAccountInstance.fetchTransaction(logID);

      assert.equal(name, "Account 2", "The transaction name should be Account 1");

    });


    it("...using account 1", async () => {

      let result = await burialStokvelAccountInstance.confirmTransaction(0, { from: accounts[1] });

      // emit Confirmation(msg.sender, _transactionId);
      const expectedEventResult = { address: accounts[1], transactionId: 0, approved: "true" };

      const logID = result.logs[0].args.transactionId;
      const logSender = result.logs[0].args.sender;
      const logApproved = result.logs[0].args.approved;

      assert.equal(expectedEventResult.transactionId, logID, "The transaction ID should be 0 for Confirmation");
      assert.equal(expectedEventResult.address, logSender, "The address should be " + accounts[1]);
      assert.equal(expectedEventResult.approved, logApproved, "The value of approved should be true");

    });
  });

  describe("Withdraw funds using confirmed transaction", async () => {
    it("...balance of stokvel should have decreased by 1", async () => {

      const balanceBeforeExecution = await web3.eth.getBalance(accounts[2]);
      const initialBalanceOfStokvel = await burialStokvelAccountInstance.balance.call();

      const result = await burialStokvelAccountInstance.withdraw(0, { from: accounts[2] });

      // emit Execution(_transactionId);
      const logID = result.logs[0].args.transactionId;
      assert.equal(0, logID, "The transaction ID should be 0 for Execution");

      var balanceAfterExecution = await web3.eth.getBalance(accounts[2]);
      // assert.isAbove(new BN(balanceAfterExecution),
      //   new BN(balanceBeforeExecution).add(new BN(1)),
      //   "The balance after execution should be greater by 1");

      const result2 = await burialStokvelAccountInstance.fetchTransaction(0);

      assert.equal(result2[3],
        "Executed",
        "The transaction should have state executed");

      const endBalanceOfStokvel = await burialStokvelAccountInstance.balance.call();

      assert.equal(new BN(initialBalanceOfStokvel).toString(), new BN(endBalanceOfStokvel).add(new BN(1)).toString(), "The balance of the stokvel should be 1");

    });
  });
});
