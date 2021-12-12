// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";

/// @title A smart contract for a South African Burial Stokvel
/// @author Jurgen Schulte
/// @notice The contract allows for multiple owners and members After members pay a contribution they are able to submit requests for payment which need to be approved by owners.
/// @dev Deletion and non approval of request will be implemented in later version
contract BurialStokvelAccount is Pausable {
    address[] public owners;
    address[] public members;
    uint256 public required;
    uint256 public balance;
    uint256 public contribution;
    uint256 public transactionCount;
    uint256[] private transactionIDs;

    mapping(address => bool) public isOwner;
    mapping(address => bool) public isMember;
    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;

    enum State {
        Executed,
        Pending,
        Approved
    }

    struct Transaction {
        string name;
        address destination;
        uint256 value;
        State state;
    }

    /// @notice Emitted when a request is submitted
    /// @param transactionId transaction id
    event Submission(uint256 indexed transactionId);

    /// @notice Emitted when a submitted request is confirmed
    /// @param sender sender address
    /// @param transactionId transaction id
    /// @param approved a boolean indication if the confirmed transaction is approved
    event Confirmation(
        address indexed sender,
        uint256 indexed transactionId,
        string approved
    );

    /// @notice Emitted when a transfer of funds is executed
    /// @param transactionId transaction id
    event Execution(uint256 indexed transactionId);

    /// @notice Emitted when a transfer of funds fails
    /// @param transactionId transaction id
    event ExecutionFailure(uint256 indexed transactionId);

    /// @notice Emitted when a address is enrolled as a member
    /// @param accountAddress account of member
    event LogEnrolled(address indexed accountAddress);

    /// @notice Emitted when a member deposits his contribution
    /// @param sender sender address
    /// @param value value of contribution
    event Deposit(address indexed sender, uint256 value);

    /// @dev Fallback function allows to deposit ether.
    fallback() external payable {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
            balance++;
        }
    }

    /// @dev Receive function allows to deposit ether.
    receive() external payable {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
            balance++;
        }
    }

    // NOT a valid modifier
    modifier validRequirement(uint256 _ownerCount, uint256 _required) {
        if (_required > _ownerCount || _required == 0 || _ownerCount == 0)
            revert();
        _;
    }

    modifier onlyOwners(address _address) {
        require(isOwner[_address], "Only owners allowed");
        _;
    }

    modifier onlyMembers(address _address) {
        require(isMember[_address], "Only members allowed");
        _;
    }

    function unpause() public onlyOwners(msg.sender) {
        _unpause();
    }

    function pause() public {
        _pause();
    }

    /// @dev Contract constructor sets initial owners of the stokvel account and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    /// @param _contribution Required minimum contribution.
    constructor(
        address[] memory _owners,
        uint256 _required,
        uint256 _contribution
    ) validRequirement(_owners.length, _required) {
        require(_contribution > 0);
        require(_owners.length >= _required);
        for (uint256 i = 0; i < _owners.length; i++) {
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
        contribution = _contribution;
    }

    function enroll() public payable returns (bool) {
        require(isMember[msg.sender] == false);
        require(msg.value >= contribution);
        isMember[msg.sender] = true;
        members.push(msg.sender);
        emit LogEnrolled(msg.sender);
        balance += msg.value;
        emit Deposit(msg.sender, msg.value);
        return isMember[msg.sender];
    }

    /// @dev Allows a member to submit a transaction request.
    /// @param _value Amount requested.
    function submitRequest(uint256 _value, string memory _name)
        public
        returns (uint256)
    {
        require(isMember[msg.sender]);
        require(_value <= balance);
        uint256 transactionId = addTransaction(msg.sender, _value, _name);
        return transactionId;
    }

    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param _destination Transaction target address.
    /// @param _value Transaction ether value.
    /// @return transactionId Returns transaction ID.
    function addTransaction(
        address _destination,
        uint256 _value,
        string memory _name
    ) internal returns (uint256 transactionId) {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            name: _name,
            destination: _destination,
            value: _value,
            state: State.Pending
        });
        transactionIDs.push(transactionId);
        transactionCount += 1;
        emit Submission(transactionId);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param _transactionId Transaction ID.
    function confirmTransaction(uint256 _transactionId) public {
        require(isOwner[msg.sender]);
        require(transactions[_transactionId].destination != address(0));
        require(confirmations[_transactionId][msg.sender] == false);

        confirmations[_transactionId][msg.sender] = true;
        string memory approved = "false";
        if (isConfirmed(_transactionId)) {
            transactions[_transactionId].state = State.Approved;
            approved = "true";
        }

        emit Confirmation(msg.sender, _transactionId, approved);
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param _transactionId Transaction ID.
    /// @return confirmed Confirmation status.
    function isConfirmed(uint256 _transactionId)
        public
        view
        returns (bool confirmed)
    {
        uint256 count = 0;
        confirmed = false;
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[_transactionId][owners[i]]) count += 1;
            if (count == required) confirmed = true;
        }
        return confirmed;
    }

    function withdraw(uint256 _transactionId) public whenNotPaused {
        require(transactions[_transactionId].destination == msg.sender);
        executeTransaction(_transactionId);
    }

    /// @dev Transaction is executed if enough confirmations have been
    /// received and the balance is sufficient.
    /// @param _transactionId Transaction ID.
    function executeTransaction(uint256 _transactionId) internal {
        require(transactions[_transactionId].state == State.Approved);
        // Check balance
        require(transactions[_transactionId].value <= balance);
        if (isConfirmed(_transactionId)) {
            Transaction storage t = transactions[_transactionId]; // using the "storage" keyword makes "t" a pointer to storage
            t.state = State.Executed;
            balance = balance - transactions[_transactionId].value;
            (bool success, ) = t.destination.call{value: msg.value}("");
            if (success) emit Execution(_transactionId);
            else {
                emit ExecutionFailure(_transactionId);
                t.state = State.Approved;
                balance = balance + transactions[_transactionId].value;
                require(success, "Failed to send money");
            }
        }
    }

    function getAllTransactionIDs() public view returns (uint256[] memory) {
        // Only three pending transactions allowed
        return transactionIDs;
    }

    //
    function fetchTransaction(uint256 _transactionId)
        public
        view
        returns (
            string memory name,
            uint256 value,
            address destination,
            string memory state
        )
    {
        name = transactions[_transactionId].name;
        value = transactions[_transactionId].value;
        destination = transactions[_transactionId].destination;
        if (transactions[_transactionId].state == State.Executed) {
            state = "Executed";
        } else if (transactions[_transactionId].state == State.Pending) {
            state = "Pending";
        } else if (transactions[_transactionId].state == State.Approved) {
            state = "Approved";
        } else {
            state = "";
        }

        return (name, value, destination, state);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getMinimumContribution() public view returns (uint256) {
        return contribution;
    }

    function getNumberofRequiredApprovals() public view returns (uint256) {
        return required;
    }

    function getBalance() public view returns (uint256) {
        return balance;
    }

    function getMembers() public view returns (address[] memory) {
        return members;
    }

    /// @notice Allows approver to cancel submitted transaction
    /// @dev This function will allow owners to cancel submitted requests by members
    function cancelTransaction() external {
        // TODO: this will allow owners to cancel transaction. We will need to ensure that a
        // transaction is only cancelled when enough owners cancel.
    }

    /// @notice Allows approvers to remove members
    /// @dev This function will allow owners to remove members members
    function removeMember() external {
        // TODO: this will allow owners to remove members and refund their contributions.
        // This mechanism will ensure owners can remove misbehaving members.
    }
}
