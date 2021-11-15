import React, { Component } from "react";
import SimpleStorageContract from "./contracts/BurialStokvelAccount.json";
import getWeb3 from "./getWeb3";

import "./App.css";

class App extends Component {
  state = { storageValue: 0, web3: null, accounts: null, contract: null, owners: null, members: null, balance: 0 };

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
      this.setState({ web3, accounts, contract: instance }, this.runExample);
      // this.setState({ web3, accounts, contract: instance });
    } catch (error) {
      // Catch any errors for any of the above operations.
      alert(
        `Failed to load web3, accounts, or contract. Check console for details.`,
      );
      console.error(error);
    }
  };

  runExample = async () => {
    const { storageValue, accounts, contract } = this.state;

    console.log("Value is...", storageValue);

    // Stores a given value, 5 by default.
    // await contract.methods.set(5).send({ from: accounts[0] });

    // Get the value from the contract to prove it worked.
    // const response = await contract.methods.get().call();
    // Update state with the result.
    // this.setState({ storageValue: response });

    const ownersResp = await contract.methods.getOwners().call();
    this.setState({ owners: ownersResp });

    const balance = await contract.methods.getBalance().call();
    this.setState({ balance: balance });

    const members = await contract.methods.getMembers().call();
    this.setState({ members: members });

    // console.log("Value is now...", response);
    console.log("Owner one is ...", this.state.owners[0]);
    if (members != null) {
      console.log("Member one is ...", this.state.members[0]);
    }
    console.log("Balance is ...", this.state.balance);


  };

  querySecret = async () => {

    const { contract } = this.state;

    // Get the value from the contract to prove it worked.
    const response = await contract.methods.get().call();

    this.setState({ storageValue: response });
    //if (err) console.error('An error occured', err);

    console.log('This is our stored data: ', response);

  }

  setSecret = async () => {

    const { storageValue, accounts, contract } = this.state;

    console.log('This is our stored data: ', storageValue);
    const ssInputValue = document.getElementById('ss-input-box').value;

    // Stores a given value, 5 by default.
    await contract.methods.set(ssInputValue).send({ from: accounts[0] });
    console.log('This is our submitted data: ', ssInputValue)

  }

  enroll = async () => {

    const { storageValue, accounts, contract } = this.state;

    const ssInputValue = document.getElementById('ss-contribution-input-box').value;
    console.log('Contribution for enrollment (min 2): ', ssInputValue);

    // Enroll new member
    await contract.methods.enroll().send({ from: accounts[0], value: ssInputValue });
    const members = await contract.methods.getMembers().call();
    this.setState({ members: members });

  }

  render() {
    if (!this.state.web3) {
      return <div>Loading Web3, accounts, and contract...</div>;
    }

    const ownersLoaded = (this.state.owners != null);
    let membersLoaded = false;
    let membersList = null;

    const members = this.state.members;
    if (members != null) {
      membersLoaded = true;
      membersList = members.map(function (address, index) {
        return <li key={index}>Member {index}: {address}</li>;
      })
    }


    return (
      <div className="App" >
        <h1>Burial Stokvel Account</h1>
        <p></p>
        <h2>Smart Contract Example</h2>
        <br />
        <br />

        <h3>Owners</h3>
        <div>Owner 1: {ownersLoaded ? this.state.owners[0] : ""} </div>
        <div>Owner 2: {ownersLoaded ? this.state.owners[1] : ""} </div>
        <br />
        <h3>Members</h3>
        {membersLoaded ? membersList : ""}
        <br />
        <div>Balance is {this.state.balance}</div>
        <br />
        <div>
          <input id="ss-contribution-input-box" type="number" placeholder="Contribution amount" />
          <button onClick={this.enroll} id="ss-contr-input-button">Enroll</button>
        </div>
        <br />
        <div>The stored value is: {this.state.storageValue}</div>
        <br />
        <button onClick={this.querySecret}> Query Smart Contract's Secret</button>
        <br />
        <br />
        <div>
          <input id="ss-input-box" type="number" placeholder="Provide input" />
          <button onClick={this.setSecret} id="ss-input-button">Submit Value</button>
        </div>
      </div>
    );
  }
}

export default App;
