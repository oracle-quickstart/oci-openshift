.PHONY: all
all: pre-commit zip

.PHONY: pre-commit
pre-commit:
	pre-commit run --all-files

.phony: zip
zip:
	rm -f infrastructure.zip
	zip -r infrastructure.zip infrastructure/*

	rm -f tagging-resources.zip
	zip tagging-resources.zip tagging-resources/*
