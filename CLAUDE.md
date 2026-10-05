# Sandbox

Test bed for the Claude PR review workflows (Chestnut CHES-1154). Plain
JavaScript, no build step. `src/` holds a tiny shopping-cart module and
`node --test` runs `src/*.test.js`.

- Money is handled in integer cents, never floats.
- Functions MUST NOT mutate their arguments.
