# Contract security measures

## SWC-103 (Floating pragma)

Specific compiler pragma 0.8.0 is used in contracts to avoid accidental bug inclusion through outdated compiler versions.

## SWC-105 (Unprotected Ether Withdrawal)

The withdraw function is protected with a require ensuring only initiator of submitted payout request can withdraw amount.

## SWC-104 (Unchecked Call Return Value)

The return value from a call to the owner's address in withdraw -> executeTransaction is checked with require to ensure transaction rollback if call fails. The internal state is reset to Approved from Executed and the internal balance is also adjusted.

(bool success, ) = t.destination.call{value: transactions[_transactionId].value}("");

## Modifiers used only for validation

All modifiers in contract(s) only validate data with require statements.
