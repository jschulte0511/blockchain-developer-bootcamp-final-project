Design Patterns

Access Control Design Patterns

BurialStokvelAccount.sol contract inherits the OpenZeppelin AccessControl contract @openzeppelin/contracts/access/AccessControl.sol to createthe owner and member roles. Only owners are allowed to pause and unpause the contract thereby making it impossible for funds to be withdrawn. By restricting the submitRequest function using onlyRole(MEMBER_ROLE) only members that have been enrolled successfully can request funds from the BurialStokvel.

Inheritance and Interfaces

BurialStokvelAccount.sol contract inherits the OpenZeppelin Pausable contract @openzeppelin/contracts/security/Pausable.sol to enable pausing of the withdraw function if an attack on the contract occurs.