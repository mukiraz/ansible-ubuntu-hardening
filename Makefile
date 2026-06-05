# =============================================================================
# INFRASTRUCTURE AUTOMATION MAKEFILE (Centralized via .env)
# =============================================================================

# Include .env file and export its variables to the shell environment
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

# --- STRICT SECURITY FALLBACKS FOR ENVIRONMENT VARIABLES ---
CUSTOM_SSH_PORT          ?= 55555
ANSIBLE_SUDO_USER        ?= admin_user

STAGING_SSH_PORT         ?= $(CUSTOM_SSH_PORT)
PRODUCTION_SSH_PORT      ?= $(CUSTOM_SSH_PORT)

STAGING_ROOT_SSH_PORT    ?= 22
PRODUCTION_ROOT_SSH_PORT ?= 22

# Staging (Local Lab) Environments
STAGING_SSH_KEY_NAME     ?= id_ed25519_generic
STAGING_SERVER_IP        ?= 192.168.56.10
STAGING_ROOT_PASSWORD    ?= placeholder_dont_use_in_prod
STAGING_INVENTORY        ?= ansible/inventories/staging

# Production (Live Server) Environments
PRODUCTION_SSH_KEY_NAME  ?= id_ed25519_prod_real
PRODUCTION_SERVER_IP     ?= 127.0.0.1
PRODUCTION_ROOT_PASSWORD ?= placeholder_dont_use_in_prod
PRODUCTION_INVENTORY     ?= ansible/inventories/production

# --- AUTOMATION CORE PLAYBOOKS ---
PLAYBOOK_BOOTSTRAP       := ansible/playbooks/00_bootstrap_server.yml
PLAYBOOK_HARDEN          := ansible/playbooks/01_harden_server.yml

# --- ANSI TERMINAL COLORS FOR LOGGING ---
COLOR_RESET              := \033[0m
COLOR_INFO               := \033[36m
COLOR_SUCCESS            := \033[32m
COLOR_WARN               := \033[33m
COLOR_ERROR              := \033[31m

# =============================================================================
# REUSABLE MACROS (DRY ENGINE)
# =============================================================================

# Function to inject public keys and provision initial sudo users using root access
# Arguments: 1=ROOT_PASS, 2=ROOT_PORT, 3=KEY_NAME, 4=SERVER_IP
define macro_push_root_key
	@echo "$(COLOR_INFO)NOTICE: Injecting root key and provisioning sudo user into target...$(COLOR_RESET)"
	sshpass -p "$(1)" ssh-copy-id -o StrictHostKeyChecking=no -p $(2) -i ~/.ssh/$(3).pub root@$(4)
	sshpass -p "$(1)" ssh -o StrictHostKeyChecking=no -p $(2) root@$(4) \
		"id -u $(ANSIBLE_SUDO_USER) >/dev/null 2>&1 || useradd -m -s /bin/bash -G sudo $(ANSIBLE_SUDO_USER)"
	sshpass -p "$(1)" ssh -o StrictHostKeyChecking=no -p $(2) root@$(4) "cat > /tmp/$(ANSIBLE_SUDO_USER).pub" < ~/.ssh/$(3).pub
	sshpass -p "$(1)" ssh -o StrictHostKeyChecking=no -p $(2) root@$(4) \
		"mkdir -p /home/$(ANSIBLE_SUDO_USER)/.ssh && chmod 700 /home/$(ANSIBLE_SUDO_USER)/.ssh && cat /tmp/$(ANSIBLE_SUDO_USER).pub >> /home/$(ANSIBLE_SUDO_USER)/.ssh/authorized_keys && chmod 600 /home/$(ANSIBLE_SUDO_USER)/.ssh/authorized_keys && chown -R $(ANSIBLE_SUDO_USER):$(ANSIBLE_SUDO_USER) /home/$(ANSIBLE_SUDO_USER)/.ssh && rm -f /tmp/$(ANSIBLE_SUDO_USER).pub"
	sshpass -p "$(1)" ssh -o StrictHostKeyChecking=no -p $(2) root@$(4) \
		"echo '$(ANSIBLE_SUDO_USER) ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/$(ANSIBLE_SUDO_USER) && chmod 440 /etc/sudoers.d/$(ANSIBLE_SUDO_USER)"
	@echo "$(COLOR_SUCCESS)SUCCESS: Sudo user configured. Verifying secure handshake...$(COLOR_RESET)"
	ssh -i ~/.ssh/$(3) -p $(2) -o StrictHostKeyChecking=no $(ANSIBLE_SUDO_USER)@$(4) "echo 'SUCCESS: Remote Server Sudo User Handshake Established!'"
endef

# Function to execute core Ansible playbooks uniformly
# Arguments: 1=INVENTORY, 2=PLAYBOOK, 3=KEY_NAME, 4=EXTRA_VARS
define macro_run_playbook
	ANSIBLE_HOST_KEY_CHECKING=False \
	ansible-playbook -i $(1) $(2) --private-key=~/.ssh/$(3) --extra-vars "$(4)"
endef

# =============================================================================
# PHONY TARGET DECLARATIONS
# =============================================================================
.PHONY: help create-env-file check-keys setup check-deps validate-prod-ip \
        vagrant-up vagrant-destroy staging-push-root-key production-push-root-key \
        staging-harden production-harden staging-bootstrap production-bootstrap \
        staging production staging-ssh-user production-ssh-user

help: ## Display this help menu with all available automation targets
	@echo "Available Infrastructure Automation Commands:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "$(COLOR_INFO)%-30s$(COLOR_RESET) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# =============================================================================
# ENVIRONMENT PREPARATION & VALIDATION
# =============================================================================

validate-prod-ip: # Internal safeguard to ensure production target IP is configured correctly
	@if [ "$(PRODUCTION_SERVER_IP)" = "127.0.0.1" ]; then \
		echo "$(COLOR_ERROR)ERROR: Aborting execution. PRODUCTION_SERVER_IP is unconfigured or mapped to localhost!$(COLOR_RESET)"; \
		exit 1; \
	fi

check-keys: ## Verify local presence of SSH keys, generate separate keys if missing
	@if [ ! -f ~/.ssh/$(STAGING_SSH_KEY_NAME) ]; then \
		echo "$(COLOR_WARN)NOTICE: Staging SSH key missing. Generating...$(COLOR_RESET)"; \
		ssh-keygen -t ed25519 -f ~/.ssh/$(STAGING_SSH_KEY_NAME) -N "" -C "ansible_staging"; \
	else \
		echo "$(COLOR_SUCCESS)SUCCESS: Staging SSH key verified.$(COLOR_RESET)"; \
	fi
	@if [ ! -f ~/.ssh/$(PRODUCTION_SSH_KEY_NAME) ]; then \
		echo "$(COLOR_WARN)NOTICE: Production SSH key missing. Generating...$(COLOR_RESET)"; \
		ssh-keygen -t ed25519 -f ~/.ssh/$(PRODUCTION_SSH_KEY_NAME) -N "" -C "ansible_production"; \
	else \
		echo "$(COLOR_SUCCESS)SUCCESS: Production SSH key verified.$(COLOR_RESET)"; \
	fi

setup: check-keys ## Install local system dependencies on the Ubuntu host machine
	@echo "$(COLOR_INFO)NOTICE: Initializing Ubuntu host system preparation...$(COLOR_RESET)"
	sudo apt update
	sudo apt install -y software-properties-common wget gpg curl git sshpass
	@if ! grep -q "ansible/ansible" /etc/apt/sources.list /etc/apt/sources.list.d/*; then \
		sudo add-apt-repository --yes --update ppa:ansible/ansible; \
	fi
	sudo apt install -y ansible
	@if pgrep "VirtualBox|VBoxHeadless|VBoxSVC" > /dev/null; then \
		echo "$(COLOR_WARN)WARNING: Active VirtualBox processes detected. Clearing for safe upgrades...$(COLOR_RESET)"; \
		sudo pkill "VirtualBox|VBoxHeadless|VBoxSVC" || true; \
		sleep 3; \
	fi
	@if [ ! -f /usr/share/keyrings/hashicorp-archive-keyring.gpg ]; then \
		wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg; \
		echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $$(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list; \
	fi
	sudo apt update && sudo apt install -y virtualbox vagrant
	@echo "--------------------------------------------------"
	@echo "$(COLOR_SUCCESS)SUCCESS: Local environment infrastructure components installed successfully!$(COLOR_RESET)"
	@echo "Ansible Version: $$(ansible --version | head -n 1)"
	@echo "Vagrant Version: $$(vagrant --version)"
	@echo "--------------------------------------------------"

check-deps: # Internal helper to validate hypervisor components
	@which vagrant > /dev/null || (echo "$(COLOR_ERROR)ERROR: Vagrant not found! Run 'make setup' first.$(COLOR_RESET)" && exit 1)
	@pgrep -f "VirtualBox|VBox" > /dev/null && echo "$(COLOR_INFO)NOTICE: VirtualBox core service engine is active.$(COLOR_RESET)" || true

# =============================================================================
# VAGRANT SANDBOX MANAGEMENT
# =============================================================================

vagrant-up: check-deps check-keys ## Launch or resume the host-isolated local laboratory sandbox
	@echo "$(COLOR_INFO)NOTICE: Validating local staging environment matrix...$(COLOR_RESET)"
	@if [ -d "Vagrant" ]; then \
		STATUS=$$(cd Vagrant && vagrant status --machine-readable | grep ",state," | cut -d, -f4); \
		if [ "$$STATUS" = "running" ]; then \
			echo "$(COLOR_SUCCESS)SUCCESS: Staging sandbox instance is already active.$(COLOR_RESET)"; \
		elif [ "$$STATUS" = "poweroff" ] || [ "$$STATUS" = "saved" ]; then \
			cd Vagrant && vagrant up --provider=virtualbox; \
		else \
			cd Vagrant && vagrant up; \
		fi; \
	else \
		echo "$(COLOR_ERROR)ERROR: Directory 'Vagrant' not found!$(COLOR_RESET)"; exit 1; \
	fi

vagrant-destroy: ## Wipe out and completely purge the local sandbox laboratory instance
	@echo "$(COLOR_WARN)WARNING: Purging local staging virtual instance completely...$(COLOR_RESET)"
	cd Vagrant && vagrant destroy -f

# =============================================================================
# STEP 1: SSH PUBLIC KEY INJECTION PIPELINES
# =============================================================================

staging-push-root-key: check-keys ## STEP 1 (STAGING): Inject key and provision sudo user into local sandbox
	$(call macro_push_root_key,$(STAGING_ROOT_PASSWORD),$(STAGING_ROOT_SSH_PORT),$(STAGING_SSH_KEY_NAME),$(STAGING_SERVER_IP))

production-push-root-key: validate-prod-ip check-keys ## STEP 1 (PRODUCTION): Inject key and provision sudo user into live target
	@echo "$(COLOR_INFO)INFO: Clearing stale host keys for security alignment...$(COLOR_RESET)"
	-ssh-keygen -f ~/.ssh/known_hosts -R "$(PRODUCTION_SERVER_IP)" 2>/dev/null
	$(call macro_push_root_key,$(PRODUCTION_ROOT_PASSWORD),$(PRODUCTION_ROOT_SSH_PORT),$(PRODUCTION_SSH_KEY_NAME),$(PRODUCTION_SERVER_IP))

# =============================================================================
# STEP 2: CIS COMPLIANT OPERATING SYSTEM HARDENING
# =============================================================================

staging-harden: ## STEP 2 (STAGING): Apply CIS compliance playbooks on local lab (Port 22 -> Custom)
	@echo "$(COLOR_INFO)NOTICE: Initializing full CIS Security Baseline Hardening on local sandbox...$(COLOR_RESET)"
	$(call macro_run_playbook,$(STAGING_INVENTORY),$(PLAYBOOK_HARDEN),$(STAGING_SSH_KEY_NAME),ansible_host=$(STAGING_SERVER_IP) ansible_ssh_user=root ansible_port=$(STAGING_ROOT_SSH_PORT) custom_ssh_port=$(CUSTOM_SSH_PORT) run_heavy_updates=false sysctl_overwrite={})

production-harden: validate-prod-ip ## STEP 2 (PRODUCTION): Apply CIS compliance playbooks on live remote instance
	@echo "$(COLOR_WARN)WARNING: Executing full CIS Security Baseline Hardening on live production node...$(COLOR_RESET)"
	$(call macro_run_playbook,$(PRODUCTION_INVENTORY),$(PLAYBOOK_HARDEN),$(PRODUCTION_SSH_KEY_NAME),ansible_host=$(PRODUCTION_SERVER_IP) ansible_ssh_user=root ansible_port=$(PRODUCTION_ROOT_SSH_PORT) custom_ssh_port=$(CUSTOM_SSH_PORT) run_heavy_updates=$(RUN_HEAVY_UPDATES) sysctl_overwrite={})

# =============================================================================
# STEP 3: PRIVILEGE DEPLOYMENT & ROOT LOCKDOWN
# =============================================================================

staging-bootstrap: ## STEP 3 (STAGING): Establish secure custom port access layer and lock down remote root
	@echo "$(COLOR_INFO)NOTICE: Connecting via secure custom port to seal root access privileges...$(COLOR_RESET)"
	$(call macro_run_playbook,$(STAGING_INVENTORY),$(PLAYBOOK_BOOTSTRAP),$(STAGING_SSH_KEY_NAME),ansible_host=$(STAGING_SERVER_IP) ansible_ssh_user=$(ANSIBLE_SUDO_USER) ansible_become=true ansible_become_method=sudo ansible_port=$(STAGING_SSH_PORT) created_username=$(ANSIBLE_SUDO_USER) ssh_key_path=$(HOME)/.ssh/$(STAGING_SSH_KEY_NAME).pub)

production-bootstrap: validate-prod-ip ## STEP 3 (PRODUCTION): Establish secure custom port access layer and lock down live root
	@echo "$(COLOR_WARN)WARNING: Executing final server provisioning and root account lockdown on live node...$(COLOR_RESET)"
	$(call macro_run_playbook,$(PRODUCTION_INVENTORY),$(PLAYBOOK_BOOTSTRAP),$(PRODUCTION_SSH_KEY_NAME),ansible_host=$(PRODUCTION_SERVER_IP) ansible_ssh_user=$(ANSIBLE_SUDO_USER) ansible_become=true ansible_become_method=sudo ansible_port=$(PRODUCTION_SSH_PORT) created_username=$(ANSIBLE_SUDO_USER) ssh_key_path=$(HOME)/.ssh/$(PRODUCTION_SSH_KEY_NAME).pub)

# =============================================================================
# MONOLITHIC AUTOMATION ORCHESTRATORS
# =============================================================================

staging: ## Execute full staging automation simulation lifecycle sequentially
	@echo "$(COLOR_SUCCESS) Starting Monolithic Staging Deployment Lifecycle against Sandbox Pipeline...$(COLOR_RESET)"
	$(MAKE) staging-push-root-key
	$(MAKE) staging-harden
	$(MAKE) staging-bootstrap
	@echo "$(COLOR_SUCCESS) Staging lifecycle complete. Sandbox is fully secure.$(COLOR_RESET)"

production: validate-prod-ip ## Execute full production automation deployment pipeline sequentially
	@echo "$(COLOR_WARN) WARNING: Executing full Production Deployment Lifecycle against live architecture...$(COLOR_RESET)"
	$(MAKE) production-push-root-key
	$(MAKE) production-harden
	$(MAKE) production-bootstrap
	@echo "$(COLOR_SUCCESS) Production lifecycle complete. Remote infrastructure secured.$(COLOR_RESET)"

# =============================================================================
# UTILITIES & QUICK CONVENIENCE SHORTCUTS
# =============================================================================

staging-ssh-user: ## Connect instantly to the local sandbox using the admin user profile
	ssh -i ~/.ssh/$(STAGING_SSH_KEY_NAME) -p $(STAGING_SSH_PORT) $(ANSIBLE_SUDO_USER)@$(STAGING_SERVER_IP) -o StrictHostKeyChecking=no

production-ssh-user: validate-prod-ip ## Connect instantly to the live production server using the admin user profile
	ssh -i ~/.ssh/$(PRODUCTION_SSH_KEY_NAME) -p $(PRODUCTION_SSH_PORT) $(ANSIBLE_SUDO_USER)@$(PRODUCTION_SERVER_IP) -o StrictHostKeyChecking=no

create-env-file: ## Interactive wizard to securely generate the initial .env file
	@if [ -f .env ]; then \
		echo "$(COLOR_WARN)WARNING: An existing .env file was detected!$(COLOR_RESET)"; \
		read -p "Do you want to overwrite it? (y/N): " confirm; \
		if [ "$$confirm" != "y" ] && [ "$$confirm" != "Y" ]; then \
			echo "NOTICE: Operation aborted. Configuration file remains unchanged."; \
			exit 0; \
		fi \
	fi; \
	echo "============================================================================="; \
	echo "  ANSIBLE UBUNTU HARDENING - INTERACTIVE CONFIGURATION WIZARD"; \
	echo "============================================================================="; \
	read -p "1. Common Secure SSH Port [Press ENTER for random secure port]: " port; \
	if [ -z "$$port" ]; then port=$$(shuf -i 2000-65000 -n 1); fi; \
	read -p "2. Dedicated Administrator Username [admin_user]: " suser; suser=$${suser:-admin_user}; \
	read -p "3. Staging (Local Lab) SSH Key Name [id_ed25519_server]: " skey; skey=$${skey:-id_ed25519_server}; \
	read -p "4. Staging (Local Lab) Server IP Address [192.168.56.10]: " sip; sip=$${sip:-192.168.56.10}; \
	read -p "5. Staging (Local Lab) Default Root Password [placeholder_root_pass]: " spass; spass=$${spass:-placeholder_root_pass}; \
	read -p "6. Production (Live) SSH Key Name [id_ed25519_prod_real]: " pkey; pkey=$${pkey:-id_ed25519_prod_real}; \
	read -p "7. Run Heavy OS Package Upgrades (dist-upgrade)? (true/false) [false]: " heavy; heavy=$${heavy:-false}; \
	while [ -z "$$pip" ]; do read -p "8. Production (Live) Server IP Address (Required): " pip; done; \
	while [ -z "$$ppass" ]; do read -p "9. Live Server Initial Temporary Root Password: " ppass; done; \
	echo "# =============================================================================\n# ENVIRONMENT CONTROL PANEL\n# =============================================================================\n" > .env; \
	echo "CUSTOM_SSH_PORT=$$port\nANSIBLE_SUDO_USER=$$suser\nRUN_HEAVY_UPDATES=$$heavy\n" >> .env; \
	echo "STAGING_SSH_KEY_NAME=$$skey\nSTAGING_SERVER_IP=$$sip\nSTAGING_ROOT_PASSWORD=$$spass\n" >> .env; \
	echo "PRODUCTION_SSH_KEY_NAME=$$pkey\nPRODUCTION_SERVER_IP=$$pip\nPRODUCTION_ROOT_PASSWORD=$$ppass" >> .env; \
	echo "-----------------------------------------------------------------------------"; \
	echo "$(COLOR_SUCCESS)SUCCESS: .env configuration generated successfully!$(COLOR_RESET)"; \
	echo "=============================================================================";