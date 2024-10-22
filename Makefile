.PHONY: all
all: pre-commit zip

.PHONY: pre-commit
pre-commit:
	pre-commit run --all-files

.PHONY: zip
zip:
	rm -f infrastructure.zip
	cd infrastructure && zip -r ../infrastructure.zip . -x .terraform/\* -x .\*

	rm -f tagging-resources.zip
	zip tagging-resources.zip tagging-resources/*
