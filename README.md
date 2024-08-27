# Private Ethereum Blockchain Network with IaC/SRE Practices

## Table of Contents

- [Private Ethereum Blockchain Network with IaC/SRE Practices](#private-ethereum-blockchain-network-with-iacsre-practices)
  - [Table of Contents](#table-of-contents)
  - [Intro \& Misc info](#intro--misc-info)
  - [Terraform Configuration](#terraform-configuration)
  - [Ansible Playbooks](#ansible-playbooks)
    - [Roles](#roles)
    - [Commands](#commands)
  - [Monitoring and Logging](#monitoring-and-logging)
  - [Security Considerations](#security-considerations)
  - [Future improvements](#future-improvements)

## Intro & Misc info

This repository contains the necessary code and configuration to deploy, monitor, and maintain a private Ethereum blockchain network using SRE/IaC practices. For this implementation, I chose to deploy the private network on a set of VPSs provided by Contabo cloud provider, utilizing Terraform for infrastructure provisioning and Ansible for configuration management. While Kubernetes with GitOps tools like FluxCD or ArgoCD could have been alternative approaches, the current setup demonstrates a straightforward for a small-scale private blockchain network.

To enhance flexibility and allow for potential expansion across multiple cloud providers, I've implemented a Wireguard network. This secure VPN solution enables the seamless integration of nodes from different cloud environments, ensuring that the private Ethereum network can easily scale beyond the initial Contabo setup. This approach provides a robust foundation for a hybrid or multi-cloud architecture, allowing for greater resilience and geographic distribution of nodes if needed in the future.

## Terraform Configuration

The `terraform/` directory contains the Infrastructure as Code (IaC) configuration for provisioning the necessary resources:

- `main.tf`: Defines the main infrastructure components (e.g., VPSs, private network, s3 bucket).
- `variables.tf`: Declares input variables used in the Terraform configuration.
- `.env`: Not commited into the repo, this files contains some env vars and secrets that are sourced in the terminal to log-into AS3 and more, using command 'source .env'
- `secrets.tfvars`: Not commited into the repo, this files contains some secrets that are sourced in the terminal before running the terraform commands.

The Terraform state file is stored remotely in an AWS S3 bucket, with state locking implemented using DynamoDB, ensuring secure and collaborative infrastructure management.

Commands:
- `source ../.env && TF_LOG=DEBUG terraform init  -var-file="secrets.tfvars"`
- `source ../.env && TF_LOG=DEBUG terraform plan  -var-file="secrets.tfvars"`
- `source ../.env && TF_LOG=DEBUG terraform apply -var-file="secrets.tfvars"`

## Ansible Playbooks

The `ansible/` directory contains the configuration management and application deployment scripts. The `ansible/playbooks/` directory where all the playbooks live.

- `ansible/playbooks/setup_wireguard.yml`: a playbook to create a VPN accros all 4 VPSs.
- `ansible/playbooks/setup_ethereum.yml`: a playbook to bootstrap the eth network.
- `ansible/playbooks/setup_wireguard.yml`: a playbook to create a VPN accros all 4 VPSs.

### Roles

- `common/`: Sets up common configurations across all nodes (e.g., system updates, firewall rules).
- `ethereum_node/`: Installs and configures Ethereum nodes using Docker containers.
- `monitoring/`: Deploys the monitoring stack (Prometheus, Grafana, Loki, AlertManager).

### Commands

- `ansible-playbook -vv wireguard_setup.yml `
- `ansible-playbook -vv playbooks/setup_ethereum.yml --forks=1`
- `ansible-playbook -vv playbooks/ethereum_node_check.yml --forks=1`
- `ansible-playbook -vv playbooks/monitoring_stack_setup.yml --forks=1`
- `ansible-playbook -vv playbooks/setup_monitoring_agents.yml --forks=1`

## Monitoring and Logging

- `prometheus.yml.j2`: Prometheus configuration template.
- `loki-config.yml.j2`: Loki configuration for log aggregation.
- `alertmanager.yml.j2`: AlertManager configuration.
- `ansible/playbooks/setup_monitoring_agents.yml`: a playbook to install monitoring agents on the 3 VPSs that run Geth (promtail, prom node exporter etc).
- `ansible/playbooks/ethereum_node_check.yml`: a playbook to check the latest block hash on all 3 nodes so that we can quickly debug and compare. It also prints out some data such as the genesis block.
- `ansible/playbooks/ping_and_port_check.yml`: a playbook to run ping commands on all servers targetting all servers, to check and debug the networking setup (wireguard, ports, etc).

What is not set up yet:

- some alerts in alertmanager to monitor the liveness of the eth nodes and alerts on a channel such as Discord or Slack. Based on metrics and logs.
- a [dead man switch](https://medium.com/@seifeddinerajhi/never-get-caught-blind-securing-your-monitoring-stack-with-a-dead-man-switch-d4e0d54db768) to guard our monitoring services from unnoticed outage.
- improve the logging stack (promtail and loki): indexing, external storage, retention duration, log rotation, parsing of logs before they are sent to Loki, relabeling etc.
- comprehensive Grafana dashboard that includes: Node health metrics and Blockchain-specific metrics, Network performance indicators, VPSs metrics (RAM, CPU), 

Access the monitoring interfaces:

   - Grafana: `http://<monitoring-server-ip>:3000`
   - Prometheus: `http://<monitoring-server-ip>:9090`
   - AlertManager: `http://<monitoring-server-ip>:9093`


## Security Considerations

**Important Note:** This implementation is designed as a proof of concept for a technical challenge and deliberately omits several critical security measures. In a production environment, the following security issues should be addressed:

1. **Secrets Management:** 
   - Current implementation: Secrets and sensitive data are stored unencrypted in the Git repository. AWS S3 credentials that are used to update the tfstate are not encrypted and stored properly in the repo. We could have used something that Workload identity federation or similar for better security.
   - Recommendation: Use a secure secrets management solution like HashiCorp Vault or AWS Secrets Manager. Never store unencrypted secrets in version control.

2. **Authentication for Monitoring Tools:**
   - Current implementation: Grafana, Prometheus, and AlertManager are publicly accessible without authentication.
   - Recommendation: Implement strong authentication mechanisms (e.g., basic auth at minimum, preferably OAuth or SAML) for all monitoring and management interfaces.

3. **Network Security:**
   - Current implementation: Some Services are exposed directly to the internet without proper network segmentation or firewalls, such as the grafana dashboard. No firewall is set on the VPSs (using iptables or ufw).
   - Recommendation: Use private networks, VPNs, or bastion hosts to restrict access. Implement proper firewall rules to allow only necessary traffic.

4. **Encryption:**
   - Current implementation: Data transmission between components is not encrypted.
   - Recommendation: Use TLS/SSL for all network communications, including between Ethereum nodes and monitoring components.


These security considerations are critical for any production deployment. The current implementation should not be used in a production environment without addressing these security issues comprehensively.

## Future improvements

**Automation around Terra and ansible:**

- As a potential next step, the deployment process could be further automated by implementing CICD pipelines. This would allow for automatic execution of Terraform and Ansible commands upon pushing changes to the Git repository. We can also think of adding automated testing of Terraform configurations and Ansible playbooks; Automated deployment to staging/test environments
- consider adding some automated tests Terraform configurations and Ansible playbooks to ensure formatting and catch potential issues early.

**Enhance documentation by:**

- Adding a detailed architecture diagram
- Including a troubleshooting guide
- Include a section on prerequisites (e.g., required software versions, account setup for cloud providers).
- Providing more in-depth explanations of configuration choices
- Performance Benchmarks: including some performance metrics or benchmarks could be valuable.

**Implement automated backups for critical data:**

- Set up regular snapshots of Ethereum node data
- Configure offsite backup storage for disaster recovery

**Block Explorer and RPC:**

- Better set up the RPC endpoints: the HTTP RPC interface is enabled, but it's not explicitly exposed in the docker compose file.
- Set up Blockscout or similar block explorer and indexer.
