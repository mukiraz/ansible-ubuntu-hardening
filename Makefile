# =============================================================================
# INFRASTRUCTURE AUTOMATION MAKEFILE (Centralized via .env)
# =============================================================================

# Include .env file and export its variables to the shell environment
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

# --- STRICT SECURITY FALLBACKS FOR ENVIRONMENT VARIABLES ---
CUSTOM_SSH_PORT       ?= 55555
ANSIBLE_SUDO_USER     ?= admin_user

# STAGING (LOCAL LAB) VARIABLES
STAGING_SSH_KEY_NAME  ?= id_ed25519_generic
STAGING_SERVER_IP     ?= 192.168.50.10
STAGING_ROOT_PASSWORD ?= placeholder_dont_use_in_prod
STAGING_INVENTORY     ?= ansible/inventories/staging

# PRODUCTION (LIVE SERVER) VARIABLES
PRODUCTION_SSH_KEY_NAME  ?= id_ed25519_prod_real
PRODUCTION_SERVER_IP     ?= 127.0.0.1
PRODUCTION_ROOT_PASSWORD ?= placeholder_dont_use_in_prod
PRODUCTION_INVENTORY     ?= ansible/inventories/production

# --- AUTOMATION CORE PLAYBOOKS ---
PLAYBOOK_BOOTSTRAP = ansible/playbooks/00_bootstrap_server.yml
PLAYBOOK_HARDEN    = ansible/playbooks/01_harden_server.yml

# --- PHONY TARGET DECLARATIONS ---
.PHONY: help create-env-file check-keys setup check-deps vagrant-up vagrant-destroy staging-push-root-key production-push-root-key staging-harden production-harden staging-bootstrap production-bootstrap staging-ssh-user production-ssh-user

create-env-file: ## Interactive wizard to securely generate the initial .env file
	@if [ -f .env ]; then \
		echo "WARNING: An existing .env file was detected!"; \
		read -p "Do you want to overwrite it? (y/N): " confirm; \
		if [ "$$confirm" != "y" ] && [ "$$confirm" != "Y" ]; then \
			echo "NOTICE: Operation aborted. Existing .env file remains untouched."; \
			exit 0; \
		fi \
	fi; \
	echo "============================================================================="; \
	echo "  ANSIBLE UBUNTU HARDENING - INTERACTIVE CONFIGURATION WIZARD"; \
	echo "============================================================================="; \
	echo "Default values are shown inside brackets []."; \
	echo "Press ENTER directly to keep the default fallback values."; \
	echo "-----------------------------------------------------------------------------"; \
	\
	read -p "1. Common Secure SSH Port [2222]: " port; \
	port=$${port:-2222}; \
	\
	read -p "2. Dedicated Administrator Username [admin_user]: " suser; \
	suser=$${suser:-admin_user}; \
	\
	read -p "3. Staging (Local Lab) SSH Key Name [id_ed25519_server]: " skey; \
	skey=$${skey:-id_ed25519_server}; \
	\
	read -p "4. Staging (Local Lab) Server IP Address [192.168.56.10]: " sip; \
	sip=$${sip:-192.168.56.10}; \
	\
	read -p "5. Staging (Local Lab) Default Root Password [placeholder_root_pass]: " spass; \
	spass=$${spass:-placeholder_root_pass}; \
	\
	read -p "6. Production (Live) SSH Key Name [id_ed25519_prod_real]: " pkey; \
	pkey=$${pkey:-id_ed25519_prod_real}; \
	\
	while [ -z "$$pip" ]; do \
		read -p "7. Production (Live) Server IP Address (Required): " pip; \
		if [ -z "$$pip" ]; then \
			echo "ERROR: Production server IP address cannot be empty!"; \
		fi \
	done; \
	\
	while [ -z "$$ppass" ]; do \
		read -p "8. Live Server Initial Temporary Root Password (e.g. xY8zPq9Wst...): " ppass; \
		if [ -z "$$ppass" ]; then \
			echo "ERROR: Initial root password cannot be empty!"; \
		fi \
	done; \
	\
	echo "# =============================================================================" > .env; \
	echo "# ENVIRONMENT CONTROL PANEL (Centralized Variables - Global Standard)" >> .env; \
	echo "# =============================================================================" >> .env; \
	echo "" >> .env; \
	echo "# --- GLOBAL SECURITY SETTINGS ---" >> .env; \
	echo "CUSTOM_SSH_PORT=$$port" >> .env; \
	echo "ANSIBLE_SUDO_USER=$$suser" >> .env; \
	echo "" >> .env; \
	echo "# --- STAGING (LOCAL LABORATORY) SETTINGS ---" >> .env; \
	echo "STAGING_SSH_KEY_NAME=$$skey" >> .env; \
	echo "STAGING_SERVER_IP=$$sip" >> .env; \
	echo "STAGING_ROOT_PASSWORD=$$spass" >> .env; \
	echo "" >> .env; \
	echo "# --- PRODUCTION (LIVE SERVER) SETTINGS ---" >> .env; \
	echo "PRODUCTION_SSH_KEY_NAME=$$pkey" >> .env; \
	echo "PRODUCTION_SERVER_IP=$$pip" >> .env; \
	echo "PRODUCTION_ROOT_PASSWORD=$$ppass" >> .env; \
	\
	echo "-----------------------------------------------------------------------------"; \
	echo "SUCCESS: Anonymous and secure .env file successfully generated!"; \
	echo "=============================================================================";

help: ## Display this help menu with all available automation targets
	@echo "Available Infrastructure Automation Commands:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# --- ENVIRONMENT PREPARATION & PREREQUISITES ---

check-keys: ## Verify local presence of SSH keys, generate separate keys if missing
	@if [ ! -f ~/.ssh/$(STAGING_SSH_KEY_NAME) ]; then \
		echo "NOTICE: Staging SSH key missing. Generating: ~/.ssh/$(STAGING_SSH_KEY_NAME)"; \
		ssh-keygen -t ed25519 -f ~/.ssh/$(STAGING_SSH_KEY_NAME) -N "" -C "ansible_staging"; \
	else \
		echo "SUCCESS: Staging SSH key verified: ~/.ssh/$(STAGING_SSH_KEY_NAME)"; \
	fi
	@if [ ! -f ~/.ssh/$(PRODUCTION_SSH_KEY_NAME) ]; then \
		echo "NOTICE: Production SSH key missing. Generating: ~/.ssh/$(PRODUCTION_SSH_KEY_NAME)"; \
		ssh-keygen -t ed25519 -f ~/.ssh/$(PRODUCTION_SSH_KEY_NAME) -N "" -C "ansible_production"; \
	else \
		echo "SUCCESS: Production SSH key verified: ~/.ssh/$(PRODUCTION_SSH_KEY_NAME)"; \
	fi

setup: check-keys ## Install local dependencies (Ansible, Vagrant, VirtualBox) on Ubuntu host
	@echo "NOTICE: Initializing Ubuntu host system preparation..."
	@sudo apt update
	@sudo apt install -y software-properties-common wget gpg curl git sshpass
	@if ! grep -q "ansible/ansible" /etc/apt/sources.list /etc/apt/sources.list.d/*; then \
		echo "NOTICE: Adding Ansible official PPA repository..."; \
		sudo add-apt-repository --yes --update ppa:ansible/ansible; \
	fi
	@sudo apt install -y ansible
	@if pgrep "VirtualBox|VBoxHeadless|VBoxSVC" > /dev/null; then \
		echo "WARNING: Active VirtualBox processes detected. Sending pkill signal for upgrade safety..."; \
		sudo pkill "VirtualBox|VBoxHeadless|VBoxSVC" || true; \
		sleep 3; \
	fi
	@if [ ! -f /usr/share/keyrings/hashicorp-archive-keyring.gpg ]; then \
		echo "NOTICE: Adding HashiCorp official repository and GPG signing key..."; \
		wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg; \
		echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $$(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list; \
	fi
	@sudo apt update
	@sudo apt install -y virtualbox
	@sudo apt install -y vagrant
	@echo "--------------------------------------------------"
	@echo "SUCCESS: Local environment components installed successfully!"
	@echo "Ansible Version: $$(ansible --version | head -n 1)"
	@echo "Vagrant Version: $$(vagrant --version)"
	@echo "--------------------------------------------------"

check-deps: ## Internal validation helper to ensure hypervisor services are accessible
	@which vagrant > /dev/null || (echo "ERROR: Vagrant executable not found! Please run 'make setup' first." && exit 1)
	@pgrep -f "VirtualBox|VBox" > /dev/null && echo "NOTICE: VirtualBox service engine is active." || true

# --- VAGRANT VIRTUAL LABORATORY MANAGEMENT ---

vagrant-up: check-deps check-keys ## Spin up or resume the local staging sandbox machine
	@echo "NOTICE: Validating local staging environment matrix..."
	@if [ -d "Vagrant" ]; then \
		STATUS=$$(cd Vagrant && vagrant status --machine-readable | grep ",state," | cut -d, -f4); \
		if [ "$$STATUS" = "running" ]; then \
			echo "SUCCESS: Staging sandbox instance is already running."; \
		elif [ "$$STATUS" = "poweroff" ] || [ "$$STATUS" = "saved" ]; then \
			echo "NOTICE: Resuming suspended local instance in headless mode..."; \
			cd Vagrant && vagrant up --provider=virtualbox; \
		else \
			echo "NOTICE: Launching pristine raw Ubuntu laboratory instance..."; \
			cd Vagrant && vagrant up; \
		fi; \
	else \
		echo "ERROR: Directory 'Vagrant' not found!"; exit 1; \
	fi

vagrant-destroy: ## Completely wipe out and purge the local laboratory instance
	@echo "WARNING: Purging local staging virtual instance completely..."
	cd Vagrant && vagrant destroy -f

# =============================================================================
# STEP 1: SSH PUBLIC KEY INJECTION OPERATIONS
# =============================================================================

staging-push-root-key: check-keys ## STEP 1 (STAGING): Authorize local SSH public key on raw sandbox root account
	@echo "NOTICE: Injecting staging public key into local sandbox root user space..."
	sshpass -p "$(STAGING_ROOT_PASSWORD)" ssh-copy-id -o StrictHostKeyChecking=no -p 22 -i ~/.ssh/$(STAGING_SSH_KEY_NAME).pub root@$(STAGING_SERVER_IP)
	@echo "SUCCESS: Key delivered. Testing passwordless execution layer..."
	ssh -i ~/.ssh/$(STAGING_SSH_KEY_NAME) -p 22 -o StrictHostKeyChecking=no root@$(STAGING_SERVER_IP) "echo 'SUCCESS: Staging SSH Key Authentication Loop Verified!'"

production-push-root-key: check-keys ## STEP 1 (PRODUCTION): Authorize production SSH public key on live server root
	@echo "WARNING: Injecting production public key into live target infrastructure..."
	@if [ "$(PRODUCTION_SERVER_IP)" = "127.0.0.1" ]; then \
		echo "ERROR: Aborting execution. PRODUCTION_SERVER_IP is unconfigured or mapped to localhost!"; \
		exit 1; \
	fi
	sshpass -p "$(PRODUCTION_ROOT_PASSWORD)" ssh-copy-id -o StrictHostKeyChecking=no -p 22 -i ~/.ssh/$(PRODUCTION_SSH_KEY_NAME).pub root@$(PRODUCTION_SERVER_IP)
	@echo "SUCCESS: Production key delivered. Verifying secure handshake..."
	ssh -i ~/.ssh/$(PRODUCTION_SSH_KEY_NAME) -p 22 -o StrictHostKeyChecking=no root@$(PRODUCTION_SERVER_IP) "echo 'SUCCESS: Production Live Server Handshake Established!'"

# =============================================================================
# STEP 2: CIS COMPLIANT OPERATING SYSTEM HARDENING
# =============================================================================

staging-harden: ## STEP 2 (STAGING): Execute CIS hardening playbook on local lab (Port 22 -> Custom)
	@echo "NOTICE: Initializing full CIS Security Baseline Hardening on local sandbox..."
	ANSIBLE_HOST_KEY_CHECKING=False \
	ansible-playbook -i $(STAGING_INVENTORY) \
	$(PLAYBOOK_HARDEN) \
	--private-key=~/.ssh/$(STAGING_SSH_KEY_NAME) \
	--extra-vars "ansible_host=$(STAGING_SERVER_IP) ansible_ssh_user=root ansible_port=22 custom_ssh_port=$(CUSTOM_SSH_PORT) run_heavy_updates=false sysctl_overwrite={}"

production-harden: ## STEP 2 (PRODUCTION): Execute CIS hardening playbook on live instance (Updates active)
	@echo "WARNING: Executing full CIS Security Baseline Hardening on live production node..."
	@if [ "$(PRODUCTION_SERVER_IP)" = "127.0.0.1" ]; then \
		echo "ERROR: Aborting execution. PRODUCTION_SERVER_IP is unconfigured or mapped to localhost!"; \
		exit 1; \
	fi
	ANSIBLE_HOST_KEY_CHECKING=False \
	ansible-playbook -i $(PRODUCTION_INVENTORY) \
	$(PLAYBOOK_HARDEN) \
	--private-key=~/.ssh/$(PRODUCTION_SSH_KEY_NAME) \
	--extra-vars "ansible_host=$(PRODUCTION_SERVER_IP) ansible_ssh_user=root ansible_port=22 custom_ssh_port=$(CUSTOM_SSH_PORT) run_heavy_updates=true sysctl_overwrite={}"

# =============================================================================
# STEP 3: ADMINISTRATOR PROVISIONING & ROOT ACCOUNT LOCKDOWN
# =============================================================================

staging-bootstrap: ## STEP 3 (STAGING): Access via custom port to provision secure sudo user and lock root
	@echo "NOTICE: Connecting via secure custom port to configure admin privilege layers..."
	ANSIBLE_HOST_KEY_CHECKING=False \
	ansible-playbook -i $(STAGING_INVENTORY) \
	$(PLAYBOOK_BOOTSTRAP) \
	--private-key=~/.ssh/$(STAGING_SSH_KEY_NAME) \
	--extra-vars "ansible_host=$(STAGING_SERVER_IP) ansible_ssh_user=root ansible_port=$(CUSTOM_SSH_PORT) created_username=$(ANSIBLE_SUDO_USER) ssh_key_path=~/.ssh/$(STAGING_SSH_KEY_NAME).pub"

production-bootstrap: ## STEP 3 (PRODUCTION): Connect via live custom port to provision secure user and lock root
	@echo "WARNING: Executing final server provisioning and root account lockdown on live node..."
	@if [ "$(PRODUCTION_SERVER_IP)" = "127.0.0.1" ]; then \
		echo "ERROR: Aborting execution. PRODUCTION_SERVER_IP is unconfigured or mapped to localhost!"; \
		exit 1; \
	fi
	ANSIBLE_HOST_KEY_CHECKING=False \
	ansible-playbook -i $(PRODUCTION_INVENTORY) \
	$(PLAYBOOK_BOOTSTRAP) \
	--private-key=~/.ssh/$(PRODUCTION_SSH_KEY_NAME) \
	--extra-vars "ansible_host=$(PRODUCTION_SERVER_IP) ansible_ssh_user=root ansible_port=$(CUSTOM_SSH_PORT) created_username=$(ANSIBLE_SUDO_USER) ssh_key_path=~/.ssh/$(PRODUCTION_SSH_KEY_NAME).pub"

# =============================================================================
# CONVENIENCE SSH TUNNELING SHORTCUTS
# =============================================================================

staging-ssh-user: ## Establish an instant passwordless SSH terminal with the Staging admin user
	ssh -i ~/.ssh/$(STAGING_SSH_KEY_NAME) -p $(CUSTOM_SSH_PORT) $(ANSIBLE_SUDO_USER)@$(STAGING_SERVER_IP) -o StrictHostKeyChecking=no

production-ssh-user: ## Establish an instant passwordless SSH terminal with the Live production user
	ssh -i ~/.ssh/$(PRODUCTION_SSH_KEY_NAME) -p $(CUSTOM_SSH_PORT) $(ANSIBLE_SUDO_USER)@$(PRODUCTION_SERVER_IP) -o StrictHostKeyChecking=no