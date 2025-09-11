SHELL = bash

PKG_VERSION ?= v1.4.1
OCI_DRIVER_VERSION ?= v1.32.0

PRE_COMMIT := $(shell command -v pre-commit 2> /dev/null)
PODMAN := $(shell command -v podman 2> /dev/null)
OC := $(shell command -v oc 2> /dev/null)

.PHONY: all
all: precommit machineconfigs manifests version checksums zip

.PHONY: precommit
precommit:
ifdef PRE_COMMIT
	$(info Running pre-commit...)
	pre-commit run --all-files
else
	$(warning pre-commit not installed. Skipping...)
endif

.PHONY: zip
zip:
	$(info Zipping all terraform-stacks...)

	@if [ ! -d dist ]; then \
		mkdir dist ; \
	fi

	@cd terraform-stacks ; \
	for stack in * ; do \
		if [ -d $$stack ] && [ "$$stack" != "shared_modules" ]; then \
			cd $$stack ; \
			zip -FS -r -q ../../dist/$$stack-${PKG_VERSION}.zip * -x **/.terraform/\* -x \.* ; \
			zip -FS -r -q ../../dist/$$stack.zip * -x **/.terraform/\* -x \.* ; \
			cd .. ; \
		fi ; \
	done

.PHONY: manifests
manifests:
	$(info Creating condensed-manifest.yml...)
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


# generate individual file checksums and zipped stack checksums
.PHONY: checksums
checksums:
	$(info Writing checksums...)

	@if [ ! -d checksums ]; then \
		mkdir checksums ; \
	fi

	@find ./custom_manifests -type f -name '*.yml' -print0 | sort -z | xargs -0 shasum -a 256 > checksums/custom_manifests.SHA256SUMS
	@find ./terraform-stacks -type f -name '*.tf' -print0 | sort -z | xargs -0 shasum -a 256 > checksums/terraform-stacks.SHA256SUMS

	@cd terraform-stacks ; \
	for stack in * ; do \
		if [ -d $$stack ] && [ "$$stack" != "shared_modules" ]; then \
			cd $$stack ; \
			find . -type f -name '*.tf' -print0 | sort -z | xargs -0 shasum -a 256 > $$stack.SHA256SUMS ; \
			cd .. ; \
		fi ; \
	done

.PHONY: version
version:
	$(info Using PKG_VERSION=$(PKG_VERSION)...)

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
	$(info Cleaning up...)

	rm -rvf dist
	rm -rvf checksums
	find . -type f -name '*.SHA256SUMS' -print0 | xargs -0 rm -v

# export KUBECONFIG=<path_to_kubeconfig>
# make update-drivers OCI_DRIVER_VERSION=v1.32.0
.PHONY: update-drivers
update-drivers:
ifdef OC
	$(info "Updating OCI CCM and CSI drivers to ${OCI_DRIVER_VERSION}")
	oc apply -f custom_manifests/oci-ccm-csi-drivers/${OCI_DRIVER_VERSION}/01-oci-ccm.yml
	oc apply -f custom_manifests/oci-ccm-csi-drivers/${OCI_DRIVER_VERSION}/01-oci-csi.yml
else
	$(warning "'oc' not installed. Cancelling driver update...")
endif
