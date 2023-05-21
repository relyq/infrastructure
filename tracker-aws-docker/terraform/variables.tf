locals {
  import_cert_script = <<-EOT
                        #!/bin/bash
                        CERT_PATH=/etc/pki/ca-trust/source/anchors
                        mkdir "$CERT_PATH/relyq.dev/"
                        echo -e "${data.aws_acm_certificate.cert_relyq_dev.certificate}" > "$CERT_PATH/relyq.dev/cert.pem"
                        echo -e "${data.aws_ssm_parameter.cert_relyq_dev_privkey.value}" > "$CERT_PATH/relyq.dev/privkey.pem"
                        chmod -R 0700 "$CERT_PATH/relyq.dev"
                        update-ca-trust
                        EOT
}