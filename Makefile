ligo_compiler?=docker run --rm -v "$(PWD)":"$(PWD)" -w "$(PWD)" ligolang/ligo:stable
# ^ Override this variable when you run make command by make <COMMAND> ligo_compiler=<LIGO_EXECUTABLE>
# ^ Otherwise use default one (you'll need docker)
PROJECTROOT_OPT?=--project-root .
PROTOCOL_OPT?=
JSON_OPT?=--michelson-format json
tsc=npx tsc
help:
	@echo  'Usage:'
	@echo  '  all             - Remove generated Michelson files, recompile smart contracts and lauch all tests'
	@echo  '  clean           - Remove generated Michelson files'
	@echo  '  compile         - Compiles smart contract Factory'
	@echo  '  test            - Run integration tests (written in Ligo)'
	@echo  '  deploy          - Deploy smart contracts advisor & indice (typescript using Taquito)'
	@echo  ''

all: clean compile test

compile: fa2_nft.tz factory marketplace_nft.tz

factory: factory.tz factory.json

factory.tz: contracts/main.jsligo
	@echo "Compiling smart contract to Michelson"
	@mkdir -p compiled
	@$(ligo_compiler) compile contract $^ -e main $(PROTOCOL_OPT) $(PROJECTROOT_OPT) > compiled/$@

factory.json: contracts/main.jsligo
	@echo "Compiling smart contract to Michelson in JSON format"
	@mkdir -p compiled
	@$(ligo_compiler) compile contract $^ $(JSON_OPT) -e main $(PROTOCOL_OPT) $(PROJECTROOT_OPT) > compiled/$@

fa2_nft.tz: contracts/generic_fa2/core/instance/NFT.mligo
	@echo "Compiling smart contract FA2 to Michelson"
	@mkdir -p contracts/generic_fa2/compiled
	@$(ligo_compiler) compile contract $^ -e main $(PROTOCOL_OPT) $(PROJECTROOT_OPT) > contracts/generic_fa2/compiled/$@

marketplace_nft.tz: contracts/marketplace/main.jsligo
	@echo "Compiling smart contract Marketplace to Michelson"
	@mkdir -p contracts/marketplace/compiled
	@$(ligo_compiler) compile contract $^ -e main $(PROTOCOL_OPT) $(PROJECTROOT_OPT) > contracts/marketplace/compiled/$@

clean: clean_contracts clean_fa2 clean_marketplace

clean_contracts:
	@echo "Removing Michelson files"
	@rm -f compiled/*.tz compiled/*.json

clean_fa2:
	@echo "Removing FA2 Michelson file"
	@rm -f contracts/generic_fa2/compiled/*.tz

clean_marketplace:
	@echo "Removing Marketplace Michelson file"
	@rm -f contracts/marketplace/compiled/*.tz


test: test_ligo test_marketplace

test_ligo: test/test.jsligo
	@echo "Running integration tests"
	@$(ligo_compiler) run test $^ $(PROTOCOL_OPT) $(PROJECTROOT_OPT)

test_marketplace: test/test_marketplace.jsligo
	@echo "Running integration tests (marketplace)"
	@$(ligo_compiler) run test $^ $(PROTOCOL_OPT) $(PROJECTROOT_OPT)

deploy: deploy_node_modules deploy.js
	@echo "Deploying contract"
	@node deploy/deploy.js

deploy.js:
	@cd deploy && $(tsc) deploy.ts --resolveJsonModule -esModuleInterop

deploy_node_modules:
	@echo "Install node modules"
	@cd deploy && npm install
