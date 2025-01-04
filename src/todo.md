# To Do

## Security Enhancements
- Ensure emergency mode can only be triggered under specific conditions and consider adding a cooldown period.
- Secure the transition from admin to DAO governance and ensure it is irreversible unless explicitly allowed by a proposal.
- Ensure proposal execution is atomic and cannot be interrupted or manipulated.
- Implement a robust snapshot mechanism to accurately reflect voting power at the time of proposal creation.

## Gas Optimization
- Optimize storage by reordering state variables and using `immutable` for constants.
- Use mappings and arrays efficiently to minimize storage costs.

## Functionality Enhancements
- Implement a mechanism to unlock liquidity after a certain period or based on governance decisions.
- Implement a vesting mechanism for team members' token allocations to ensure long-term commitment.
- Allow for different bonding curve formulas and token sale mechanisms to be selected at deployment or through governance proposals.

## Testing and Coverage
- Ensure all functions and edge cases are covered by tests, aiming for 100% test coverage.

## Specific Tasks
- Add a function to check if a proposal has passed.
- Add a function to check if a proposal has been executed.
- Check locked liquidity logic.