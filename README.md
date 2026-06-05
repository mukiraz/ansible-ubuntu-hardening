# Infrastructure & Server Hardening (Ubuntu 24.04 LTS)

This project provides an enterprise-grade, **Infrastructure as Code (IaC)** automation suite designed to streamline the initialization, cryptographic bootstrapping, and programmatic hardening of Ubuntu 24.04 LTS servers using **Ansible** and GNU **Make**. 

The core architecture enforces a deterministic, three-stage **hardening pipeline** validated across a high-fidelity, two-tier environmental matrix:

*   **Staging (Local Laboratory):** An isolated, host-only Virtual Machine orchestrated via **Vagrant** and **VirtualBox**. This sandbox emulates raw cloud environments, providing a high-fidelity space to audit security policies, network rules, and low-level system states without risk.
*   **Production (Live Target):** Your remote, live Virtual Private Server (VPS) hosted across public cloud infrastructure providers such as Contabo, DigitalOcean, or Hetzner.

By utilizing a centralized environment control panel (`.env`), this framework separates sensitive operational variables from the underlying automation logic—ensuring secure, repeatable, and non-destructive deployments across all infrastructure layers.

### ⚠️ CRITICAL INFRASTRUCTURE DISCLAIMER & WARNING

> [!DANGER]
> **CRITICAL HAZARD: IMMEDIATE SYSTEM LOCKOUT & UNRECOVERABLE DOWNTIME WARNING**
> This automation framework modifies critical, low-level operating system layers, kernel variables (`sysctl`), core network routing matrices, and low-level systemd core components (specifically targeting the `systemd-ssh-generator` socket layout). 
> 
> Out-of-order execution, manual script modification, or misconfiguration of the centralized environment controller (`.env`) against any live production node **WILL cause catastrophic infrastructure lockouts, unrecoverable SSH handshake drops, and immediate server downtime.**
> 
> **MANDATORY REQUIRED ACTIONS BEFORE EXECUTION:**
> 1. **MANDATORY BACKUP:** Before executing *any* target provided within this workspace (including but not limited to `make production`, `make production-harden`, or `make production-bootstrap`) against a live remote environment, the operator is **STRICTLY REQUIRED** to perform a full system state snapshot or complete cold image backup via their infrastructure provider's control panel (e.g., Contabo, Hetzner, DigitalOcean).
> 2. **NO LOCALHOST INTRUSION:** Never manually bypass the environment failsafes. Misconfiguring target definitions may cause the automation framework to execute parameters against your local host machine, leading to unrecoverable system damage.
> 
> **ABSOLUTE ZERO LIABILITY CLAUSE:**
> The author maintains absolute zero liability for any broken production nodes, bricked server instances, lost data, compromised infrastructure access layers, or commercial financial damages arising directly or indirectly from the utilization of this automation code. You execute these orchestration routines entirely at your own risk. If you do not agree to these terms, destroy this code immediately.

## 1. Security Standards, CIS Compliance & Nessus Audits

This automation framework is strictly engineered around the official **CIS (Center for Internet Security) Ubuntu Linux 24.04 LTS Benchmark** guidelines. Rather than relying on theoretical abstractions, the defensive posture of this deployment suite is programmatically validated using industrial-grade **Tenable Nessus Professional** vulnerability assessment tools.

### 1.1. Benchmark Reference & Compliance Scope

The hardening logic targets both infrastructure edge defenses and low-level kernel configurations to systematically reduce the OS attack surface:
*   **Target Standard:** CIS Ubuntu Linux 24.04 LTS Benchmark (Level 1 and Level 2 Server Profiles).
*   **Section 1.1 (Filesystem Restrictions):** Restricting node mounts, locking down shared memory layers, and enforcing protective system layout limits.
*   **Section 3 (Automated UFW Firewall Policies):** Deploying a strict, drop-by-default inbound network matrix while sustaining local container bridges.
*   **Section 5 (Secure SSH Daemon Specifications):** Shifting service ports, disabling legacy cryptographic primitives, removing password vectors, and disabling direct administrative root logic.
*   **Kernel Security:** Injecting defensive `sysctl` parameter tuning while explicitly maintaining localized virtualization exceptions.

### 1.2. Vulnerability Mitigation Matrix (Nessus Metrics)

The following validation matrix documents the exact security state of the target remote infrastructure node (`84.247.136.234`) audited before and after the execution of the automated three-stage provisioning pipeline. 

*Note: All data points below are extracted directly from the baseline artifacts (`image_ddab09.png`) and post-hardening scan metrics (`image_d39bbb.png`, `image_d32ea0.png`) verbatim.*

| Scan Scope & Perspective | Critical (Red) | High (Orange) | Medium (Yellow) | Low (Green) | Info (Blue) | Total Open | Compliance State |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **External - Before Hardening** | 0 | 0 | 0 | 1 | 3 | **4** | Baseline Risk |
| **External - After Hardening** | **0** | **0** | **0** | **0** | **18** | **18** | **100% Invisible** |
| **Internal - Before Hardening** | 0 | 1 | 0 | 1 | 59 | **61** | Exposed Core |
| **Internal - After Hardening** | **0** | **0** | **0** | **0** | **51** | **51** | **CIS Certified** |

### 1.3. Hardening Operational Analysis & Threat Mitigation

#### 1.3.1. External Surface Evolution (Unauthenticated Audit)
*   **Pre-Hardening State (`image_ddab09.png`):** The raw cloud provider baseline exposed low-severity information disclosure vectors—specifically an active **ICMP Timestamp Request Remote Date Disclosure (CVSS 2.1)** and uninhibited **Traceroute Information** tracking. This allowed remote adversaries to map out internal network topologies and system uptime behaviors during initial reconnaissance phases.
*   **Post-Hardening Realignment (`image_d39bbb.png`):** Upon pipeline execution, the external attack surface drops to zero severe vectors. The integration of high-range port shifting alongside dropping unauthorized ICMP/ping discovery probes completely silences edge telemetry, rendering the host invisible to automated botnet scanning sweeps.

#### 1.3.2. Internal Core Evolution (Authenticated/Credentialed Audit)
*   **Pre-Hardening State (White-Box Audit):** Deep infrastructure auditing detected 61 structural and asset compliance vulnerabilities. High-risk elements included **Apache Log4j Installed** asset detection flags, active **SSH Password Authentication Accepted** (exposing the system to brute-force vectors), local user enumeration capabilities, and the presence of weak **SSH SHA-1 HMAC Algorithms Enabled**.
*   **Post-Hardening Realignment (`image_d32ea0.png`):** Authenticated scanning using custom administrative SSH key variables confirms that **all High and Low vulnerabilities have been mitigated to absolute zero (0).** The framework successfully purged legacy cryptographic ciphers, stripped weak HMAC exchange algorithms, disabled root interaction maps, and neutralized credentialed enumeration channels. The remaining 51 informational flags represent harmless asset discoveries (such as tracking localized Vim installation paths or basic device uptime metrics) necessary for normal business operations.


## 2. Core Architectural Architecture & Automation Steps

The core architecture of this framework is engineered around a deterministic, **Three-Stage Security Pipeline** executed via GNU `Make` and orchestrated by `Ansible`. This design guarantees that the server's state transitions safely from a high-risk factory configuration into an immutable security bastion without configuration drift or accidental lockouts.


```

[Raw Production Instance] (Root Access / Password Auth / Port 22)
│
▼
┌──────────────────────────────┐
│  STAGE 1: SSH Key Injection   │ ──► Deploys dedicated administrator account (e.g., mukiraz),
└──────────────────────────────┘     provisions ED25519 public keys, configurations passwordless sudo.
│
▼
┌──────────────────────────────┐
│   STAGE 2: CIS Hardening     │ ──► Executes 200+ security compliance rules, injects UFW profile,
└──────────────────────────────┘     purges default systemd-ssh-generator, migrates SSH to secure port.
│
▼
┌──────────────────────────────┐
│ STAGE 3: Server Bootstrap    │ ──► Validates end-to-end handshake over the new high-range port,
└──────────────────────────────┘     purges root authorized keys, locks down root account globally.
│
▼
[Hardened Security Bastion] (Admin User Only / Private Key Auth / Custom Secure Port Only)

```

### 2.1. Detailed Pipeline Execution Breakdown

#### Stage 1: Public Key Provisioning & Admin Genesis (`push-root-key`)
* **Target State:** Establishes initial connection to the raw target node over default Port 22 using temporary `root` credentials.
* **Execution Logic:**
    * Creates a dedicated, unprivileged administrator user profile (`mukiraz`) on the target machine.
    * Provisions authorized cryptographic `ed25519` public keys directly to the new admin profile's workspace (`/home/mukiraz/.ssh/authorized_keys`).
    * Appends a secure, atomic configuration block into `/etc/sudoers.d/mukiraz`, enabling strict `NOPASSWD: ALL` privilege elevation.
    * Asserts an end-to-end validation handshake as the new user to ensure local terminal keys are functioning perfectly.

#### Stage 2: Programmatic Hardening & Engine Overrides (`harden`)
* **Target State:** Connects as `root` via default Port 22 to overhaul system posture.
* **Execution Logic:**
    * Injects 200+ security baselines mapped to **CIS Level 1 & Level 2** server profiles.
    * **Ubuntu 24.04 Engine Override:** Safely drops the native, conflicting systemd socket activation directory (`/etc/systemd/system/ssh.socket.d`), preventing standard deployment lockouts caused by port binding collisions.
    * Migrates the entire OpenSSH daemon configuration to the centralized custom secure high-range port (`CUSTOM_SSH_PORT`).
    * Enforces strict cryptographic ciphers, drops weak MAC algorithms, and blocks direct password access.
    * Deploys the optimized, Docker-friendly **UFW Firewall Matrix**, closing down all network footprinting vulnerabilities (such as ICMP probing vectors).

#### Stage 3: Operational Validation & Root Lockdown (`bootstrap`)
* **Target State:** Connects over the newly shifted `CUSTOM_SSH_PORT` utilizing the custom admin credentials (`mukiraz`) via SSH Private Key.
* **Execution Logic:**
    * Performs a critical connectivity check to ensure the new secure configuration is operational before ending the deployment loop.
    * Purges all stale temporary keys located inside `/root/.ssh/authorized_keys`.
    * Executes a system-wide lock on the remote `root` user account (`passwd -l root`), completely neutralizing the root password layer as an attack surface.


## 3. Repository Structure & Dependency Management

This framework utilizes a decoupled layout to isolate infrastructure inventories, runtime deployment tasks, and security hardening baselines. Below is the comprehensive structural overview of the workspace, followed by the dependency management strategy.

### 3.1. Directory Tree

```text
.
├── ansible
│   ├── ansible.cfg              # Runtime engine configuration and temporary paths
│   ├── group_vars
│   │   └── all.yml              # Centralized global parameter controller and overrides
│   ├── inventories
│   │   ├── production           # Production runtime environment inventory file
│   │   └── staging              # Local laboratory sandbox inventory file
│   ├── playbooks
│   │   ├── 00_bootstrap_server.yml  # Post-hardening handshake and root lockdown
│   │   └── 01_harden_server.yml     # CIS compliance execution playbook
│   └── roles
│       ├── bootstrap            # Tailored tasks for validation and asset locking
│       ├── dev-sec.os-hardening # Locally vendorshipped upstream baseline core engine
│       └── ubuntu_hardening     # Modular firewall matrices and OS updates
├── LICENSE                      # Explicit MIT License and complete liability waivers
├── Makefile                     # Automation orchestrator powered by centralized macros
├── README.md                    # System documentation workbook
└── Vagrant
    └── Vagrantfile              # .env-synced local lab sandbox virtualization config

```

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

## 4. Installation of Host Dependencies

The local management workspace requires a specific set of automation toolchains and hypervisors to orchestrate both local sandboxes and remote production runtimes. This framework provides an automated installation vector alongside manual configuration references for full auditability.

### 4.1. Automated Initialization Blueprint

The entire host setup sequence is compiled inside a centralized orchestration layer. Execute the following target from your local controller terminal to automatically inject upstream repositories, configure keyrings, and deploy necessary package dependencies:

```bash
# Deploys upstream Ansible PPAs, HashiCorp repositories, and essential tooling natively
make setup

# Executes internal validation routines to verify hypervisor service states
make check-deps

```

### 4.2. Toolchain Inventory & Manual Deployment References

If your enterprise security policy requires manual compliance validation or if you are configuring a custom control node, the required underlying components must be fetched using the following specifications:

#### 4.2.1. Fundamental Utilities & Cryptographic Assets

The execution engine relies on `sshpass` for initial zero-key password mapping routines and standard GNU utilities for workspace management.

```bash
sudo apt update
sudo apt install -y software-properties-common wget gpg curl sshpass git

```

#### 4.2.2. Configuration Management Engine (Ansible)

Ansible handles the declarative hardening blueprints. It is highly recommended to fetch the package directly from the official upstream launchpad repository to satisfy version requirements ($\ge 2.15$):

* **Official Deployment Guidelines:** [Ansible Core Installation Reference](https://docs.ansible.com/projects/ansible/latest/installation_guide/installation_distros.html)

#### 4.2.3. Workspace Emulation Engine (HashiCorp Vagrant)

Vagrant structures the local high-fidelity laboratory infrastructure. Ensure the HashiCorp GPG signing key is validated prior to binary verification:

* **Official Deployment Guidelines:** [HashiCorp Vagrant Binary Distribution Panel](https://developer.hashicorp.com/vagrant/install)

#### 4.2.4. Hypervisor Provider (Oracle VirtualBox)

VirtualBox functions as the localized bare-metal simulation provider for the staging pipeline workspace:

* **Official Deployment Guidelines:** [Oracle VirtualBox Linux Core Downloads](https://www.virtualbox.org/wiki/Linux_Downloads)

### 4.3. Workstation State Verification

Once the local dependencies are provisioned via either the automated macro or manual tracks, confirm the integrity and versioning matrix of your host environment by querying the state registers:

```bash
# Structural check for hypervisor readiness
make check-deps

# Version control validation
ansible --version
vagrant --version

```

## 5. Centralized Environment Configuration

Before triggering any automated playbook runtimes or virtualization matrices, you must establish your centralized environment configuration panel (`.env`). This control panel acts as the single source of truth across all GNU `Make` macros, Vagrant orchestration files, and Ansible group variables.

### 5.1. Interactive Workspace Initialization

The automation engine embeds an interactive wizard designed to securely abstract target environment variables from the underlying code logic. Execute the following macro target to provision your local configuration file:

```bash
# Initialize the interactive configuration wizard
make create-env-file

```

> **CRITICAL REPOSITORY COMPLIANCE NOTE:** During this wizard execution, you will be prompted to supply your live remote infrastructure parameters. Ensure you have your active public IPv4 targets and the initial, unhardened temporary root credentials supplied by your cloud infrastructure vendor (e.g., Contabo, Hetzner, or DigitalOcean). The script writes these variables securely to an uncommitted, local `.env` file to enforce absolute configuration anonymity and prevent repository credential leaks.

### 5.2. Environmental Parameter Blueprint

The framework maps variables to specific network, deployment, and identity layers across staging and production targets. 

Instead of maintaining inline configuration blocks inside this documentation, a fully documented template is provided directly within the source tree. Review, clone, and modify the parameters defined inside the central [**`.env.example`**](.env.example) file to align with your infrastructure targets prior to initiating any deployment subroutines.

## 6. Cryptographic Asset Verification

Prior to pushing any configuration payloads to remote endpoints, the local control workstation must verify the mathematical presence and paths of the specific identity keys declared inside the centralized environment panel (`.env`).

### 6.1. Automated Key Generation Matrix

The architecture requires two completely isolated cryptographic key pairs to maintain cryptographic separation between development laboratories and live infrastructure nodes. Execute the key verification target to analyze your local storage footprint:

```bash
# Verify the presence of dedicated SSH keys; generates independent keys if missing
make check-keys

```

### 6.2. Underlying Mechanics & Key Archetypes

When the `make check-keys` rule executes, it queries the local filesystem path `~/.ssh/`. If the specific key assets defined by `STAGING_SSH_KEY_NAME` or `PRODUCTION_SSH_KEY_NAME` do not exist, the engine automatically runs low-level subroutines to provision them securely:

* **Staging Asset:** Provisions an unencrypted, high-performance `ed25519` key pair tagged with the signature comment `ansible_staging`.
* **Production Asset:** Provisions an independent `ed25519` key pair tagged with the signature comment `ansible_production`.

This setup enforces strong cryptographic protection across all infrastructure boundaries before any automated data transmission or remote identity management takes place.


## 7. Staging Environment Workflow (Local Laboratory)

The staging tier leverages Vagrant and VirtualBox to instantiate an isolated, high-fidelity local sandbox. This architecture completely mirrors the operating system state, network policies, and system dependencies of a live remote node without touching production infrastructure.

### 7.1. Rationale for Staging Implementation

The primary engineering objective of the staging tier is to establish a rigorous, risk-free validation layer before executing modifications on live production systems. By building a local sandbox that identically replicates the OS profile, network behaviors, and kernel-level configurations of your production VPS, you can safely test automation updates, catch complex system-level edge cases (such as the Ubuntu 24.04 SSH socket behavioral quirks), and refine code logic without exposing real infrastructure to critical downtime or security lockouts.

### 7.2. Infrastructure Provisioning

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

### 7.3. Automated Three-Stage Hardening Pipeline

To enforce the strict CIS security baseline without triggering an immediate infrastructure lockout, the pipeline must be executed in an exact cryptographic sequence. You can orchestrate the entire lifecycle via a single monolithic command, or run the individual subroutines sequentially:

#### 7.3.1. Monolithic Pipeline Execution (Recommended)

```bash
# Triggers the absolute 3-stage sequence (Key Injection -> CIS Hardening -> Bootstrap Lockdown)
make staging

```

#### 7.3.2. Granular Pipeline Execution

```bash
# Stage 1: Inject public cryptographic keys and provision the initial administrator identity via root
make staging-push-root-key

# Stage 2: Apply the full CIS Level 1/2 profiles and migrate the SSH daemon to the custom secure port
make staging-harden

# Stage 3: Establish a verification handshake over the custom port as the admin user and lock down root
make staging-bootstrap

```

> **Architecture Execution Note:** Stage 2 executes its structural modification loops over the legacy root channel on Port 22. Once the hardening role completes its cycles and flushes the SSH daemon state, all root access definitions map to dead-ends, legacy ports are dropped, and password authentication is terminated. Stage 3 seamlessly transitions to the newly configured high-range port to seal the operating system.

### 7.4. Post-Hardening Verification

Once the system is fully sealed and validated, verify your security topology by establishing an instant administrative terminal session via the newly provisioned non-root user over the secure custom port:

```bash
# Securely log into the staging instance using your dedicated admin profile and custom port
make staging-ssh-user

```

### 7.5. Infrastructure Teardown & Clean Up

To reclaim host hypervisor resources or reset your laboratory baseline back to a pristine state, execute the teardown routine:

```bash
# Completely destroy, wipe, and purge the local laboratory virtual instance
make vagrant-destroy

```


## 8. Production Environment Workflow (Live Infrastructure)

The production tier orchestrates the automated delivery of your hardened security baseline onto live, remote cloud infrastructure instances (e.g., Contabo, DigitalOcean, Hetzner). This phase seals the server, shifts public-facing administration to an unprivileged sudo user, and terminates legacy remote root access surfaces.

### 8.1. Rationale for Production Sequencing

To avoid catastrophic infrastructure lockout, the execution flow deviates strictly from standard deployment paradigms. On modern Linux footprints, applying security hardening before user provisioning triggers immediate session drops and persistent token rejection. By injecting public cryptographic assets first, establishing an isolated administrative identity second, and enforcing system-wide kernel and SSH containment policies third, you ensure zero downtime and uninterrupted management access.

### 8.2. Infrastructure Validation Check

> [!CAUTION]
> **CRITICAL PRE-DEPLOYMENT RUNTIME CHECKS:** Before executing code against live cloud nodes, verify that your local configuration meets the following security criteria:
> 1. Ensure your host machine has successfully verified your dedicated production cryptographic keys (`make check-keys`).
> 2. Ensure your dynamic environment file (`.env`) is fully configured with your cloud provider's temporary root credentials and remote IP targets (`make create-env-file`).
> 3. Ensure your staging simulations have successfully completed execution without throwing hypervisor errors or policy alignment failures (`make staging`).

### 8.3. Automated Three-Stage Live Hardening Pipeline

To seal your production nodes without triggering critical system lockouts, the pipeline must be executed in an exact cryptographic sequence. You can orchestrate the entire live infrastructure lifecycle via a single monolithic command, or run the individual subroutines sequentially:

#### 8.3.1. Monolithic Production Execution (Recommended)
```bash
# Triggers the absolute 3-stage sequence (Key Injection -> CIS Hardening -> Bootstrap Lockdown)
make production

```

#### 8.3.2. Granular Production Component Execution

```bash
# Stage 1: Deliver your live deployment public key to the remote root space using initial provider credentials
make production-push-root-key

# Stage 2: Enforce the final CIS baseline hardening policies, remove systemd-ssh-generator, and remap ports
make production-harden

# Stage 3: Establish verification handshake over the custom port as the admin user and globally lock root
make production-bootstrap

```

> **Architecture Execution Note:** Stage 2 executes its structural modification loops over the legacy root channel on Port 22. Once the hardening role completes its cycles and flushes the SSH daemon state, all root access definitions map to dead-ends, legacy ports are dropped, and password authentication is terminated. Stage 3 seamlessly transitions to the newly configured high-range port to seal the operating system, purge stale keys, and globally lock the root password account interface.

### 8.4. Live Connection Verification

Once the live target infrastructure has completed its hardening lifecycle, confirm that you can securely connect via your isolated administrative profile using your designated production keys over the secure port:

```bash
# Verify real-world reachability and secure shell access to the hardened production asset
make production-ssh-user

```

## 9. Post-Hardening Verification & Manual Compliance Checks

Programmatic compliance verification via automated tools must be accompanied by manual configuration audits to verify that the operating system layer has reached an absolute hardened state. Execute the following system level audits directly from your administrative terminal session (`make production-ssh-user`) to verify that the underlying security controls are running as intended.

### 9.1. Identity Management & Root Account Containment

#### 9.1.1. Root Access Lock Verification

Verify that the global remote `root` account has been explicitly locked at the password shadow register layer:

```bash
sudo passwd -s root

```

* **Expected Metric:** The output must contain an **`L`** flag directly following the user name (e.g., `root L 06/05/2026 ...`), indicating that the password hash string is globally locked and incapable of interactive validation loops.

#### 9.1.2. Authorized Security Asset Inventory

Audit the administrative access matrix to confirm that no stale cryptographic variables remain in the standard root directory:

```bash
sudo ls -la /root/.ssh/
sudo cat /root/.ssh/authorized_keys

```

* **Expected Metric:** The files must either be completely purged or absent. No active deployment keys or cloud provider automation components should persist within the administrative root scope.

---

### 9.2. Network Security, Socket Layers & Firewall Integrity

#### 9.2.1. Active Listening Sockets Matrix

Query the low-level network namespace to identify every active listening socket, ensuring that the legacy default Port 22 is completely dormant:

```bash
sudo ss -tulpn | grep LISTEN

```

* **Expected Metric:** The standard port daemon identifier `*:22` must be absent. The OpenSSH daemon signature (`sshd`) must only be bound to your designated `CUSTOM_SSH_PORT`.

#### 9.2.2. Ingress Firewall Policy Assessment

Verify the active rule state of the Netfilter firewall interface to confirm that the hardened network containment matrix is running correctly:

```bash
sudo ufw status numbered
sudo ufw status verbose

```

* **Expected Metric:** The status directive must display `Status: active`. The default incoming operational profile must be explicitly set to `deny (incoming)`. Legitimate ingress tracking rules should only appear for your designated custom secure port and standard reverse proxy endpoints (such as 80/443), while tracking states remain blocked for unauthorized ICMP and ping probes.

---

### 9.3. Operating System Hardening & Configuration Diagnostics

#### 9.3.1. OpenSSH Daemon Configuration Blueprint

Verify that the compiled operational configurations inside the live OpenSSH daemon actively reject weak cryptographic primitives and legacy connection styles:

```bash
sudo sshd -T | grep -E -i "permitrootlogin|pubkeyauthentication|passwordauthentication"

```

* **Expected Metric:** The runtime engine configuration variables must precisely yield the specific target states: `permitrootlogin no`, `pubkeyauthentication yes`, and `passwordauthentication no`.

#### 9.3.2. Kernel Security Parameter State (Sysctl Diagnostics)

Audit the running state of low-level kernel variable pools to ensure that defensive network layer modifications have been injected successfully:

```bash
sudo sysctl net.ipv4.conf.all.accept_redirects
sudo sysctl net.ipv4.conf.all.accept_source_route

```

* **Expected Metric:** Both diagnostic parameters must yield a value state of **`0`**, indicating that the kernel is actively dropping malicious source-routed packets and unauthorized ICMP redirect attempts across all network interfaces.

## 10. Operational Considerations for Virtualization (Docker Compatibility)

While applying an uncompromising CIS security posture minimizes the host operating system's attack surface, certain default hardening baselines directly break modern application virtualization layers. This section details the critical operational remediation built into this framework to guarantee native compatibility with Docker container runtimes.

### 10.1. The Packet Forwarding Conflict

By default, the upstream `dev-sec.os-hardening` engine applies strict structural kernel restrictions that completely disable IPv4 and IPv6 packet forwarding across all network boundaries. While this design prevents a standalone bare-metal node from acting as a malicious router, it introduces an immediate infrastructure failure mode when running Docker or Podman:

* **The Problem:** Container virtualization relies on host-level virtual network interfaces (e.g., `docker0` bridges). When the container engine spins up, it expects the host kernel to route traffic dynamically between these isolated bridge networks and the physical network interface card (NIC).
* **The Impact:** Disabling packet forwarding completely severs container-to-host and container-to-external-network communications. Containers will fail to pull external dependencies, resolve DNS queries via the host layer, or serve application traffic over exposed reverse proxies.

### 10.2. Native Override Architecture

To eliminate this operational friction, this framework implements a non-intrusive variables abstraction layer within `ansible/group_vars/all.yml`. This architecture systematically intercepts the upstream hardening routines, overriding specific kernel directives to preserve network packet forwarding exclusively for virtualization runtimes without altering the vendor's underlying source code:

```yaml
# Enforcing custom overrides to sustain Docker network packet forwarding
sysctl_overwrite:
  net.ipv4.ip_forward: 1
  net.ipv4.conf.all.forwarding: 1
  net.ipv6.conf.all.forwarding: 1
  fs.protected_hardlinks: 1
  fs.protected_symlinks: 1

security_init_network_ipv4_forwarding: true

```

#### 10.2.1. Kernel-Level Parameter Execution Matrix

The framework forces the kernel to honor the following operational parameters during runtime initialization loops:

* **`net.ipv4.ip_forward = 1` & `net.ipv4.conf.all.forwarding = 1`:** Explicitly re-enables the IPv4 packet forwarding subroutines inside the Linux kernel core, ensuring that Docker's underlying `iptables` and `nftables` manipulation structures can successfully bridge internal virtualization paths.
* **`net.ipv6.conf.all.forwarding = 1`:** Re-enables equivalent routing pathways for modern IPv6-enabled container layers.
* **`security_init_network_ipv4_forwarding: true`:** An upstream configuration flag injected to satisfy conditional deployment blocks within the vendor role, preventing the engine from attempting to reset forwarding registers back to a zero state on subsequent automation runs.

### 10.3. UFW and Docker Integration Safeguards

Standard Uncomplicated Firewall (UFW) configurations often conflict with Docker because Docker directly bypasses standard UFW user rules by writing its own network tables directly into `iptables`.

The Stage 2 (`harden`) automation phase ensures that if Docker is present or deployed post-hardening, standard host interface rules enforce a drop-by-default policy for external unauthorized traffic, while natively allowing the underlying kernel to maintain unhindered routing for localized virtual networks. This guarantees that your containerized applications remain highly available without compromising edge network containment.

## 11. License & Liability Waivers

This framework is distributed under the terms of the **MIT License**.

### 11.1. Open-Source Compliance

The complete legal text, copyright declarations, and full liability waivers governing this automation suite are maintained externally within the centralized `LICENSE` file located at the root of this repository. All deployments must adhere to the terms specified therein.

### 11.2. Operational Risk Warning

Automated infrastructure hardening modifies low-level kernel directives, authentication protocols, and network socket variables. Running these blueprints without prior verification against the local laboratory staging layer (`make staging`) can result in permanent infrastructure lockout. Always ensure verified system snapshots are completed via your cloud infrastructure provider's console prior to execution.













