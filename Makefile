# coverage report
coverage :; forge coverage --report lcov && lcov --remove ./lcov.info -o ./lcov.info 'script/*' 'test/*' && genhtml lcov.info --branch-coverage --output-dir coverage

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
