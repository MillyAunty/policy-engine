# Policy Engine Contract

A contract that stores and enforces protocol policies, allowing governance
to define rules that gate actions across connected smart contracts.

## Key Functions
- `set-policy` — Define or update a policy rule
- `remove-policy` — Delete an existing policy
- `check-policy` — Validate whether an action is allowed
- `get-policy` — Retrieve policy configuration and status
- `list-policies` — View all active policy rules

Designed for compliance checks, protocol safety guards, and governance-controlled
execution constraints.
