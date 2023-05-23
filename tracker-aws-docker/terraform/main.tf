terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    porkbun = {
      source  = "cullenmcdermott/porkbun"
      version = "~> 0.2.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

provider "porkbun" {
  api_key    = data.aws_ssm_parameter.porkbun_api-key.value
  secret_key = data.aws_ssm_parameter.porkbun_secret-key.value
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_key_pair" "kp_w11" {
  key_pair_id        = "key-0604359350bf44939"
  include_public_key = true
}

data "aws_key_pair" "kp_l14-rsa" {
  key_pair_id        = "key-0cc0e60ea2fbaa8be"
  include_public_key = true
}

data "aws_key_pair" "kp_l14-ed25519" {
  key_pair_id        = "key-0fbd662b002cd34d4"
  include_public_key = true
}

data "aws_key_pair" "kp_gh-actions" {
  key_pair_id        = "key-0b35fb14992ee1c5f"
  include_public_key = true
}

data "aws_acm_certificate" "cert_relyq_dev" {
  domain = "*.relyq.dev"
}

data "aws_s3_object" "s3_demo_clean" {
  bucket = "relyq-tracker-bucket"
  key    = "demo_clean.py"
}

data "cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "import_cert.sh"
    content_type = "text/x-shellscript"
    content      = <<-EOT
    ${local.import_cert_script}
    EOT
  }

  part {
    filename     = "import_secrets.sh"
    content_type = "text/x-shellscript"
    content      = <<-EOT
              #!/bin/bash
              ENV_PATH=/root/.tracker.env
              echo "export TRACKER_CERT_PATH='/etc/pki/ca-trust/source/anchors/relyq.dev'" >> $ENV_PATH
              echo "export ASPNETCORE_URLS='https://+:7004'" >> $ENV_PATH
              echo "export ASPNETCORE_HTTPS_PORT='7004'" >> $ENV_PATH
              echo "export ASPNETCORE_ENVIRONMENT='Production'" >> $ENV_PATH
              echo "export ASPNETCORE_CONTENTROOT='/publish/'" >> $ENV_PATH
              echo "export Tracker__BaseUrl='https://aws.relyq.dev:7004'" >> $ENV_PATH
              echo "export Secrets__SQLConnection='${data.aws_ssm_parameter.sql_connection.value}'" >> $ENV_PATH
              echo "export Jwt__Key='${data.aws_ssm_parameter.jwt_key.value}'" >> $ENV_PATH
              echo "export Secrets__SMTPPassword='${data.aws_ssm_parameter.smtp_password.value}'" >> $ENV_PATH
              EOT
  }

  part {
    filename     = "import_clean_script.sh"
    content_type = "text/x-shellscript"
    content      = <<-EOT
              #!/bin/bash
              HOME_DIR=/opt/tracker
              crontab -l -u tracker > $HOME_DIR/cron_tracker
              mkdir $HOME_DIR/scripts/
              aws s3 cp s3://${data.aws_s3_object.s3_demo_clean.bucket}/${data.aws_s3_object.s3_demo_clean.key} $HOME_DIR/scripts/demo_clean.py
              chmod +x $HOME_DIR/scripts/demo_clean.py
              echo -e "Secrets__JanitorPassword='${data.aws_ssm_parameter.tracker-janitor_password.value}'" >> $HOME_DIR/cron_tracker
              echo -e "Tracker__BaseUrl='https://aws.relyq.dev:7004'" >> $HOME_DIR/cron_tracker
              echo -e "@daily /usr/bin/python3 /opt/tracker/scripts/demo_clean.py" >> $HOME_DIR/cron_tracker
              crontab -u tracker $HOME_DIR/cron_tracker
              rm $HOME_DIR/cron_tracker
              EOT
  }

  part {
    filename     = "add_cicd_kp.sh"
    content_type = "text/x-shellscript"
    content      = <<-EOT
          #!/bin/bash
          HOME_DIR=/home/ec2-user
          echo "${data.aws_key_pair.kp_gh-actions.public_key}" >> $HOME_DIR/.ssh/authorized_keys
          EOT
  }

  part {
    filename     = "init.yaml"
    content_type = "text/cloud-config"
    content      = file("../cloud-init/init.yaml")
  }
}

data "aws_iam_instance_profile" "tracker_ec2_instance_profile" {
  name = "tracker-ec2-ssm-s3"
}

resource "aws_instance" "server" {
  ami = "ami-02396cdd13e9a1257" # amazon linux 2023
  #ami                    = "ami-01e5ff16fd6e8c542" # debian 11
  instance_type          = "t2.micro"
  key_name               = data.aws_key_pair.kp_w11.key_name
  subnet_id              = aws_subnet.tracker_subnet.id
  vpc_security_group_ids = [aws_security_group.allow_api_port.id, aws_security_group.allow_https.id, aws_security_group.allow_ssh.id]
  iam_instance_profile   = data.aws_iam_instance_profile.tracker_ec2_instance_profile.name
  user_data              = data.cloudinit_config.config.rendered

  tags = {
    Name = "Tracker"
  }
}

resource "porkbun_dns_record" "dns" {
  domain  = "relyq.dev"
  name    = "aws"
  type    = "A"
  content = aws_instance.server.public_ip
  notes   = "autogenerated by terraform"
  ttl     = "600"

  lifecycle {
    replace_triggered_by = [aws_instance.server]
  }
}