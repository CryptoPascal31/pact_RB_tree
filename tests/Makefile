.NOTPARALLEL:

all: test

test-basic:
	pact test-rb-tree-basic.repl

test-gas-100:
	@echo "Test Gas 100"
	python3 gen_test_vectors.py 75 50 > test-vectors-gas.pact
	pact test-rb-tree-gas.repl | python3 analyze-gas.py

test-gas-1000:
	@echo "Test Gas 1000"
	python3 gen_test_vectors.py 1000 100 > test-vectors-gas.pact
	pact test-rb-tree-gas.repl | python3 analyze-gas.py

test-gas-10000:
	@echo "Test Gas 10000"
	python3 gen_test_vectors.py 10000 100 > test-vectors-gas.pact
	pact test-rb-tree-gas.repl | python3 analyze-gas.py

test-consistency:
	@echo "Test Consistency"
	python3 gen_test_vectors.py 5000 100 > test-vectors.pact
	pact test-rb-tree-consistency.repl | python3 analyze-consistency.py

test: test-basic test-consistency test-gas-100 test-gas-1000 test-gas-10000

clean:
	rm -rf test-vectors.pact test-vectors-gas.pact
