# Floork

## Deployment Steps:
- Add wallet `PRIVATE_KEY` and a mainnet `RPC_URL`  to `.env` file
- Run the following command: `forge script script/DeployFloork.s.sol --broadcast --verify --chain-id=1 --rpc-url=${RPC_URL} --optimize --optimizer-runs=200`
