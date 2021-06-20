# terraform-aws-python-alf ( alb, lambda and flask)

Deploys a simple AWS lambda using the python3.8 runtime.

  * All AWS resources are deployed with Terraform 1.0.0 and the following providers:
    * aws 3.0.45
  * Use single python handler function:
    * One file, one function
    * Python ONLY (e.g no Node.JS helper code)
    * Runtime: Python 3.8
    * GET requests only, returns valid JSON
  * Build out complete, standalone VPC network stack
  * Create ALB configured to target our Lambda function
    * Create ALB target group to "target" the Lamnba service
    * Create Lambda permission to allow ALB to invoke Our Lambda
  * Least-privilege security
    * Ingress to VPC from Internet restricted to 80/tco
    * Egress to Internet from VPC cannot be initiatied (except return tcp traffic)
    * ALB can access Lambda on 80/tcp only
    * Lambda can send return tcp traffic to the ALB

## Terraform Breakdown

### Networking

* VPC (`vpc`)
* VPC security group (`sg`)
* private subnets (`subnet`, 2)
* Internet gateway (`igw`)
* VPC Route table (`rtb`)
* Route table associations (`rtb-assoc`, 2, one per subnet)
* Network ACL (`nacl`)
  * egress: return tcp traffic
  * ingress: tcp 80

### ALB

* 1 ALB
  * 1 target group
    * type lambda
    * health Checks disabled
  * 1 listener
    * Forward 80/tcp to lambda
  * 1 security group

### Lambda

* 1 Lambda function
  * runtime Python 3.8
  * $LATEST version
  * vpc-config
* 1 role
* 1 attached policy to manage EC2 network interfaces
* 1 security group
* 1 Lambda alias
* 1 Lambda permission for ALB
