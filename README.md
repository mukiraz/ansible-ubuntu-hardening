# Infrastructure & Server Hardening (Ubuntu 24.04)

This project provides a comprehensive **Infrastructure as Code (IaC)** suite designed to automate the initial bootstrapping, secure configuration, and programmatic hardening (CIS Compliance) of Ubuntu 24.04 LTS servers using **Ansible**.

The architecture enforces a strict, two-tier "Real World" deployment and validation pipeline:

* **Staging:** A local Virtual Machine (orchestrated via Vagrant and VirtualBox) acting as a high-fidelity sandbox that identically mirrors the security policies, network rules, and system behavior of your live remote node.
* **Production:** Your remote, live Virtual Private Server (VPS) hosted with cloud infrastructure providers such as Contabo, DigitalOcean, or Hetzner.

By utilizing a centralized environment control panel, this framework isolates infrastructure variables from the underlying automation logic, ensuring secure, repeatable, and anonymous deployments across both target environments.

## 1. Security Standards & CIS Compliance

This project is engineered based on the official **CIS Ubuntu Linux 24.04 LTS Benchmark**. The hardening playbooks enforce industry-standard server security profiles to systematically minimize the attack surface in production environments.

### 1.1. Benchmark Reference
* **Standard:** CIS Ubuntu Linux 24.04 LTS Benchmark
* **Compliance Level:** Level 1 and Level 2 Server Profiles
* **Scope:** Core OS Hardening including Filesystem Restrictions (Section 1.1), Automated UFW Firewall Policies (Section 3), Secure SSH Daemon Specifications (Section 5), and Protective Kernel/Sysctl Parameter Tuning.

---

## 2. Goals of This Project

* **Idempotent Hardening:** Apply deterministic, repeatable security baselines across environments without altering system stability.
* **Zero Root Exposure:** Safely transition the target infrastructure from raw root password access to an isolated, dedicated administrator account enforced with ed25519 SSH key-based authentication.
* **Production-Ready Bastion:** Deliver a secure, clean, and fully hardened Ubuntu 24.04 LTS foundation ready to host critical enterprise workloads and modern containerized applications.

## 3. Repository Structure & Dependency Management

Here is the completed **Section 3** for your `README.md`, perfectly tailored to international standards. It describes the file tree concisely, explains how the external role was fetched, and provides the engineering rationale for the tailoring process—all in clean, technical English without any emojis.

### 3.1. Directory Tree


.
├── ansible
│   ├── ansible.cfg
│   ├── group_vars
│   │   ├── all.yml
│   │   ├── production.yml
│   │   └── staging.yml
│   ├── inventories
│   │   ├── group_vars
│   │   │   └── all.yml
│   │   ├── production
│   │   └── staging
│   ├── playbooks
│   │   ├── 00_bootstrap_server.yml
│   │   └── 01_harden_server.yml
│   └── roles
│       ├── bootstrap
│       │   └── tasks
│       ├── dev-sec.os-hardening
│       │   ├── ansible.cfg
│       │   ├── CHANGELOG.md
│       │   ├── CONTRIBUTING.md
│       │   ├── defaults
│       │   ├── Gemfile
│       │   ├── handlers
│       │   ├── kitchen_vagrant_block.rb
│       │   ├── meta
│       │   ├── Rakefile
│       │   ├── README.md
│       │   ├── rhel6_provision.rb
│       │   ├── suse_provision.rb
│       │   ├── tasks
│       │   ├── templates
│       │   ├── tests
│       │   ├── TODO.md
│       │   └── vars
│       └── ubuntu_hardening
│           ├── defaults
│           ├── handlers
│           └── tasks
├── LICENSE
├── Makefile
├── README.md
└── Vagrant
    └── Vagrantfile


### 3.2. Vendor Role Acquisition

The core security hardening engine utilizes the industry-proven `dev-sec.os-hardening` framework. To keep this repository completely standalone, immutable, and capable of operating in air-gapped environments without runtime internet dependencies, the role was vendorshipped locally into the source tree.

This extraction was executed directly from the project root via the Ansible Galaxy package manager:

```bash
ansible-galaxy role install dev-sec.os-hardening -p ./ansible/roles/

```

By embedding the vendor codebase into `./ansible/roles/dev-sec.os-hardening`, we guarantee absolute consistency across deployment runs and eliminate the risk of upstream modifications breaking our automated pipelines.

### 3.3. Tailoring & Customization Strategy

Out-of-the-box, the `dev-sec.os-hardening` framework applies aggressive kernel optimizations and network parameters that fully disable packet forwarding. While this minimizes the host attack surface, it conflicts with container runtimes (such as Docker or Podman) by severing bridge networking and isolating container traffic.

To harmonize elite CIS compliance with modern microservices stacks, a custom abstraction layer was implemented within `ansible/group_vars/all.yml` to safely override conflicting kernel controls:

```yaml
# Enforcing custom overrides to sustain Docker network packet forwarding
sysctl_overwrite:
  net.ipv4.ip_forward: 1
  net.ipv4.conf.all.forwarding: 1
  net.ipv6.conf.all.forwarding: 1
  fs.protected_hardlinks: 1
  fs.protected_symlinks: 1

security_init_network_ipv4_forwarding: true
security_restrict_core_dumps: true

```

#### 3.3.1. Key Tailoring Mechanisms:

* **Container Network Retention:** The `sysctl_overwrite` dictionary intercepts the vendor's enforcement loops, explicitly sustaining the network forwarding capabilities required for container-to-container routing.

* **Variable Precedence Mapping:** By injecting these parameters through global variable scopes, Ansible enforces our local customizations over vendor defaults (`defaults/main.yml`) seamlessly, without requiring manual patches to the underlying upstream source files.



Here is the streamlined, command-focused **Section 4** for your `README.md`. It highlights your automation pipeline, explicitly underscores the importance of cloud credentials during the environment setup, and guides users through the step-by-step execution matrix in clean, professional English with all emojis stripped.

## 4. Installation The Dependencies

The entire infrastructure lifecycle is optimized through centralized `make` commands. Follow the sequence below to provision, validate, and harden your environments.

### 4.1. Prerequisites & Host Environment Initialization

Run the automated host provisioning engine to pull repositories, configure system packages, and verify cryptographic assets.

```bash
# Install core dependencies (Ansible, Vagrant, VirtualBox, sshpass) on your local Ubuntu host
make setup

# Internal validation helper to ensure hypervisor services are accessible
make check-deps
ansible --version
vagrant --version

```

### 4.1.1. Dependencies

All dependencies will be installed automatically after running

```bash
make setup
```

command, However if you want to setup manually dependencies are below:

#### 4.1.1.1. Core Dependencies & SSH Keys
First, ensure your package lists are updated and core tools are installed.

```bash
sudo apt update
sudo apt install -y software-properties-common wget gpg curl sshpass git
```

#### 4.1.1.2. Ansible

To install ansible, follow the instructions:

https://docs.ansible.com/projects/ansible/latest/installation_guide/installation_distros.html

#### 4.1.1.3. HashiCorp Vagrant

To install vagrant, follow the instructions:

https://developer.hashicorp.com/vagrant/install


#### 4.1.1.4. Virtualbox

To install virtualbox, follow the instructions:

https://www.virtualbox.org/wiki/Linux_Downloads

#### 4.1.1.5. Verification

After manual installation, you can verify that everything is correctly set up by running:

```bash
make check-deps
ansible --version
vagrant --version

```


### 5. Environment Configuration

Before triggering any playbooks, you must generate your localized environment configuration panel.

```bash
# Initialize the interactive configuration panel
make create-env-file

```

> **CRITICAL REPOSITORY COMPLIANCE NOTE:** During this wizard, you will be prompted to enter your live remote infrastructure parameters. Ensure you have your raw public IPv4 addresses and the initial, unhardened root passwords provided via email by your cloud infrastructure providers (such as Contabo, DigitalOcean, or Hetzner). The wizard writes these parameters securely to an uncommitted, local `.env` file to maintain complete operational anonymity.

### 6. Cryptographic Asset Verification

```bash
# Verify the presence of dedicated SSH keys; generates independent keys if missing
make check-keys

```

Here is the fully engineered, standardized international version for **Section 7: Staging Environment Workflow**.

This section is structured in clean, professional technical English to serve as a mirror-image guide for your production steps. It details the setup, the core 3-step execution pipeline, testing, and environmental cleanup without any emojis or bloated prose.


## 7. Staging Environment Workflow (Local Laboratory)

The staging tier leverages Vagrant and VirtualBox to instantiate an isolated, high-fidelity local sandbox. This architecture completely mirrors the operating system state, network policies, and system dependencies of a live remote node without touching production infrastructure.

### 7.0. Rationale for Staging Implementation

The primary engineering objective of the staging tier is to establish a rigorous, risk-free validation layer before executing modifications on live production systems. By building a local sandbox that identically replicates the OS profile, network behaviors, and kernel-level configurations of your production VPS, you can safely test automation updates, catch complex system-level edge cases (such as the Ubuntu 24.04 SSH socket behavioral quirks), and refine code logic without exposing real infrastructure to critical downtime or security lockouts.

### 7.1. Infrastructure Provisioning

> **CRITICAL PRE-PROVISIONING CHECKLIST:** Before launching the local sandbox architecture, ensure your local host machine satisfies all runtime operational criteria:
> 1. All host hypervisor dependencies must be fully installed (`make setup`).
> 2. The host installation state must be programmatically verified (`make check-deps`).
> 3. Your dynamic infrastructure control panel file (`.env`) must be initialized and populated (`make create-env-file`). 
>
> Executing infrastructure provisioning tasks without completing these initialization loops will cause hypervisor allocation faults or playbook execution runtime failures.

Initialize and spin up your pristine local sandbox instance:

```bash
# Provision and start the local laboratory virtual machine
make vagrant-up

```

### 7.2. Automated Three-Step Hardening Pipeline

To enforce the strict CIS security baseline without triggering an immediate infrastructure lockout, you must execute the following core commands in exact sequential order:

```bash
# Step 1: Inject your local staging public cryptographic key using temporary root credentials
make staging-push-root-key

# Step 2: Programmatically provision your dedicated secure administrator user with passwordless sudo access
make staging-bootstrap

# Step 3: Run the final CIS security baseline hardening playbook on the target machine
make staging-harden

```

> **Architecture Execution Note:** Step 3 establishes and relies on its final execution session over the legacy root channel on Port 22. Once the hardening playbook completes its execution loops and cycles the SSH daemon, all root access maps to dead-ends and password authentication drops completely.

### 7.3. Post-Hardening Verification

Once the system is fully sealed, verify your security topology by establishing an administrative session via the newly provisioned non-root user over the secure custom port:

```bash
# Securely log into the staging instance using your dedicated admin profile and custom port
make staging-ssh-user

```

### 7.4. Infrastructure Teardown & Clean Up

To reclaim host hypervisor resources or reset your laboratory baseline back to a pristine state, execute the teardown routine:

```bash
# Completely destroy, wipe, and purge the local laboratory virtual instance
make vagrant-destroy

```

## 8. Production Environment Workflow (Live Infrastructure)

The production tier orchestrates the automated delivery of your hardened security baseline onto live, remote cloud infrastructure instances (e.g., Contabo, DigitalOcean, Hetzner). This phase seals the server, shifts public-facing administration to an unprivileged sudo user, and terminates legacy remote root access surfaces.

### 8.0. Rationale for Production Sequencing

To avoid catastrophic infrastructure lockout, the execution flow deviates strictly from standard deployment paradigms. On modern Linux footprints, applying security hardening before user provisioning triggers immediate session drops and persistent token rejection. By injecting public cryptographic assets first, establishing an isolated administrative identity second, and enforcing system-wide kernel and SSH containment policies third, you ensure zero downtime and uninterrupted management access.

### 8.1. Infrastructure Validation Check

> **CRITICAL PRE-DEPLOYMENT RUNTIME CHECKS:** Before executing code against live cloud nodes, verify that your local configuration meets the following security criteria:
> 1. Ensure your host machine has successfully verified your dedicated production cryptographic keys (`make check-keys`).
> 2. Ensure your dynamic environment file (`.env`) is fully configured with your cloud provider's temporary root credentials and remote IP targets (`make create-env-file`).
> 3. Ensure your staging simulations have successfully completed execution without throwing hypervisor errors or policy alignment failures.


### 8.2. Automated Three-Step Live Hardening Pipeline

To seal your production nodes without triggering critical system lockouts, you must execute the following commands in exact sequential order:

```bash
# Step 1: Deliver your live deployment public key to the remote root space using initial provider credentials
make production-push-root-key

# Step 2: Establish your dedicated secure administrator identity and assign passwordless sudo profiles
make production-bootstrap

# Step 3: Enforce the final CIS baseline hardening policies (Remaps ports, closes passwords, locks remote root channels)
make production-harden

```

> **Architecture Execution Note:** Step 3 establishes its concluding configuration tunnel using the legacy root identity over Port 22. Once the final tasks complete their execution loops, the custom Ubuntu 24.04 socket handling logic kicks in, the SSH daemon updates, and all subsequent administrative sessions must shift entirely to your custom user over the secure port configuration.

### 8.3. Live Connection Verification

Once the live target infrastructure has completed its hardening lifecycle, confirm that you can securely connect via your isolated administrative profile using your designated production keys over the secure port:

```bash
# Verify real-world reachability and secure shell access to the hardened production asset
make production-ssh-user
```

## 9. Automated Secret Scanning with Git Hooks

To guarantee absolute operational anonymity and prevent accidental credential leaks into the local Git history, this repository utilizes a native Git `pre-commit` hook. This configuration forces Gitleaks to audit your staged codebase automatically before any commit is finalized.

### 9.1. Automated Setup (Recommended)

If your local environment is initialized via the centralized orchestration framework, you can activate the protection hook with a single command:

```bash
# Programmatically inject the Gitleaks guard into your local Git hook lifecycle
make setup-hooks

```

### 9.2. Manual Hook Configuration

If you prefer to establish the defensive hook layer manually on your Ubuntu host, execute the following commands precisely from your repository root (`~/Development/ansible-ubuntu-hardening`):

#### Step 1: Create the Pre-Commit Hook File

Git stores executable hook scripts inside the hidden `.git/hooks/` directory. Create a new file named `pre-commit` inside this space:

```bash
nano .git/hooks/pre-commit

```

#### Step 2: Inject the Gitleaks Execution Logic

Paste the following production-grade shell script into the editor. This script intercepts the commit chain, checks for Gitleaks availability, and enforces a strict scan against cached modifications:

```bash
#!/bin/bash

# DevSecOps Automation: Pre-Commit Secret Scanner Guard
# Intercepts the commit workflow to verify zero cryptographic leaks exist in staged assets.

# Ensure Gitleaks binary is locally accessible on the host PATH
if ! command -v gitleaks &> /dev/null; then
    echo "========================================================================="
    echo "🚨 DEVSECOPS SECURITY WARNING: Gitleaks binary not detected on your host!"
    echo "Please run 'make setup' or visit https://github.com/gitleaks/gitleaks"
    echo "Commit blocked to preserve repository security compliance."
    echo "========================================================================="
    exit 1
fi

echo "🛡️  [DevSecOps] Initiating automated Gitleaks secret scanning on staged assets..."

# Execute Gitleaks against staged (cached) alterations using local Git history boundaries
gitleaks detect --log-opts="--cached" --verbose

# Capture the exit code of the scanning engine
GITLEAKS_STATUS=$?

if [ $GITLEAKS_STATUS -eq 0 ]; then
    echo "✅ [DevSecOps] Code audit successful. No secrets or tokens detected."
    exit 0
else
    echo "========================================================================="
    echo "🚨 DEPLOYMENT BLOCKED: Hardcoded secrets or tokens detected in your diff!"
    echo "Review the Gitleaks verbose log above, purge the tokens, and re-stage."
    echo "========================================================================="
    exit 1
fi

```

#### Step 3: Enforce Executable Permissions

By default, Git ignores scripts inside the hooks folder unless they possess explicit system execution flags. Grant the necessary permissions via `chmod`:

```bash
chmod +x .git/hooks/pre-commit

```

---

### 9.3. Verification & Operational Testing

Once the hook is armed, your daily development workflow gains an active cryptographic firewall.

#### Scenario A: Secure Commit (Passing State)

When you modify safe project documentation or configurations and commit the changes:

```bash
git add README.md
git commit -m "docs: updating automation parameters"

```

*Output:* The hook prints the shield banner, Gitleaks scans the diff, returns a zero exit code, and Git allows the commit to pass successfully.

#### Scenario B: Accidental Leak Attempt (Blocked State)

If you accidentally leave a live provider token or unencrypted password inside a file and attempt to commit it:

```bash
echo "CONTABO_API_KEY=rQ8acl08R0uQU5D9U0" >> ansible/group_vars/production.yml # gitleaks:allow
git add ansible/group_vars/production.yml
git commit -m "feat: adding production provider connectivity variables"

```

*Output:* Gitleaks flags the high-entropy string, outputs the exact file line details to stdout, throws an exit code of `1`, and **the commit is instantly aborted**. Your branch state remains safe, and the secret never touches the local commit ledger.

## License
This project is open-source software licensed under the **MIT License** with an explicit operational system-lockout disclaimer. See the [LICENSE](LICENSE) file for the full text before deploying to real infrastructure.

