.PHONY: all
all: pre-commit zip

.PHONY: pre-commit
pre-commit:
	pre-commit run --all-files

.PHONY: zip
zip:
	zip -j infrastructure.zip infrastructure/data.tf infrastructure/locals.tf infrastructure/main.tf infrastructure/output.tf infrastructure/schema.yaml infrastructure/variables.tf
