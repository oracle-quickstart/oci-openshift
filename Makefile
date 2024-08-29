.PHONY: all
all: pre-commit

.PHONY: pre-commit
pre-commit:
	pre-commit run --all-files
