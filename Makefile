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

.PHONY: manifest
manifest:
	rm -f single-manifest.yml

	for filename in ./custom_manifests/manifests/* ; do \
		echo "# $$filename" >> single-manifest.yml ; \
		cat $$filename >> single-manifest.yml ; \
		echo "---" >> single-manifest.yml ; \
	done
