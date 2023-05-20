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

data "cloudinit_config" "api_config" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "import_cert.sh"
    content_type = "text/x-shellscript"
    content      = <<-EOT
    ${local.import_cert_script}
    chown -R tracker:tracker "/etc/pki/ca-trust/source/anchors/relyq.dev"
    EOT
  }

  part {
    filename     = "import_unit_file.sh"
    content_type = "text/x-shellscript"
    content      = <<-EOT
    #!/bin/bash
    echo "${data.aws_ssm_parameter.tracker_api-unit_file.value}" > "/etc/systemd/system/tracker.service"
    EOT
  }

  part {
    filename     = "import_crontab.sh"
    content_type = "text/x-shellscript"
    content      = <<-EOT
    #!/bin/bash
    HOME_DIR=/opt/tracker
    crontab -l -u tracker > $HOME_DIR/cron_tracker
    echo -e "Secrets__JanitorPassword='${data.aws_ssm_parameter.tracker-janitor_password.value}'" >> $HOME_DIR/cron_tracker
    echo -e "Tracker__BaseUrl='https:--aws\x2dtracker\x2dapi.relyq.dev:7004'" >> $HOME_DIR/cron_tracker
    echo -e "@daily /usr/bin/python3 /opt/tracker/api/scripts/demo_clean.py" >> $HOME_DIR/cron_tracker
    crontab -u tracker $HOME_DIR/cron_tracker
    rm $HOME_DIR/cron_tracker
    EOT
  }

  part {
    filename     = "init.yaml"
    content_type = "text/cloud-config"
    content      = file("../cloud-init/api.yaml")
  }
}

data "cloudinit_config" "frontend_config" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "import_cert.sh"
    content_type = "text/x-shellscript"
    content      = <<-EOT
    ${local.import_cert_script}
    chown -R nginx:nginx "/etc/pki/ca-trust/source/anchors/relyq.dev"
    EOT
  }

  part {
    filename     = "init.yaml"
    content_type = "text/cloud-config"
    content      = file("../cloud-init/frontend.yaml")
  }
}

data "aws_iam_instance_profile" "tracker_ec2_instance_profile" {
  name = "tracker-ec2-ssm-s3"
}

resource "aws_instance" "api_server" {
  ami                    = "ami-02396cdd13e9a1257"
  instance_type          = "t2.micro"
  key_name               = data.aws_key_pair.kp_w11.key_name
  subnet_id              = aws_subnet.tracker_subnet.id
  vpc_security_group_ids = [aws_security_group.allow_api_port.id, aws_security_group.allow_ssh.id]
  iam_instance_profile   = data.aws_iam_instance_profile.tracker_ec2_instance_profile.name
  user_data              = data.cloudinit_config.api_config.rendered

  tags = {
    Name = "TrackerAPI"
  }
}

resource "aws_instance" "frontend_server" {
  ami                    = "ami-02396cdd13e9a1257"
  instance_type          = "t2.micro"
  key_name               = data.aws_key_pair.kp_w11.key_name
  subnet_id              = aws_subnet.tracker_subnet.id
  vpc_security_group_ids = [aws_security_group.allow_https.id, aws_security_group.allow_ssh.id]
  iam_instance_profile   = data.aws_iam_instance_profile.tracker_ec2_instance_profile.name
  user_data              = data.cloudinit_config.frontend_config.rendered

  tags = {
    Name = "TrackerFrontend"
  }
}
