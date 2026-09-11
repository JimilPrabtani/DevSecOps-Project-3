# Output of This Project — Problems Faced and Fixes

Project: **Trident-DevSecOps** (3-tier Flask + Nginx + MySQL on AWS, Terraform + Jenkins + GitHub Actions).
This file logs every real problem hit while building it, so the next person doesn't repeat them.

---

## 1. Deploying Terraform resources

**Problem A — stale resources from an earlier run caused conflicts.**
An `apply` from a week earlier was still live (VPC, subnets, security groups, IAM role, EC2). Re-running `terraform apply` against fixed-name resources (`devsecops-web/app/db-sg`, `devsecops-ec2-secrets-role`, `10.0.0.0/16`) risked duplicate-name and CIDR-overlap conflicts.
Fix: `cd terraform && terraform plan -destroy` to preview, then `terraform destroy` (handles order itself: instance → route-table association → route table/IGW → security groups/subnets → VPC → IAM). Then verified empty with `aws ec2 describe-vpcs/instances/security-groups/roles` filtered on `devsecops-*`. Lesson: keep `terraform.tfstate` until `destroy` succeeds — deleting state orphans live resources.

**Problem B — `ami_id` is region-specific.**
The default `ami-0c7217cdde317cfec` (Ubuntu 22.04) is valid only in `us-east-1`. Any other `aws_region` fails with `InvalidAMIID.NotFound`.
Fix: `terraform/variables.tf` now lists AMI IDs for common regions next to the variable; README tells the user to change it when switching regions.

**Problem C — EC2 key pair must already exist.**
`var.key_pair_name` (`devsecops-key`) references a key pair Terraform does not create. `apply` fails with `InvalidKeyPair.NotFound` if you skip creating it.
Fix: documented prerequisite `aws ec2 create-key-pair --key-name devsecops-key ... > devsecops-key.pem && chmod 400 devsecops-key.pem` before `apply`.

**Problem D — `my_ip` default was someone else's IP.**
`variables.tf` shipped with a hardcoded personal IP (`43.241.194.24/32`), so SSH (port 22) was locked to the wrong machine for every new user.
Fix: README instructs setting it from `https://checkip.amazonaws.com` as `"x.x.x.x/32"`.

---

## 2. Fixing the workflows (GitHub Actions + Jenkins — both kept)

**Problem A — `pip-audit` never ran in GitHub Actions.**
The repo file was `requirement.txt` (singular) but the workflow checked `hashFiles('requirements.txt')` (plural) — always false, so the dependency audit silently skipped on every run while looking green.
Fix: renamed to standard `requirements.txt` via `git mv`; updated `Dockerfile` (`COPY` + `pip install -r`) and `Jenkinsfile` (`pip-audit -r`). The workflow needed no change.

**Problem B — repo URL mismatch between the two pipelines.**
`Jenkinsfile` checked out `DevSecOps-Project-3.git` while `README.md` told users to clone `DevSecOps-Project.git` (no `-3`) — one of them 404s.
Fix: unified everything on `DevSecOps-Project-3.git` (the live remote). Jenkins URL kept as-is per decision; README's 4 clone commands and the template portfolio link updated to match.

**Problem C — scans could never fail the Jenkins build.**
Every scan stage ended with `|| true` (including Trivy), so even HIGH/CRITICAL findings — or Trivy not being installed at all — passed silently.
Fix: kept non-blocking intentionally for the first green run and documented it in the README; the Jenkins runbook requires pre-installing Trivy. Flip: remove `|| true` when you want gating builds.

**Problem D — fixed `sleep 10` health check flaked.**
MySQL has `start_period: 40s`, so `curl -f http://localhost/healthz` right after `sleep 10` often failed on a cold start and marked the whole pipeline red.
Fix: `Jenkinsfile` stage 7 now retries `curl` 6× with 10s sleeps and only fails after all attempts.

**Problem E — Bandit scanned junk directories.**
`bandit -r . -x ./venv` also walked `.git`, `terraform/`, and `.venv` on a fresh clone (slow, noisy).
Fix: excludes extended to `./venv,./.venv,./terraform,./.git`.

---

## 3. EC2 + Docker + port setup

**Problem A — `Cannot connect to the Docker daemon`.**
`docker compose up --build` on a fresh EC2 failed with `unix:///var/run/docker.sock. Is the docker daemon running?`
Root causes found: (1) SSH'd in before `user_data` (apt install + `systemctl start/enable docker`) finished; (2) `usermod -aG docker ubuntu` needs a logout/login (or `newgrp docker`) to take effect — `sudo docker ps` worked while plain `docker ps` didn't.
Fix: `sudo systemctl start docker && sudo systemctl enable docker`, then re-login; diagnose with `cloud-init status`, `systemctl status docker`, `groups`, `ls -l /var/run/docker.sock`.

**Problem B — `version is obsolete` warning on every compose run.**
`docker-compose.yml` started with `version: "3.8"`, which Compose v2 ignores.
Fix: deleted the line (1-line diff, zero behavior change).

**Problem C — Tier-1 `web-proxy` in a `Restarting (1)` loop (restart count 22).**
`docker logs Tier-1-webproxy` showed `mkdir() "/var/cache/nginx/client_temp" failed (13: Permission denied)` repeating.
Root cause: `nginx/Dockerfile` set `USER nginx` but only `chown`ed `/etc/nginx` — the unprivileged user couldn't write `/var/cache/nginx`, `/var/run`, or `/var/log/nginx`, and couldn't bind privileged port 80. The official `nginx:alpine` image is designed to start as root and drop workers itself.
Fix (Plan A): removed `USER nginx`; also pointed `HEALTHCHECK` at proxy-only `/healthz` instead of `/` so proxy health doesn't depend on Flask being up. The similar-looking Flask `USER appuser` block was deliberately kept: it owns `/app` via `chown`, listens on unprivileged `5000`, and needs its `PATH`/`PYTHONUNBUFFERED` lines.

**Problem D — exposing the app (ports).**
Nginx `80:80` worked locally, but Jenkins on EC2 needed security-group port `8080` opened (restricted to `my_ip`) for `http://<EC2_IP>:8080`, and Flask `5000` stays internal-only behind `backend-net`. Documented in the README Jenkins section.

---

## Cleanup done for new users

Removed (scratch from the build, not needed to clone and run): `IAC.md` (infra IDs + passwords), `diagrams/` screenshots, stray root `terraform.tfstate`, local `messages.db`/`instance/`, `__pycache__/`.
Kept locally but never committed (gitignored): `.env`, `terraform/terraform.tfstate*` (needed for `destroy`), DB files.
Kept in repo: `ARCHITECTURE.md` (network + threat-model reference).
