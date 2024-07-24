# Docker Commands to Build and Run the Container

## Build the Docker Image

1. Open your terminal and navigate to the root directory of your project.

2. Build the Docker image using the following command. Replace `your_image_name` with a name you want to give your Docker image:

   ```sh
   docker build -t your_image_name .

#### Run the Docker image.
This will map your port on your server to the port exposed in Docker. The Docker container will be called "myapp" and will be removed automatically after termination
   ```sh
   docker run --name myapp --rm -d -p 8080:8080 --name your_container_name your_image_name

   ```
   This will write the "ping" file out to the mount point /tmp on your machine/server, otherwise the file will be on the container.
   See below how to access the file
 
  ```sh  
    docker run --name myapp --rm -d -v /tmp:/tmp -p 8080:8080 --name your_container_name your_image_name

   ```


#### Verify the Container is Running
   ```sh
   docker ps

   ```
#### Access the Application

   ```sh
 curl http://localhost:8080/ping

   ```
   
#### check the file on the container.
   ```sh
docker exec your_container_name cat /tmp/pin

   ```
Or if written to mount point /tmp directory simply:
```sh
cat /tmp/ping
```

#
#
#
   
# Running the Helm Chart and installing on EKS
#

## Prerequisites
Ensure EKS cluster is configured with config file.
```
kubectl get nodes
```



## Step 1: Initialize Helm

Initialize Helm (if helm chart was in helm repo):

```sh
helm repo add stable https://<chart-repo>/<name_of_chart>
helm repo update
```
## Step 2: Dry Run


```sh
helm template monolith --debug ./myapp
```
## Step 3: Install the Helm Chart


```sh
helm install monolith ./myapp

```
## Step 4: Test the Application
Will be installed in the default namespace.
Use -n if in another namespace

```sh
kubectl get service monolith -n default

```

```sh
curl http://<external-ip>/ping
```


#
#
#


# Running the Terraform Code

## Prerequisites

Ensure you have the following installed and configured:
- Terraform command-line tool
- AWS CLI configured with appropriate credentials (if deploying to AWS)

## Step 1: Navigate to the Terraform Directory

Open your terminal and navigate to the directory where your Terraform configuration files (`main.tf`, `variables.tf`, `provider.tf`, `backend.tf`, etc.) are located:

```sh
cd terraform/
```
The backend is stored in an s3 bucket.

## Step 2:  Initialize Terraform
```sh
terraform init

```
output example
```
Initializing the backend...

Initializing provider plugins...
- Finding latest version of hashicorp/aws...
- Installing hashicorp/aws v3.38.0...
- Installed hashicorp/aws v3.38.0 (signed by HashiCorp)

Terraform has been successfully initialized!
```
## Step 3:  Validate the Configuration (Optional)

Validate the Terraform configuration files to ensure they are syntactically valid:

```sh
terraform validate

```
## Step 4:  Generate and Review an Execution Plan
Generate an execution plan to see what actions Terraform will take to achieve the desired state defined in your configuration files:
```sh
terraform plan -out=tfplan

```
-out=tfplan: This option saves the generated plan to a file named tfplan.



```
An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_vpc.main will be created
  + resource "aws_vpc" "main" {
      + cidr_block = "10.0.0.0/16"
      + enable_dns_hostnames = false
      + enable_dns_support = true
      + instance_tenancy = "default"
      + tags = {
          + "Name" = "main-vpc"
        }
      + id = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

This plan was saved to: tfplan

To perform exactly these actions, run the following command to apply:
    terraform apply "tfplan"
```

## Step 5:  Apply the Configuration

```sh
terraform apply "tfplan"

```
Or pass values to the terraform command.
```sh
terraform apply -var="name=yourname"

```
Or with an empty string.
```sh
terraform apply -var="name="

```

Output example:
```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_vpc.main: Creating...
aws_vpc.main: Creation complete after 5s [id=vpc-0abcd1234efgh5678]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```
After applying the configuration, you can see the output for the EKS cluster name:

```sh
terraform output eks_cluster_name

```

### Configure cluster and connect to cluster

setup kubeconfig file.

```sh
aws eks update-kubeconfig --region eu-west-2 --name <cluster-name>
```

apply config map to access cluster.

```sh
kubectl get configmaps -n kube-system aws-auth -oyaml > autconfig.yaml
kubectl apply -f  autconfig.yaml
```


Install appliacation to cluster

```sh
helm install monolith ./myapp

```

Check service is running.

```sh
kubectl get services -n default
```

check pods in cluster.

```sh
kubectl get pods -n default
```

Remove cluster.

```sh
terraform destroy
```
#
#
#
#

# Scaling the Application to Handle 1000 Requests per Second

To scale an application to handle 1000 requests per second, we need to ensure that our infrastructure, application design, and operational practices are optimised for high performance, reliability, and scalability. Here’s a high-level description of the approach, including specific tools and services that would be used:

## Infrastructure

### Elastic Kubernetes Service (EKS)
- **Auto-scaling**: Utilise Kubernetes Horizontal Pod Autoscaler (HPA) to automatically scale the number of pods based on CPU/memory usage or custom metrics.
- **Cluster Autoscaler**: Integrate Kubernetes Cluster Autoscaler to automatically adjust the number of nodes in your cluster based on the pod resource requests.

### Amazon EC2
- **Instance Types**: Use a mix of EC2 instance types (e.g., general-purpose, compute-optimised) to handle different workload requirements.
- **Auto Scaling Groups**: Configure EC2 Auto Scaling Groups to ensure that the number of instances scales dynamically based on demand.

### Networking
- **Amazon VPC**: Ensure a well-architected VPC design with multiple subnets (public/private) across different availability zones for high availability.
- **Elastic Load Balancer (ELB)**: Use an Application Load Balancer (ALB) to distribute incoming traffic across multiple instances and ensure fault tolerance.

## Application Design

### Microservices Architecture
- **Decoupling**: Break down the application into smaller, independent services that can be developed, deployed, and scaled independently.
- **Containerization**: Use Docker containers to package and deploy services, ensuring consistency across different environments.

### Caching
- **In-memory Caching**: Use services like Amazon ElastiCache (Redis or Memcached) to cache frequently accessed data and reduce load on the database.
- **Content Delivery Network (CDN)**: Use Amazon CloudFront to cache static assets and reduce latency for end-users.

### Database Optimisation
- **Amazon RDS/Aurora**: Use managed relational databases with read replicas to handle read-heavy workloads.
- **NoSQL Databases**: Consider using Amazon DynamoDB for highly scalable and low-latency data access patterns.
- **Database Sharding**: Implement sharding to distribute database load across multiple instances.

## Operational Practices

### Monitoring and Logging
- **Amazon CloudWatch**: Use CloudWatch to monitor application metrics, set up alarms, and gain insights into application performance.
- **Centralised Logging**: Use services like Amazon Elasticsearch Service (with Kibana) or Grafana Loki for centralised log management and analysis.

### CI/CD Pipeline
- **Continuous Integration/Continuous Deployment**: Implement CI/CD pipelines using tools like Jenkins, GitLab CI, or AWS CodePipeline to automate testing and deployment processes.
- **Canary Deployments**: Use canary deployments to gradually roll out changes to a subset of users and monitor for issues before a full-scale release.

## Scaling Strategy

### Horizontal Scaling
- **Kubernetes HPA**: Automatically increase the number of pod replicas based on real-time metrics (e.g., CPU, memory, custom application metrics).
- **Cluster Autoscaler**: Adjust the number of nodes in the EKS cluster to ensure sufficient capacity for the increased number of pods.
- **Tools**: Use tools like k6s https://k6.io/ to force load on to the cluster.

### Vertical Scaling
- **Resource Allocation**: Ensure pods have appropriate resource requests and limits defined to allow Kubernetes to make informed scheduling decisions.
- **Instance Size**: Use larger instance types in EC2 Auto Scaling Groups as needed to handle increased load.

### Load Balancing
- **Application Load Balancer**: Configure ALB to distribute traffic evenly across pods, with health checks to ensure only healthy instances receive traffic.
- **Global Accelerator**: Use AWS Global Accelerator to improve availability and performance by routing traffic to the nearest healthy endpoint.

## Resilience and High Availability

### Multi-AZ Deployment
- Deploy applications across multiple Availability Zones (AZs) to ensure high availability and fault tolerance.

### Disaster Recovery
- Implement backup and recovery strategies for critical data and services.
- Use Amazon RDS automated backups and snapshots for database recovery.

### Rate Limiting and Throttling
- Implement rate limiting at the API Gateway level (e.g., using Amazon API Gateway) to protect backend services from being overwhelmed by sudden traffic spikes.

## Summary

By leveraging AWS managed services and best practices for application architecture and operational excellence, we can build a scalable, resilient, and high-performance system capable of handling 1000 requests per second. This involves using EKS for container orchestration, implementing auto-scaling policies, optimising database access, and ensuring robust monitoring and logging practices.
