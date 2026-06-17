SHELL = bash

PKG_VERSION ?= v1.5.1
OCI_DRIVER_VERSION ?= v1.34.0

PRE_COMMIT := $(shell command -v pre-commit 2> /dev/null)
PODMAN := $(shell command -v podman 2> /dev/null)
OC := $(shell command -v oc 2> /dev/null)

REQUEST_TIMEOUT ?= 60s
AUTOSCALER_NAMESPACE ?= oci-capi-operator
AUTOSCALER_NAME ?= ociclusterautoscaler
AUTOSCALER_CLUSTER_NAMESPACE ?= capi-system
AUTOSCALER_CLUSTER_NAME ?=
AUTOSCALER_LABEL_SELECTOR ?= capi.openshift.io/managed-by=$(AUTOSCALER_NAME)
AUTOSCALER_PROVIDER_INSTALLER_JOB ?= oci-capi-operator-provider-installer
AUTOSCALER_DELETE_NAMESPACE ?= false

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

	@podman run -i --rm quay.io/coreos/butane:release --pretty --strict < custom_manifests/butane/vlan-bm-mtu-configure-master.bu > custom_manifests/manifests/07-configure-bm-vlan-mtu.yml
	@echo '---' >> custom_manifests/manifests/07-configure-bm-vlan-mtu.yml
	@podman run -i --rm quay.io/coreos/butane:release --pretty --strict < custom_manifests/butane/vlan-bm-mtu-configure-worker.bu >> custom_manifests/manifests/07-configure-bm-vlan-mtu.yml
	@echo '---' >> custom_manifests/manifests/07-configure-bm-vlan-mtu.yml


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

.PHONY: cleanup-autoscaler
cleanup-autoscaler:
	CONFIRM_OPERATOR_ONLY_TEARDOWN=true $(MAKE) cleanup-operator-only AUTOSCALER_DELETE_NAMESPACE=true

.PHONY: cleanup-autoscaler-full
cleanup-autoscaler-full:
	CONFIRM_PROVIDER_TEARDOWN=true $(MAKE) cleanup-capi-autoscaler

.PHONY: cleanup-operator-only
cleanup-operator-only:
	@test "$(CONFIRM_OPERATOR_ONLY_TEARDOWN)" = "true" || (echo "Refusing operator cleanup. Re-run with CONFIRM_OPERATOR_ONLY_TEARDOWN=true." >&2; exit 1)
ifdef OC
	@if oc get ociclusterautoscaler -n $(AUTOSCALER_NAMESPACE) $(AUTOSCALER_NAME) >/dev/null 2>&1; then \
		oc delete ociclusterautoscaler -n $(AUTOSCALER_NAMESPACE) $(AUTOSCALER_NAME) --ignore-not-found=true --wait=false --request-timeout=$(REQUEST_TIMEOUT) || true; \
		oc patch ociclusterautoscaler -n $(AUTOSCALER_NAMESPACE) $(AUTOSCALER_NAME) --type=merge -p '{"metadata":{"finalizers":[]}}' --request-timeout=$(REQUEST_TIMEOUT) || true; \
	else \
		echo "OCIClusterAutoscaler $(AUTOSCALER_NAMESPACE)/$(AUTOSCALER_NAME) not found; continuing cleanup."; \
	fi
	oc -n $(AUTOSCALER_NAMESPACE) delete deployment oci-capi-operator-controller-manager --ignore-not-found=true --request-timeout=$(REQUEST_TIMEOUT)
	oc -n $(AUTOSCALER_NAMESPACE) delete job $(AUTOSCALER_PROVIDER_INSTALLER_JOB) oci-capi-operator-activate-after-install --ignore-not-found=true --wait=false --request-timeout=$(REQUEST_TIMEOUT)
	oc -n $(AUTOSCALER_NAMESPACE) delete configmap oci-capi-operator-config oci-capi-operator-runtime-manifest --ignore-not-found=true --request-timeout=$(REQUEST_TIMEOUT)
	oc -n $(AUTOSCALER_NAMESPACE) delete serviceaccount oci-capi-operator-controller-manager oci-capi-operator-activator --ignore-not-found=true --request-timeout=$(REQUEST_TIMEOUT)
	oc -n $(AUTOSCALER_NAMESPACE) delete role oci-capi-operator-leader-election-role --ignore-not-found=true --request-timeout=$(REQUEST_TIMEOUT)
	oc -n $(AUTOSCALER_NAMESPACE) delete rolebinding oci-capi-operator-leader-election-rolebinding --ignore-not-found=true --request-timeout=$(REQUEST_TIMEOUT)
	oc delete clusterrole oci-capi-operator-manager-role oci-capi-operator-ociclusterautoscaler-editor-role oci-capi-operator-ociclusterautoscaler-viewer-role --ignore-not-found=true --request-timeout=$(REQUEST_TIMEOUT)
	oc delete clusterrolebinding oci-capi-operator-manager-rolebinding oci-capi-operator-oci-capi-operator-admin oci-capi-operator-activator-admin oci-capi-operator-capoci-privileged-scc --ignore-not-found=true --request-timeout=$(REQUEST_TIMEOUT)
	oc delete validatingwebhookconfiguration oci-capi-operator-validating-webhook-configuration --wait=false --ignore-not-found=true --request-timeout=$(REQUEST_TIMEOUT)
	oc delete mutatingwebhookconfiguration oci-capi-operator-mutating-webhook-configuration --wait=false --ignore-not-found=true --request-timeout=$(REQUEST_TIMEOUT)
	oc delete crd ociclusterautoscalers.capi.openshift.io --ignore-not-found=true --request-timeout=$(REQUEST_TIMEOUT)
	@if [ "$(AUTOSCALER_DELETE_NAMESPACE)" = "true" ] && [ "$(AUTOSCALER_NAMESPACE)" != "default" ]; then \
		oc delete ns $(AUTOSCALER_NAMESPACE) --ignore-not-found=true --wait=false --request-timeout=$(REQUEST_TIMEOUT); \
	fi
else
	$(warning "'oc' not installed. Cancelling autoscaler cleanup...")
endif

.PHONY: cleanup-provider-finalizers
cleanup-provider-finalizers:
	@test "$(CONFIRM_PROVIDER_FINALIZER_CLEANUP)" = "true" || (echo "Refusing provider finalizer cleanup. Re-run with CONFIRM_PROVIDER_FINALIZER_CLEANUP=true." >&2; exit 1)
ifdef OC
	@cluster_names="$$( { \
		[ -n "$(AUTOSCALER_CLUSTER_NAME)" ] && printf '%s\n' "$(AUTOSCALER_CLUSTER_NAME)"; \
		oc get clusters.cluster.x-k8s.io -n $(AUTOSCALER_CLUSTER_NAMESPACE) -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null || true; \
		oc get machinedeployments.cluster.x-k8s.io -n $(AUTOSCALER_CLUSTER_NAMESPACE) -o jsonpath='{range .items[*]}{.spec.clusterName}{"\n"}{end}' 2>/dev/null || true; \
		oc get machinesets.cluster.x-k8s.io -n $(AUTOSCALER_CLUSTER_NAMESPACE) -o jsonpath='{range .items[*]}{.spec.clusterName}{"\n"}{end}' 2>/dev/null || true; \
		oc get machines.cluster.x-k8s.io -n $(AUTOSCALER_CLUSTER_NAMESPACE) -o jsonpath='{range .items[*]}{.spec.clusterName}{"\n"}{end}' 2>/dev/null || true; \
	} | sed '/^$$/d' | sort -u )"; \
	if [ -n "$$cluster_names" ]; then \
		echo "Discovered CAPI cluster names in namespace $(AUTOSCALER_CLUSTER_NAMESPACE): $$cluster_names"; \
	else \
		echo "No CAPI cluster names discovered in namespace $(AUTOSCALER_CLUSTER_NAMESPACE)."; \
	fi; \
	printf '%s\n' "$$cluster_names" > /tmp/oci-capi-autoscaler-cleanup-clusters
	@echo "Deleting provider-managed resources in namespace $(AUTOSCALER_CLUSTER_NAMESPACE) matching label selector: $(AUTOSCALER_LABEL_SELECTOR)"
	@for r in machines.cluster.x-k8s.io machinesets.cluster.x-k8s.io machinedeployments.cluster.x-k8s.io ocimachines.infrastructure.cluster.x-k8s.io ocimachinetemplates.infrastructure.cluster.x-k8s.io clusters.cluster.x-k8s.io ociclusters.infrastructure.cluster.x-k8s.io ociclusteridentities.infrastructure.cluster.x-k8s.io; do \
		oc delete $$r -n $(AUTOSCALER_CLUSTER_NAMESPACE) -l '$(AUTOSCALER_LABEL_SELECTOR)' --ignore-not-found=true --wait=false --request-timeout=$(REQUEST_TIMEOUT) >/dev/null 2>&1 || true; \
	done
	@while read cluster_name; do \
		[ -n "$$cluster_name" ] || continue; \
		echo "Deleting CAPI resources in namespace $(AUTOSCALER_CLUSTER_NAMESPACE) for cluster $$cluster_name"; \
		for r in machines.cluster.x-k8s.io machinesets.cluster.x-k8s.io machinedeployments.cluster.x-k8s.io ocimachines.infrastructure.cluster.x-k8s.io ocimachinetemplates.infrastructure.cluster.x-k8s.io; do \
			oc delete $$r -n $(AUTOSCALER_CLUSTER_NAMESPACE) -l "cluster.x-k8s.io/cluster-name=$$cluster_name" --ignore-not-found=true --wait=false --request-timeout=$(REQUEST_TIMEOUT) >/dev/null 2>&1 || true; \
		done; \
		for r in clusters.cluster.x-k8s.io ociclusters.infrastructure.cluster.x-k8s.io ociclusteridentities.infrastructure.cluster.x-k8s.io; do \
			oc delete $$r "$$cluster_name" -n $(AUTOSCALER_CLUSTER_NAMESPACE) --ignore-not-found=true --wait=false --request-timeout=$(REQUEST_TIMEOUT) >/dev/null 2>&1 || true; \
		done; \
	done < /tmp/oci-capi-autoscaler-cleanup-clusters
	@echo "Waiting for provider-managed resources to delete before finalizer fallback"
	@for r in machines.cluster.x-k8s.io machinesets.cluster.x-k8s.io machinedeployments.cluster.x-k8s.io ocimachines.infrastructure.cluster.x-k8s.io ocimachinetemplates.infrastructure.cluster.x-k8s.io clusters.cluster.x-k8s.io ociclusters.infrastructure.cluster.x-k8s.io ociclusteridentities.infrastructure.cluster.x-k8s.io; do \
		oc wait --for=delete $$r -n $(AUTOSCALER_CLUSTER_NAMESPACE) -l '$(AUTOSCALER_LABEL_SELECTOR)' --timeout=$(REQUEST_TIMEOUT) >/dev/null 2>&1 || true; \
	done
	@while read cluster_name; do \
		[ -n "$$cluster_name" ] || continue; \
		for r in machines.cluster.x-k8s.io machinesets.cluster.x-k8s.io machinedeployments.cluster.x-k8s.io ocimachines.infrastructure.cluster.x-k8s.io ocimachinetemplates.infrastructure.cluster.x-k8s.io; do \
			oc wait --for=delete $$r -n $(AUTOSCALER_CLUSTER_NAMESPACE) -l "cluster.x-k8s.io/cluster-name=$$cluster_name" --timeout=$(REQUEST_TIMEOUT) >/dev/null 2>&1 || true; \
		done; \
		for r in clusters.cluster.x-k8s.io ociclusters.infrastructure.cluster.x-k8s.io ociclusteridentities.infrastructure.cluster.x-k8s.io; do \
			if oc get $$r "$$cluster_name" -n $(AUTOSCALER_CLUSTER_NAMESPACE) >/dev/null 2>&1; then \
				oc wait --for=delete $$r "$$cluster_name" -n $(AUTOSCALER_CLUSTER_NAMESPACE) --timeout=$(REQUEST_TIMEOUT) >/dev/null 2>&1 || true; \
			fi; \
		done; \
	done < /tmp/oci-capi-autoscaler-cleanup-clusters
	@echo "Removing provider-managed finalizers in namespace $(AUTOSCALER_CLUSTER_NAMESPACE)"
	@for r in machines.cluster.x-k8s.io machinesets.cluster.x-k8s.io machinedeployments.cluster.x-k8s.io ocimachines.infrastructure.cluster.x-k8s.io ocimachinetemplates.infrastructure.cluster.x-k8s.io clusters.cluster.x-k8s.io ociclusters.infrastructure.cluster.x-k8s.io ociclusteridentities.infrastructure.cluster.x-k8s.io; do \
		oc get $$r -n $(AUTOSCALER_CLUSTER_NAMESPACE) -l '$(AUTOSCALER_LABEL_SELECTOR)' --no-headers -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name' 2>/dev/null | while read ns name; do \
			[ -n "$$name" ] || continue; \
			echo "$$r $$ns/$$name"; \
			oc patch $$r "$$name" -n "$$ns" --type=merge -p '{"metadata":{"finalizers":[]}}' --request-timeout=$(REQUEST_TIMEOUT) || true; \
		done; \
	done
	@while read cluster_name; do \
		[ -n "$$cluster_name" ] || continue; \
		echo "Removing CAPI finalizers in namespace $(AUTOSCALER_CLUSTER_NAMESPACE) for cluster $$cluster_name"; \
		for r in machines.cluster.x-k8s.io machinesets.cluster.x-k8s.io machinedeployments.cluster.x-k8s.io ocimachines.infrastructure.cluster.x-k8s.io ocimachinetemplates.infrastructure.cluster.x-k8s.io; do \
			oc get $$r -n $(AUTOSCALER_CLUSTER_NAMESPACE) -l "cluster.x-k8s.io/cluster-name=$$cluster_name" --no-headers -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name' 2>/dev/null | while read ns name; do \
				[ -n "$$name" ] || continue; \
				echo "$$r $$ns/$$name"; \
				oc patch $$r "$$name" -n "$$ns" --type=merge -p '{"metadata":{"finalizers":[]}}' --request-timeout=$(REQUEST_TIMEOUT) || true; \
			done; \
		done; \
		for r in clusters.cluster.x-k8s.io ociclusters.infrastructure.cluster.x-k8s.io ociclusteridentities.infrastructure.cluster.x-k8s.io; do \
			if oc get $$r "$$cluster_name" -n $(AUTOSCALER_CLUSTER_NAMESPACE) >/dev/null 2>&1; then \
				echo "$$r $(AUTOSCALER_CLUSTER_NAMESPACE)/$$cluster_name"; \
				oc patch $$r "$$cluster_name" -n $(AUTOSCALER_CLUSTER_NAMESPACE) --type=merge -p '{"metadata":{"finalizers":[]}}' --request-timeout=$(REQUEST_TIMEOUT) || true; \
			fi; \
		done; \
	done < /tmp/oci-capi-autoscaler-cleanup-clusters
else
	$(warning "'oc' not installed. Cancelling provider finalizer cleanup...")
endif

.PHONY: cleanup-provider-installer-resources
cleanup-provider-installer-resources:
	@test "$(CONFIRM_PROVIDER_INSTALLER_CLEANUP)" = "true" || (echo "Refusing provider-installer cleanup. Re-run with CONFIRM_PROVIDER_INSTALLER_CLEANUP=true." >&2; exit 1)
ifdef OC
	oc -n $(AUTOSCALER_NAMESPACE) delete job $(AUTOSCALER_PROVIDER_INSTALLER_JOB) --ignore-not-found=true --wait=false --request-timeout=$(REQUEST_TIMEOUT)
	oc -n capi-system delete deployment capi-manager capi-controller-manager oci-cluster-autoscaler --ignore-not-found=true --request-timeout=$(REQUEST_TIMEOUT)
	oc -n cluster-api-provider-oci-system delete deployment capoci-controller-manager --ignore-not-found=true --request-timeout=$(REQUEST_TIMEOUT)
	oc -n cert-manager delete deployment cert-manager cert-manager-cainjector cert-manager-webhook --ignore-not-found=true --request-timeout=$(REQUEST_TIMEOUT)
	oc delete validatingwebhookconfiguration capoci-validating-webhook-configuration capi-validating-webhook-configuration cert-manager-webhook --wait=false --ignore-not-found=true --request-timeout=$(REQUEST_TIMEOUT)
	oc delete mutatingwebhookconfiguration capoci-mutating-webhook-configuration capi-mutating-webhook-configuration cert-manager-webhook --wait=false --ignore-not-found=true --request-timeout=$(REQUEST_TIMEOUT)
	oc -n kube-system delete role cert-manager-cainjector:leaderelection cert-manager:leaderelection --ignore-not-found=true --request-timeout=$(REQUEST_TIMEOUT)
	oc -n kube-system delete rolebinding cert-manager-cainjector:leaderelection cert-manager:leaderelection --ignore-not-found=true --request-timeout=$(REQUEST_TIMEOUT)
	oc delete scc oci-capi --ignore-not-found=true --request-timeout=$(REQUEST_TIMEOUT)
	oc delete ns capi-system cluster-api-provider-oci-system cert-manager --wait=false --ignore-not-found=true --request-timeout=$(REQUEST_TIMEOUT)
	@oc get crd -o name 2>/dev/null | grep -E '/((clusterclasses|clusters|machinedeployments|machinedrainrules|machinehealthchecks|machinepools|machines|machinesets)\.cluster\.x-k8s\.io|(clusterresourcesetbindings|clusterresourcesets)\.addons\.cluster\.x-k8s\.io|extensionconfigs\.runtime\.cluster\.x-k8s\.io|(ocicluster|ocimachine|ocimanaged|ocivirtual).*\.infrastructure\.cluster\.x-k8s\.io|(certificaterequests|certificates|clusterissuers|issuers)\.cert-manager\.io|(challenges|orders)\.acme\.cert-manager\.io)$$' | while read crd; do \
		oc delete "$$crd" --ignore-not-found=true --request-timeout=$(REQUEST_TIMEOUT); \
	done || true
	@oc get clusterrole -o name 2>/dev/null | grep -E '/(capi-|capoci-|cert-manager|oci-cluster-autoscaler)' | while read role; do \
		oc delete "$$role" --ignore-not-found=true --request-timeout=$(REQUEST_TIMEOUT); \
	done || true
	@oc get clusterrolebinding -o name 2>/dev/null | grep -E '/(capi-|capoci-|cert-manager|oci-capi-operator-capoci-privileged-scc|oci-cluster-autoscaler)' | while read rolebinding; do \
		oc delete "$$rolebinding" --ignore-not-found=true --request-timeout=$(REQUEST_TIMEOUT); \
	done || true
	@for ns in capi-system cluster-api-provider-oci-system cert-manager; do \
		if oc get ns $$ns >/dev/null 2>&1; then \
			oc patch ns $$ns --type=json -p '[{"op":"remove","path":"/spec/finalizers"}]' || true; \
		fi; \
	done
else
	$(warning "'oc' not installed. Cancelling provider-installer cleanup...")
endif

.PHONY: cleanup-capi-autoscaler
cleanup-capi-autoscaler:
	@test "$(CONFIRM_PROVIDER_TEARDOWN)" = "true" || (echo "Refusing destructive cleanup. Re-run with CONFIRM_PROVIDER_TEARDOWN=true." >&2; exit 1)
ifdef OC
	oc -n $(AUTOSCALER_NAMESPACE) delete job $(AUTOSCALER_PROVIDER_INSTALLER_JOB) --ignore-not-found=true --wait=false --request-timeout=$(REQUEST_TIMEOUT)
	oc -n $(AUTOSCALER_NAMESPACE) delete deployment oci-capi-operator-controller-manager --ignore-not-found=true --wait=true --timeout=$(REQUEST_TIMEOUT)
	@if oc get ociclusterautoscaler -n $(AUTOSCALER_NAMESPACE) $(AUTOSCALER_NAME) >/dev/null 2>&1; then \
		oc delete ociclusterautoscaler -n $(AUTOSCALER_NAMESPACE) $(AUTOSCALER_NAME) --ignore-not-found=true --wait=false --request-timeout=$(REQUEST_TIMEOUT) || true; \
		oc patch ociclusterautoscaler -n $(AUTOSCALER_NAMESPACE) $(AUTOSCALER_NAME) --type=merge -p '{"metadata":{"finalizers":[]}}' --request-timeout=$(REQUEST_TIMEOUT) || true; \
	else \
		echo "OCIClusterAutoscaler $(AUTOSCALER_NAMESPACE)/$(AUTOSCALER_NAME) not found; continuing provider teardown."; \
	fi
	CONFIRM_PROVIDER_FINALIZER_CLEANUP=true $(MAKE) cleanup-provider-finalizers AUTOSCALER_CLUSTER_NAMESPACE='$(AUTOSCALER_CLUSTER_NAMESPACE)' AUTOSCALER_CLUSTER_NAME='$(AUTOSCALER_CLUSTER_NAME)' AUTOSCALER_LABEL_SELECTOR='$(AUTOSCALER_LABEL_SELECTOR)'
	CONFIRM_PROVIDER_INSTALLER_CLEANUP=true $(MAKE) cleanup-provider-installer-resources AUTOSCALER_NAMESPACE='$(AUTOSCALER_NAMESPACE)'
	CONFIRM_OPERATOR_ONLY_TEARDOWN=true $(MAKE) cleanup-operator-only AUTOSCALER_NAMESPACE='$(AUTOSCALER_NAMESPACE)' AUTOSCALER_NAME='$(AUTOSCALER_NAME)' AUTOSCALER_DELETE_NAMESPACE=true REQUEST_TIMEOUT='$(REQUEST_TIMEOUT)'
else
	$(warning "'oc' not installed. Cancelling provider teardown...")
endif

# export KUBECONFIG=<path_to_kubeconfig>
# make update-drivers OCI_DRIVER_VERSION=v1.34.0
.PHONY: update-drivers
update-drivers:
ifdef OC
	$(info "Updating OCI CCM and CSI drivers to ${OCI_DRIVER_VERSION}")
	oc apply -f custom_manifests/oci-ccm-csi-drivers/${OCI_DRIVER_VERSION}/01-oci-ccm.yml
	oc apply -f custom_manifests/oci-ccm-csi-drivers/${OCI_DRIVER_VERSION}/01-oci-csi.yml
else
	$(warning "'oc' not installed. Cancelling driver update...")
endif
