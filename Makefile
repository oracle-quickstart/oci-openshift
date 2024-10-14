.PHONY: all
all: pre-commit zip

.PHONY: pre-commit
pre-commit:
	pre-commit run --all-files

.phony: zip
zip:
	rm -f infrastructure.zip
	zip infrastructure.zip infrastructure/*
