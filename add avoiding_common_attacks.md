Contract security measures

SWC-103 (Floating pragma)

Specific compiler pragma 0.8.0 used in contracts to avoid accidental bug inclusion through outdated compiler versions.

SWC-105 (Unprotected Ether Withdrawal)

withdraw is protected with a require ensuring only owner of submitted request can withdraw amount.

SWC-104 (Unchecked Call Return Value)

The return value from a call to the owner's address in withdraw -> executeTransaction is checked with require to ensure transaction rollback if call fails. The internal state is reset to Approved and the internal balance is also adjusted.

Modifiers used only for validation

All modifiers in contract(s) only validate data with require statements.