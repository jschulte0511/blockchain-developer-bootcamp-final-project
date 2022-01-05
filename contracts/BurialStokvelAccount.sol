// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title A smart contract for a South African Burial Stokvel
/// @author Jurgen Schulte
/// @notice The contract allows for multiple owners and members After members pay a contribution they are able to submit requests for payment which need to be approved by owners.
/// @dev Deletion and non approval of request will be implemented in later version
contract BurialStokvelAccount is Pausable, AccessControl {
    address[] public owners;
    address[] public members;
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant MEMBER_ROLE = keccak256("MEMBER_ROLE");

    uint256 public required;
    uint256 public balance;
    uint256 public contribution;

    // Used to assign transactionID's by incrementing the value
    uint256 public transactionCount;
    uint256[] private transactionIDs;

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
    /// @param transactionId Transaction ID
    event Submission(uint256 indexed transactionId);

    /// @notice Emitted when a submitted request is confirmed
    /// @param sender Sender address
    /// @param transactionId Transaction id
    /// @param approved A boolean indication if the confirmed transaction is approved
    event Confirmation(
        address indexed sender,
        uint256 indexed transactionId,
        string approved
    );

    /// @notice Emitted when a transfer of funds is executed
    /// @param transactionId Transaction ID
    event Execution(uint256 indexed transactionId);

    /// @notice Emitted when a transfer of funds fails
    /// @param transactionId Transaction ID
    event ExecutionFailure(uint256 indexed transactionId);

    /// @notice Emitted when a address is enrolled as a member
    /// @param accountAddress Account of member
    event LogEnrolled(address indexed accountAddress);

    /// @notice Emitted when a member deposits his contribution
    /// @param sender Sender address
    /// @param value Value of contribution
    event Deposit(address indexed sender, uint256 value);

    /// @notice Fallback function
    /// @dev Fallback function allows to deposit ether.
    fallback() external payable {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
            balance++;
        }
    }

    /// @notice Receive function
    /// @dev Receive function allows to deposit ether.
    receive() external payable {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
            balance++;
        }
    }

    modifier notMember(address _address) {
        require(
            !hasRole(MEMBER_ROLE, msg.sender),
            "Applicant is already a member"
        );
        _;
    }

    modifier notOwner(address _address) {
        require(
            !hasRole(OWNER_ROLE, msg.sender),
            "Applicant is already a approver"
        );
        _;
    }

    /// @notice Unpause the contract by owners only.
    /// @dev This function controls the unpause/pause modifier which is used to prevent withdrawals in case an attack on the contract.
    function unpause() public onlyRole(OWNER_ROLE) {
        _unpause();
    }

    /// @notice Pause the contract by owners only.
    /// @dev This function controls the unpause/pause modifier which is used to prevent withdrawals in case an attack on the contract.
    function pause() public onlyRole(OWNER_ROLE) {
        _pause();
    }

    /// @notice Contract constructor sets initial owners of the stokvel
    // account and required number of confirmations.
    /// @dev Contract constructor sets initial owners of the stokvel account
    /// and required number of confirmations.
    /// @param _required Number of required confirmations.
    /// @param _contribution Required minimum contribution.
    constructor(uint256 _required, uint256 _contribution) {
        require(_contribution > 0, "Contribution has to be larger than 0");
        require(
            _required > 0,
            "Number of required approvers has to be larger than 0"
        );

        required = _required;
        contribution = _contribution;
    }

    /// @notice Enrolls the address as a member
    /// @dev Checks that the address is not already a member
    function applyAsApprover()
        public
        notMember(msg.sender)
        notOwner(msg.sender)
    {
        _setupRole(OWNER_ROLE, msg.sender);
        owners.push(msg.sender);
    }

    /// @notice Enrolls the address as a member
    /// @dev Checks that the address is not already a member
    function enroll()
        public
        payable
        notMember(msg.sender)
        notOwner(msg.sender)
    {
        require(
            msg.value >= contribution,
            "Amount sent has to be larger than minimum contribution amount"
        );
        _setupRole(MEMBER_ROLE, msg.sender);
        members.push(msg.sender);
        emit LogEnrolled(msg.sender);
        balance += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Allows member to submit a payment request
    /// @dev The value of the contribution is checked aaginst the minimum contribution
    /// stipulated during contract creation
    /// @param _value Value of contribution in Wei
    /// @param _name Name of request
    function submitRequest(uint256 _value, string memory _name)
        public
        onlyRole(MEMBER_ROLE)
        notOwner(msg.sender)
        returns (uint256)
    {
        require(
            _value <= balance,
            "Amount requested has to be smaller or equal to balance in contract"
        );
        uint256 transactionId = addTransaction(msg.sender, _value, _name);
        return transactionId;
    }

    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param _destination Transaction target address.
    /// @param _value Transaction wei value.
    /// @param _name Name of submitted request.
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
    function confirmTransaction(uint256 _transactionId)
        public
        onlyRole(OWNER_ROLE)
    {
        //require(isOwner[msg.sender]);
        require(
            transactions[_transactionId].destination != address(0),
            "Desination address cannot be 0"
        );
        require(
            confirmations[_transactionId][msg.sender] == false,
            "Sender address has to be equal to address of adress that submitted initial request"
        );
        confirmations[_transactionId][msg.sender] = true;
        string memory approved = "false";
        if (isConfirmed(_transactionId)) {
            transactions[_transactionId].state = State.Approved;
            approved = "true";
        }

        emit Confirmation(msg.sender, _transactionId, approved);
    }

    /// @notice Returns the confirmation status of a transaction.
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

    /// @notice Withdraws the reqiested amount by the member.
    /// @dev The sender address is checked to ensure it matches that of the initial requestor
    /// @param _transactionId Transaction ID.
    function withdraw(uint256 _transactionId) public whenNotPaused {
        require(
            transactions[_transactionId].destination == msg.sender,
            "Requester of withdrawal needs to be the same as the initiator of initial request"
        );
        executeTransaction(_transactionId);
    }

    /// @notice Executes the submitted request.
    /// @dev Transaction is executed if enough confirmations have been
    /// received and the balance is sufficient.
    /// @param _transactionId Transaction ID.
    function executeTransaction(uint256 _transactionId) internal {
        require(
            transactions[_transactionId].state == State.Approved,
            "Transaction needs to be in Approved state"
        );
        // Check balance
        require(
            transactions[_transactionId].value <= balance,
            "Balance needs to be equal or greater than requested amount"
        );
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

    /// @notice Returns all transaction IDs.
    /// @return memory All transaction IDs.
    function getAllTransactionIDs() public view returns (uint256[] memory) {
        return transactionIDs;
    }

    /// @notice Returns the details of a transaction.
    /// @param _transactionId The transaction ID.
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

    /// @notice Get all owners.
    /// @return memory All owner addresses.
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    /// @notice Get all members.
    /// @return memory All member addresses.
    function getMembers() public view returns (address[] memory) {
        return members;
    }

    /// @notice Get minimum contribution required.
    /// @return uint256 Minimum contribution.
    function getMinimumContribution() public view returns (uint256) {
        return contribution;
    }

    /// @notice Get number of required approvals.
    /// @return uint256 Number of required approvals.
    function getNumberofRequiredApprovals() public view returns (uint256) {
        return required;
    }

    /// @notice Get balance of contract.
    /// @return uint256 Balance of contract.
    function getBalance() public view returns (uint256) {
        return balance;
    }

    /// @notice Allows approver to cancel submitted transaction
    /// @dev This function will allow owners to cancel submitted requests by members
    function cancelTransaction() public onlyRole(OWNER_ROLE) {
        // TODO: this will allow owners to cancel a transaction. We will need to ensure that a
        // transaction is only cancelled when enough owners cancel.
    }

    /// @notice Allows approvers to remove members
    /// @dev This function will allow owners to remove members members
    function removeMember() public onlyRole(OWNER_ROLE) {
        // TODO: this will allow owners to remove members and refund their contributions.
        // This mechanism will ensure owners can remove misbehaving members.
    }
}
