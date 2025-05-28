data "aws_ssm_parameter" "cert_relyq_dev_privkey" {
  name            = "relyq.dev-privkey"
  with_decryption = true
}

data "aws_ssm_parameter" "tracker_api-unit_file" {
  name            = "tracker_api-unit_file"
  with_decryption = true
}

data "aws_ssm_parameter" "tracker-janitor_password" {
  name            = "tracker-janitor_password"
  with_decryption = true
}

data "aws_ssm_parameter" "porkbun_api-key" {
  name            = "porkbun_api-key"
  with_decryption = true
}

data "aws_ssm_parameter" "porkbun_secret-key" {
  name            = "porkbun_secret-key"
  with_decryption = true
}