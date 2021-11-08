// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract BurialStokvelAccount {
    uint256 public storedData = 0;

    function set(uint256 x) public {
        storedData = x;
    }

    function get() public view returns (uint256) {
        return storedData;
    }

    address[] public owners;
    uint256 public required;

    mapping(address => bool) public isOwner;
    mapping(address => bool) public isMember;

    uint256 public transactionCount;
    uint256[] private pendingTransactionIDs;
    mapping(uint256 => Transaction) public transactions;

    mapping(uint256 => mapping(address => bool)) public confirmations;

    struct Transaction {
        address destination;
        uint256 value;
        bool executed;
    }

    uint256 public balance;
    uint256 public contribution;

    //Events
    event Submission(uint256 indexed transactionId);
    event Confirmation(address indexed sender, uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);
    event LogEnrolled(address accountAddress);

    event Deposit(address indexed sender, uint256 value);

    /// @dev Fallback function allows to deposit ether.
    function() external payable {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
        }
    }

    /// @dev Contract constructor sets initial owners of the stokvel account and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    /// @param _contribution Required minimum contribution.
    constructor(
        address[] memory _owners,
        uint256 _required,
        uint256 _contribution
    ) public validRequirement(_owners.length, _required) {
        require(_contribution > 0);
        for (uint256 i = 0; i < _owners.length; i++) {
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
        contribution = _contribution;
    }

    modifier validRequirement(uint256 ownerCount, uint256 _required) {
        if (_required > ownerCount || _required == 0 || ownerCount == 0)
            revert();
        _;
    }

    modifier validContribution(uint256 _contribution) {
        if (_contribution >= contribution) revert();
        _;
    }

    function enroll()
        public
        payable
        validContribution(msg.value)
        returns (bool)
    {
        require(isMember[msg.sender] == false);
        isMember[msg.sender] = true;
        emit LogEnrolled(msg.sender);
        balance += msg.value;
        emit Deposit(msg.sender, msg.value);
        return isMember[msg.sender];
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param value Amount requested.
    function submitRequest(uint256 value)
        public
        returns (uint256 transactionId)
    {
        require(isMember[msg.sender]);
        transactionId = addTransaction(msg.sender, value);
        confirmTransaction(transactionId);
    }

    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @return Returns transaction ID.
    function addTransaction(address destination, uint256 value)
        internal
        returns (uint256 transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            executed: false
        });
        transactionCount += 1;
        emit Submission(transactionId);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint256 transactionId) public {
        require(isOwner[msg.sender]);
        require(transactions[transactionId].destination != address(0));
        require(confirmations[transactionId][msg.sender] == false);
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint256 transactionId) public view returns (bool) {
        uint256 count = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) count += 1;
            if (count == required) return true;
        }
    }

    /// @dev Transaction is executed if enough confirmations have been
    /// received and the balance is not sufficient.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint256 transactionId) internal {
        require(transactions[transactionId].executed == false);
        // Check balance
        if (isConfirmed(transactionId)) {
            Transaction storage t = transactions[transactionId]; // using the "storage" keyword makes "t" a pointer to storage
            t.executed = true;
            (bool success, ) = t.destination.call.value(t.value)("");
            removePendingTransactionID(transactionId);
            if (success) emit Execution(transactionId);
            else {
                emit ExecutionFailure(transactionId);
                t.executed = false;
                pendingTransactionIDs.push(transactionId);
                require(success, "Failed to send money");
            }
        }
    }

    function removePendingTransactionID(uint256 _index) internal {
        require(_index < pendingTransactionIDs.length, "index out of bound");

        for (uint256 i = _index; i < pendingTransactionIDs.length - 1; i++) {
            pendingTransactionIDs[i] = pendingTransactionIDs[i + 1];
        }
        pendingTransactionIDs.pop();
    }

    function getAllPendingTransactionIDs()
        public
        view
        returns (uint256[] memory)
    {
        // Only three pending transactions allowed
        return pendingTransactionIDs;
    }
}
