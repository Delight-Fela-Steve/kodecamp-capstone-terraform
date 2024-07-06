# About
This project creates an ec2 instance, installs docker, pulls a web application image and starts a container with the image. The web application is accessed by going to the public domain or ip address of the created ec2 instance along with the web application port.

# Implementation
1. The first block specifies the provider (aws) and the version of terraform to use. The versions determines the type of resources that can be used.
```
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.5.1"
}

```

2. The second block specifies the region where the resources should be created
```
provider "aws" {
  region = "us-east-1"
}
```

3. The third block specifies the instance to be created. It consists of the Amazon Machine Image (AMI), the instance type, and the security groups to be attached to it. For this project, security groups for allowing ssh connections, security group for allowing a specific port used for a web application. It also specifies a user_data section which allows the instance to run specific commands after it's creation. The commands are written in bash script and the file is referenced as seen in the code block below. For this project, commands to install docker, pull an image that contains a web application and to run that image are put in the bash script.

```
resource "aws_instance" "app_server" {
  ami                    = "ami-04b70fa74e45c3917"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_ssh.id, aws_security_group.allow_web_port.id]
  key_name               = "kodehauz-practice-keypair"


  user_data = file("install_docker.sh")

  tags = {
    Name = "KodeCampCapstone"
  }

}
```

4. The fourth block just creates a default vpc that would be used for all resources created through terraform.

```
resource "aws_default_vpc" "default" {

}
```
5. The fifth block creates the security group for allowing ssh, which is referenced by the aws instance in block 2.

```
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic and all outbound traffic"
  vpc_id      = aws_default_vpc.default.id

}
```

6. The sixth block creates an ingress rule. The ingress rule basically specifies the rules to allow incoming connections. It is tied to the security group created in block 5. It allows connections to port 22, which is the port for ssh, the cidr_ipv4 specifies that connection should be allowed from anywhere

```
resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}
```

7. The seventh block creates an egress rule. The egress rule specifies the rules to allow outgoing connections. It is also tied to the security group created in block 5. The egress rule allows all outgoing connections. This is important as the ec2 instance would not be able to download or make network requests if this isn't specified. An example of an outgoing network request is when you try to run ```sudo apt update```. The command tries to get the latest updates for the software running on the ec2 instance and you would get errors if the egress rule is not set. Other network requests can be "installing a package", "using the curl package" etc.

```
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
```

8. The eigth block creates the security group to allow access to a specific port for a web application that would be running on the ec2 instance. The pattern here is the same as that for block 5.
```
resource "aws_security_group" "allow_web_port" {
  name        = "allow_web_port"
  description = "Allow inbound traffic to port 8000"
  vpc_id      = aws_default_vpc.default.id

}

```

9. The ninth block creates the ingress rule for the security group in block 8. It allows connections from anywhere for the specified port

```
resource "aws_vpc_security_group_ingress_rule" "allow_web_port" {
  security_group_id = aws_security_group.allow_web_port.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8000
  ip_protocol       = "tcp"
  to_port           = 8000
}
```

10. The tenth block creates the security group for apache. Apache usually runs on port 80

```
resource "aws_security_group" "allow_apache_port" {
  name        = "allow_apache_port"
  description = "Allow inbound traffic to port 80"
  vpc_id      = aws_default_vpc.default.id

}
```

11. The eleventh block creates the ingress rule for the security group in block 10.

# Possible Improvements
1. The resources can be speparated into different files for better organization

2. During the implementation of this project, I had issues with the terraform state. 

    The terraform state basically allows you to keep track of whatever modifications you make as regards to the resources. When running the terraform apply command locally, the state of the resources are stored in a terraform.tfstate file. This system works fine if you only plan to run terraform manually and from your local machine. 

    It become more complicated when I tried to integrate terraform into my CI pipeline using github actions. When github actions runs the terraform apply command, the terraform.tfstate is lost when the github actions completes. Also, this leads to a desynchronization of the state you have locally you get errors when you try to run the terraform apply or terraform delete command. 

    *PS*: A few browsing around and I was able to come up with the solution of storing the state in an s3 bucketas seen in the code block below. This helps with the state in github actions and the synchronizing of your terraform code locally, since they would both be using the same state file. This does not have to be the best way and other methods can be used to handle the terraform state.

    ```
    terraform {
        required_providers {
            aws = {
            source  = "hashicorp/aws"
            version = "~> 5.0"
            }
        }

        required_version = ">= 1.5.1"

        backend "s3" {
            bucket = "kodecamp-capstone"
            key    = "terraform.tfstate"
            region = "us-east-1"
        }
    }
    ```
    emphasis on the following:
    ```
    backend "s3" {
        bucket = "kodecamp-capstone"
        key    = "terraform.tfstate"
        region = "us-east-1"
    }
    ```

    Youtube Link To The Solution:
    https://www.youtube.com/watch?v=LzWBPIgbrXM&t=923s