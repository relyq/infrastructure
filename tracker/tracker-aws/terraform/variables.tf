locals {
  import_cert_script = <<-EOT
                        #!/bin/bash
                        mkdir "/etc/pki/ca-trust/source/anchors/relyq.dev/"
                        echo -e "${data.aws_acm_certificate.cert_relyq_dev.certificate}" > "/etc/pki/ca-trust/source/anchors/relyq.dev/cert.pem"
                        echo -e "${data.aws_ssm_parameter.cert_relyq_dev_privkey.value}" > "/etc/pki/ca-trust/source/anchors/relyq.dev/privkey.pem"
                        chmod -R 0700 "/etc/pki/ca-trust/source/anchors/relyq.dev"
                        update-ca-trust
                        EOT
}