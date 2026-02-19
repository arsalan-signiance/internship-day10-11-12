# DevOps Internship Project – Contact Manager Deployment on AWS with Alerting

---

## Project Overview

This project demonstrates the complete deployment of a full stack Contact Manager application on AWS using production style architecture.

The application consists of:

- Frontend hosted on Amazon S3
- Global content delivery using Amazon CloudFront (CDN)
- Dockerized backend deployed on Amazon ECS Fargate
- Two-container ECS task (API + ADOT sidecar)
- Application Load Balancer for backend exposure
- Private VPC networking (Public + Private subnets)
- Metrics collection using AWS Distro for OpenTelemetry (ADOT)
- Metrics storage in Amazon Managed Service for Prometheus (AMP)
- Alerting via Amazon SNS (Email notifications)
- Infrastructure managed using Terraform

The backend exposes Prometheus metrics which are collected by Amazon Managed Service for Prometheus (AMP). Alert rules evaluate service health, and when a failure is detected, Amazon SNS sends real-time email notifications.

All infrastructure components are provisioned and managed using Terraform with a modular structure.

---
# Architecture Overview

## Frontend Layer

### Amazon S3
The frontend (static website) of the Contact Manager application is hosted in an S3 bucket configured for static website hosting.

Used For:
- Hosting HTML, CSS, JavaScript files
- Storing frontend assets

### Amazon CloudFront
CloudFront is integrated with the S3 bucket to deliver frontend content globally with low latency and caching.

Used For:
- Content Delivery Network
- Improved performance
- Reduced latency
- HTTPS secure delivery

---

## Backend Layer

### Dockerized Backend
The backend API is containerized using Docker.

The Docker image is stored in **Docker Hub**.

### Amazon ECS, Fargate Launch Type
ECS Fargate is used to run containers without managing EC2 servers.

Used For:
- Running backend container
- Serverless container execution
- Automatic scaling capability

Fargate removes the need to manage EC2 instances.

---
# ECS Task Definition, Multi Container Setup

The ECS task definition includes **two containers**:

---

## 1. API Container

- Runs Contact Manager backend
- Exposes metrics at:
```
http://127.0.0.1:5000/metrics
```
- Sends logs to CloudWatch
- Runs inside private subnet

---

## 2. ADOT Sidecar Container

AWS Distro for OpenTelemetry (ADOT) collector runs as a sidecar container in the same task.

Image Used:
```
public.ecr.aws/aws-observability/aws-otel-collector:latest
```
Purpose:
- Scrape application metrics
- Forward metrics to Amazon Managed Prometheus (AMP)

This creates a clean integration between:

Amazon ECS → ADOT → AMP

---

# SSM Parameter Store Integration

The ADOT collector configuration is stored in AWS Systems Manager (SSM) Parameter Store.

Used For:
- Keeping collector configuration decoupled from container image
- Secure configuration management
- Centralized configuration updates

Instead of hardcoding config inside container, ECS retrieves it dynamically from SSM.

This improves:
- Maintainability
- Security
- Flexibility

---
# ADOT Configuration Details

The ADOT collector is configured to:

### Prometheus Receiver

Scrape metrics from local container:
```
127.0.0.1:5000/metrics
```
This works because:
Both containers share the same network namespace in ECS.

---

### Remote Write Exporter

The collector forwards scraped metrics to the AMP workspace using:

Prometheus remote_write protocol

Flow:

API Container  → ADOT Sidecar  → AMP Workspace  

---
# AMP

AMP stores time-series metrics and evaluates alert rules.

Used For:
- Metric storage
- PromQL querying
- Alert rule evaluation

Example Alert Rule:
```
up{job="contact-manager"} == 0
```
If backend becomes unavailable:
Alert triggers.

---
# Amazon SNS 

SNS receives alert notifications from AMP Alert Manager.

Used For:
- Sending email notifications
- Decoupled alerting system

Flow:

AMP → SNS → Email

---


## Load Balancing Layer

### Application Load Balancer

The ALB routes incoming HTTP traffic to ECS tasks running in private subnets.

Used For:
- Distributing traffic across containers
- High availability
- Health checks
- Public endpoint for backend API

---

## Networking Layer 

### Amazon VPC 

A custom VPC is created to isolate and securely manage network resources.

Inside the VPC:

### Public Subnets
- ALB is deployed in public subnets
- Internet-facing resources reside here

### Private Subnets
- ECS Fargate tasks run in private subnets
- Not directly accessible from the internet

### Internet Gateway
Attached to the VPC to allow public internet access for:
- ALB
- Public subnets

### NAT Gateway
Placed in public subnet to allow private ECS tasks to:
- Pull Docker images from Docker Hub
- Access external internet securely

### Security Groups
Security Groups act as virtual firewalls.

Used For:
- Allowing HTTP traffic to ALB
- Allowing ALB to communicate with ECS
- Restricting unnecessary inbound traffic
- Securing backend containers

---

# Logging & Observability

## Amazon CloudWatch

Used For:
- ECS container logs
- Debugging application issues
- Monitoring task behavior

Each container logs to separate CloudWatch log groups.

---
# Infrastructure as Code, Terraform

All resources provisioned using Terraform modules.

Terraform Manages:

- VPC
- Public & Private Subnets
- Internet Gateway
- NAT Gateway
- Security Groups
- ECS Cluster & Service
- Multi-container Task Definition
- IAM Roles & Policies
- SSM Parameter Store
- AMP Workspace
- SNS Topic
- ALB

Benefits:
- Reproducible infrastructure
- Version control
- Automated deployments
- Clean modular structure

---

# Complete Monitoring Flow

1. Backend runs in ECS (private subnet)
2. API exposes `/metrics`
3. ADOT scrapes metrics locally
4. ADOT remote_writes to AMP
5. AMP evaluates alert rule
6. Alert Manager triggers SNS
7. SNS sends email notification

---

# Deployment Steps

## 1. Initialize Terraform
```
cd terraform/environments/dev
terraform init
```

## 2. Validate
```
terraform validate
```

## 3. Plan
```
terraform plan
```

## 4. Apply
```
terraform apply
```

---

# Testing Alert

To force an alert:

Modify rule condition temporarily:
```
up{job="contact-manager"} == 1
```

Apply changes → Email will be triggered.

---

# Cleanup

To delete infrastructure:
```
terraform destroy
```
---
# Key DevOps Concepts Implemented

- Multi-container ECS task (Sidecar pattern)
- OpenTelemetry integration
- Managed Prometheus monitoring
- Remote write metric forwarding
- Decoupled configuration using SSM
- Private subnet architecture
- NAT-based internet egress
- Infrastructure as Code
- Production grade alert pipeline
- Secure VPC network design
---

#  Author

Arsalan Sharief  
DevOps Intern 
Signiance Technology 