import React, { Component } from "react";
import SimpleStorageContract from "./contracts/BurialStokvelAccount.json";
import getWeb3 from "./getWeb3";

import "./App.css";

class App extends Component {
  state = { web3: null, accounts: null, contract: null, owners: null, members: null, balance: 0, transactions: null, accountBalance: 0, contibution: 0, requiredApprovals: 0 };

  componentDidMount = async () => {
    try {
      // Get network provider and web3 instance.
      const web3 = await getWeb3();

      // Use web3 to get the user's accounts.
      const accounts = await web3.eth.getAccounts();
      console.log("Number of accounts: " + accounts.length);
      console.log("Acounts address: " + accounts[0]);

      // Get the contract instance.
      const networkId = await web3.eth.net.getId();
      const deployedNetwork = SimpleStorageContract.networks[networkId];
      const instance = new web3.eth.Contract(
        SimpleStorageContract.abi,
        deployedNetwork && deployedNetwork.address,
      );

      // Set web3, accounts, and contract to the state, and then proceed with an
      // example of interacting with the contract's methods.
      this.setState({ web3, accounts, contract: instance }, this.reloadState);
      // this.setState({ web3, accounts, contract: instance });
    } catch (error) {
      // Catch any errors for any of the above operations.
      alert(
        `Failed to load web3, accounts, or contract. Check console for details.`,
      );
      console.error(error);
    }
  };


  reloadState = async () => {
    const { web3, accounts, contract } = this.state;

    const ownersResp = await contract.methods.getOwners().call();
    this.setState({ owners: ownersResp });

    const balance = await contract.methods.getBalance().call();
    this.setState({ balance: balance });

    const contibution = await contract.methods.getMinimumContribution().call();
    this.setState({ contibution: contibution });

    const requiredApprovals = await contract.methods.getNumberofRequiredApprovals().call();
    this.setState({ requiredApprovals: requiredApprovals });

    const members = await contract.methods.getMembers().call();
    this.setState({ members: members });

    const accBalance = await web3.eth.getBalance(accounts[0]);
    this.setState({ accountBalance: accBalance });

    // DEBUG
    console.log("Owner one is ...", this.state.owners[0]);

    if (members != null) {
      console.log("Member one is ...", this.state.members[0]);
    }
    console.log("Balance is ...", this.state.balance);
    // DEBUG

    this.loadTransactions();
  };

  loadTransactions = async () => {

    const { contract } = this.state;

    // Get the value from the contract to prove it worked.
    const transactionIds = await contract.methods.getAllTransactionIDs().call();

    let transactions = [];

    for (let i = 0; i < transactionIds.length; i++) {

      const transaction = await contract.methods.fetchTransaction(transactionIds[i]).call();

      transactions[i] = { name: transaction.name, destination: transaction.destination, value: transaction.value, state: transaction.state };
    }

    this.setState({ transactions: transactions });
    //if (err) console.error('An error occured', err);

    // DEBUG
    console.log('Loaded transactions: ', transactions.length);

  }


  enroll = async () => {

    const { accounts, contract } = this.state;

    const ssInputValue = document.getElementById('ss-contribution-input-box').value;
    console.log('Contribution for enrollment (min 2): ', ssInputValue);

    // Enroll new member
    await contract.methods.enroll().send({ from: accounts[0], value: ssInputValue });
    const members = await contract.methods.getMembers().call();
    this.setState({ members: members });

    this.reloadState();

  }

  submitRequest = async () => {

    const { accounts, contract } = this.state;

    const ssInputValue = document.getElementById('ss-request-input-box').value;
    console.log('Requested amount: ', ssInputValue);

    // Submit Request
    await contract.methods.submitRequest(ssInputValue, "Name").send({ from: accounts[0] });

    // Reloading
    this.reloadState();
  }

  approveRequest = async () => {

    const { accounts, contract } = this.state;

    const ssInputValue = document.getElementById('ss-approve-input-box').value;
    console.log('Approved ID: ', ssInputValue);

    // Submit Approval
    await contract.methods.confirmTransaction(ssInputValue).send({ from: accounts[0] });

    // Reloading 
    this.reloadState();
  }

  withdraw = async () => {

    const { accounts, contract } = this.state;

    const ssInputValue = document.getElementById('ss-withdraw-input-box').value;
    console.log('ID fior withdrawal: ', ssInputValue);

    // Withdraw
    await contract.methods.withdraw(ssInputValue).send({ from: accounts[0] });

    // Reloading 
    this.reloadState();
  }

  render() {
    if (!this.state.web3) {
      return <div>Loading Web3, accounts, and contract...</div>;
    }

    let ownersLoaded = false;
    let ownersList = null;
    const owners = this.state.owners;
    if (owners != null) {
      ownersLoaded = true;
      ownersList = owners.map(function (address, index) {
        return <li key={index}>Owner {index}: {address}</li>;
      })
    }

    let membersLoaded = false;
    let membersList = null;
    const members = this.state.members;
    if (members != null) {
      membersLoaded = true;
      membersList = members.map(function (address, index) {
        return <li key={index}>Member {index}: {address}</li>;
      })
    }

    let transactionsLoaded = false;
    let transactionsList = null;
    const transactions = this.state.transactions;
    if (transactions != null) {
      console.log("Length: ", transactions.length);
      transactionsLoaded = true;
      transactionsList = transactions.map(function (anObjectMapped, index) {
        return <tr key={index}><td>{index}</td><td>{anObjectMapped.name}</td><td>{anObjectMapped.destination}</td><td>{anObjectMapped.value}</td><td>{anObjectMapped.state}</td></tr>;
      })
    }



    return (
      <div className="App">
        <div style={{ "textAlign": "left", "border": "1px solid black", "width": "40%" }}>
          <div>Please reload page when changing account</div>
          <div>Address: {this.state.accounts[0]}</div>
          <div>Balance in Wei: {this.state.accountBalance}</div>
        </div>
        <br />
        <br />
        <h1>Burial Stokvel Account</h1>
        <p></p>
        <h2>Balance is {this.state.balance}</h2>
        <br />
        <br />
        <h3>Number of unique approvals required from owners is {this.state.requiredApprovals}</h3>
        {ownersLoaded ? ownersList : null}
        <br />
        <h3>Members</h3>
        {membersLoaded ? membersList : null}
        <br />
        <h3>Transactions</h3>
        <table style={{ "marginLeft": "auto", "marginRight": "auto" }}>
          <thead>
            <tr>
              <th>ID</th>
              <th>Name</th>
              <th>Destination</th>
              <th>Value</th>
              <th>State</th>
            </tr>
          </thead>
          <tbody>{transactionsLoaded ? transactionsList : null}</tbody>
        </table>
        <br />
        <br />
        <div>
          <div>
            Minimum contribution in Wei is {this.state.contibution}
          </div>
          <div>
            <input id="ss-contribution-input-box" type="number" placeholder="Contribution in Wei" />
            <button onClick={this.enroll} id="ss-contr-input-button">Enroll</button>
          </div>
        </div>
        <br />
        <br />
        <div>
          <input id="ss-request-input-box" type="number" placeholder="Requested Wei" />
          <button onClick={this.submitRequest} id="ss-request-input-button">Submit</button>
        </div>
        <br />
        <br />
        <div>
          <input id="ss-approve-input-box" type="number" placeholder="Transaction ID" />
          <button onClick={this.approveRequest} id="ss-approve-input-button">Approve</button>
        </div>
        <br />
        <br />
        <div>
          <input id="ss-withdraw-input-box" type="number" placeholder="Transaction ID" />
          <button onClick={this.withdraw} id="ss-withdraw-input-button">Withdraw</button>
        </div>
        <br />
      </div >
    );
  }
}

export default App;
