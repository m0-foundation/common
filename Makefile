# Load environment variables from .env file
-include .env

# coverage report
coverage :; forge coverage --report lcov && lcov --remove ./lcov.info -o ./lcov.info 'test/*' && genhtml lcov.info --branch-coverage --output-dir coverage

coverage-summary :; forge coverage --report summary

# Run slither
slither :; FOUNDRY_PROFILE=production forge build --build-info --skip '*/test/**' --skip '*/script/**' --force && slither --compile-force-framework foundry --ignore-compile --sarif results.sarif --config-file slither.config.json .

build:
	@./build.sh -p production

tests:
	@./test.sh -p default

gas:
	@./test.sh -p production -g

sizes:
	@./build.sh -p production -s

clean:
	forge clean

# Deployment targets
deploy-timelock:
	@echo "=== Deploying TimelockController ==="
	@echo "Network: ${ETH_RPC_URL}"
	@echo "Min Delay: ${TIMELOCK_MIN_DELAY}"
	@echo "Proposers: ${TIMELOCK_PROPOSERS}"
	@echo "Executors: ${TIMELOCK_EXECUTORS}"
	@echo "Admin: ${TIMELOCK_ADMIN}"
	@forge script script/deploy/DeployTimelock.sol:DeployTimelock \
		${TIMELOCK_MIN_DELAY} \
		"[${TIMELOCK_PROPOSERS}]" \
		"[${TIMELOCK_EXECUTORS}]" \
		${TIMELOCK_ADMIN} \
		--rpc-url ${ETH_RPC_URL} \
		--private-key ${PRIVATE_KEY} \
		--broadcast \
		--verify \
		--etherscan-api-key ${ETHERSCAN_API_KEY} \
		-vvv
