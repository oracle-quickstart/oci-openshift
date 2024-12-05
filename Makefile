SHELL = bash
PKG_VERSION ?= v1.0.0
PRE_COMMIT := $(shell command -v pre-commit 2> /dev/null)
PODMAN := $(shell command -v podman 2> /dev/null)

.PHONY: all
all: pre-commit machineconfigs manifests zip

.PHONY: pre-commit
pre-commit:
ifdef PRE_COMMIT
	$(info "Running pre-commit...")
	pre-commit run --all-files
else
	$(warning "pre-commit not installed. Skipping...")
endif

.PHONY: zip
zip: version checksums
	@echo "Packaging stacks with version ${PKG_VERSION}..."

	@if [ ! -d dist ]; then \
		mkdir dist ; \
	fi

	@cd terraform-stacks ; \
	for stack in * ; do \
		if [ -d $$stack ] && [ "$$stack" != "shared_modules" ]; then \
			cd $$stack ; \
			echo "Building $$stack-${PKG_VERSION}.zip" ; \
			zip -FS -r -q ../../dist/$$stack-${PKG_VERSION}.zip * -x **/.terraform/\* -x \.* ; \
			cd .. ; \
		fi ; \
	done

.PHONY: manifests
manifests:
	@echo "Creating condensed-manifest.yml..."
	@cat ./custom_manifests/manifests/* > custom_manifests/condensed-manifest.yml ; \

.PHONY: machineconfigs
machineconfigs:
ifdef PODMAN
	$(info Generating MachineConfigs from Butane...)

	@podman run -i --rm quay.io/coreos/butane:release --pretty --strict < custom_manifests/butane/oci-kubelet-providerid-master.bu > custom_manifests/manifests/02-machineconfig-ccm.yml
	@echo '---' >> custom_manifests/manifests/02-machineconfig-ccm.yml
	@podman run -i --rm quay.io/coreos/butane:release --pretty --strict < custom_manifests/butane/oci-kubelet-providerid-worker.bu >> custom_manifests/manifests/02-machineconfig-ccm.yml
	@echo '---' >> custom_manifests/manifests/02-machineconfig-ccm.yml

	@podman run -i --rm quay.io/coreos/butane:release --pretty --strict < custom_manifests/butane/iscsid-master.bu > custom_manifests/manifests/02-machineconfig-csi.yml
	@echo '---' >> custom_manifests/manifests/02-machineconfig-csi.yml
	@podman run -i --rm quay.io/coreos/butane:release --pretty --strict < custom_manifests/butane/iscsid-worker.bu >> custom_manifests/manifests/02-machineconfig-csi.yml
	@echo '---' >> custom_manifests/manifests/02-machineconfig-csi.yml

	@podman run -i --rm quay.io/coreos/butane:release --pretty --strict < custom_manifests/butane/oci-add-consistent-device-path-master.bu > custom_manifests/manifests/03-machineconfig-consistent-device-path.yml
	@echo '---' >> custom_manifests/manifests/03-machineconfig-consistent-device-path.yml
	@podman run -i --rm quay.io/coreos/butane:release --pretty --strict < custom_manifests/butane/oci-add-consistent-device-path-worker.bu >> custom_manifests/manifests/03-machineconfig-consistent-device-path.yml
	@echo '---' >> custom_manifests/manifests/03-machineconfig-consistent-device-path.yml

	@podman run -i --rm quay.io/coreos/butane:release --pretty --strict < custom_manifests/butane/oci-eval-user-data-master.bu > custom_manifests/manifests/05-oci-eval-user-data.yml
	@echo '---' >> custom_manifests/manifests/05-oci-eval-user-data.yml
	@podman run -i --rm quay.io/coreos/butane:release --pretty --strict < custom_manifests/butane/oci-eval-user-data-worker.bu >> custom_manifests/manifests/05-oci-eval-user-data.yml
	@echo '---' >> custom_manifests/manifests/05-oci-eval-user-data.yml
else
	$(warning podman not installed. Skipping...)
endif

.PHONY: checksums
checksums:
	@echo "Writing checksums..."

	@cd terraform-stacks ; \
	for stack in * ; do \
		if [ -d $$stack ] && [ "$$stack" != "shared_modules" ]; then \
			cd $$stack ; \
			shasum -a 256 *.tf > checksums ; \
			if [ -d manifests ]; then \
				shasum -a 256 manifests/* >> checksums ; \
			fi ; \
			cd .. ; \
		fi ; \
	done

.PHONY: version
version:
	@echo ${PKG_VERSION}

	@cd terraform-stacks ; \
	for stack in * ; do \
		if [ -d $$stack ] && [ "$$stack" != "shared_modules" ]; then \
			cd $$stack ; \
			printf "locals {\n  stack_version = \"${PKG_VERSION}\"\n}\n" > version.tf ; \
			cd .. ; \
		fi ; \
	done

.PHONY: clean
clean:
	@echo "Cleaning up..."

	rm -rvf dist
