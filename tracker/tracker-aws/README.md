## known issues

- python scripts take way too long to run on EC2. i'm not quite sure why - running a trace shows it hangs on every socket.connect() call
  - tried disabling ipv6 - no effect

## todo

- secret management (using aws params store - should learn hcp vault)

- file templates - im storing my entire unit file on aws params store. i should only store the secrets and inject them into my instance

- create new rds with terraform and set it to no delete so all resources share vpc
