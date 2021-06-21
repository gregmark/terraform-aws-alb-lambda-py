# terraform-aws-alb-lambda-py

Deploys a simple AWS lambda using the python3.8 runtime.

## Operation

1. Ensure that you have access to python >= 3.8.
1. Run: `pip install awscli boto3`.
1. Follow [these instructions](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html) to setup AWS access keys with your terminal environment or simply run `aws confifgure`
1. Install terraform v1.0.0 via some package manager or download [from here](https://www.terraform.io/downloads.html).
1. Build
  ```
  git clone git@github.com:gregmark/terraform-aws-alb-lambda-py.git
  cd terraform-aws-alb-lambda-py/level0
  terraform init
  terraform apply -auto-approve
  ```
1. Test
  ```
  cd ..
  bash invoke.sh -h
  bash invoke.sh '?alb'
  bash invoke.sh now
  bash invoke.sh version
  bash invoke.sh
  ```
1. Destroy
  ```
  cd level0
  terraform destroy -auto-approve
  ```
