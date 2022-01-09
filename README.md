# Project for Consensys Academy

## Deloyed URL
https://blockchain-developer-bootcamp-final-project-jschulte0511.vercel.app/

## Project Description

In South Afrcia a Stokvel is a type of credit union in which a group of people enter into an agreement to contribute a fixed amount of money to a common pool weekly, fortnightly or monthly. Universally, such a system is known as a rotating savings and credit association (ROSCA), which is a group of individuals who agree to meet for a defined period in order to save together. 

For this project, I will provide a platform that allows the creation of a smart contract that regulates a stokvel used specifically for funeral expenses which is a common type of stokvel in South Africa that allows it's members to bury their loved ones with dignity. During the creation of the stokvel smart contract the user will have the ability to: 

1. Determine the minimum number of approvers needed to confirm a payout request by a member.
2. Minimum contribution required by a member enrolling.

### Project workflow

Once the contract has been deployed the following steps are required:

1. A minimum number of adressess have to apply as approvers. These approvers cannot become members and hence cannot submit a payout request.
2. A address has to enroll with a minimum contribution to become a member.
3. A member can then submit a request to withraw funds from the smart contract to cover funeral costs.
4. The request needs to be approved by a minimum amount of approvers using the transaction ID.
5. Once the request has been approved the initiating member can request the withdrawal of the amount asked for using the transaction ID.

For security reasons the approvers can pause and unpause the contract. When the contract is paused no funds can be withdrawn.

### Project Rooadmap

In future approvers will have the ability to cancel requests or remove members.

    1. function cancelTransaction() public onlyRole(OWNER_ROLE)
    2. function removeMember() public onlyRole(OWNER_ROLE)

## How to run this project locally:

### Prerequisites

- Node.js >= v14 with npm
- Truffle
- `git clone https://github.com/jschulte0511/blockchain-developer-bootcamp-final-project.git`
- `cd blockchain-developer-bootcamp-final-project`
- `git fetch --all --tags`
- `git checkout tags/v1.0 -b cert`

## Testing contracts

- `cd blockchain-developer-bootcamp-final-project`
- `npm install`
- `truffle test`
  
### Using Frontend App

- Using an ethereum client like Ganache, run a local testnet in port 7545
- In IDE terminal `cd blockchain-developer-bootcamp-final-project`
- `truffle migrate --network development` - network development with port 7545 is specified in truffle.config.
- In order to test locally line 27 in App.js needs to be commented out as it refers to the contract address in Rinkeby.
  
- In new terminal `cd ../blockchain-developer-bootcamp-final-project/client`
- and `npm start run` - ensure `npm install` was run previously.
- Open http://localhost:3000 in browser.
- Make sure your Metamask localhost network is port 7545.
- If you get TXRejectedError when sending a transaction, reset your Metamask account from Advanced settings.

## Directory structure

- client: Project's React frontend.
- contracts: Smart contracts that are deployed in the Rinkeby testnet.
- migrations: Migration files for deploying contracts in contracts directory.
- test: Tests for smart contracts.
- node_modules/@oppenzeppelin/contracts: Smart contracts from OppenZeppelin

## Screencast link

https://www.loom.com/share/f3b2677791a844f793cad19fd7a7f25c

## Public Ethereum wallet for certification
0x2817F199655E575FAA408eb1BCd27A6656003008