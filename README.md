# Atomic Swap HTLC

A professional-grade Hashed Timelock Contract (HTLC) for executing atomic swaps. This repository provides a secure way for two parties to exchange assets across different blockchains (or the same chain) without needing a trusted third party.

### Features
* **Hash-Locked Security**: Funds are locked using a SHA-256 hash. They can only be released by providing the correct secret (preimage).
* **Timelock Protection**: Includes a `lockTime` expiration. If the counterparty fails to complete the swap, the initiator can reclaim their funds safely.
* **Atomic Integrity**: Ensures an "all-or-nothing" execution model for peer-to-peer trades.
* **Flat Structure**: Minimalist, single-file deployment for high auditability.

### How to Use
1. **Party A** generates a secret and its hash, then calls `fund` to lock tokens in the contract.
2. **Party B** observes the hash and locks their tokens in a similar contract on another chain.
3. **Party A** claims Party B's tokens using the secret, revealing the secret to the public.
4. **Party B** uses the now-public secret to claim Party A's tokens.
