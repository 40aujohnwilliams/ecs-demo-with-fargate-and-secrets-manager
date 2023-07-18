# ECS Demo w/ Fargate and Secrets Manager

This project demonstrates running a service in ECS with Fargate as the runner.
The service has environment variables populated from the Secrets Manager.

The service (`env_var_svc`) is a Node.js service with a single endpoint at the
root. The service returns the following output. `MY_ENV_VAR_0` is a static 
value while `MY_ENV_VAR_1`, `MY_ENV_VAR_2`, and `MY_ENV_VAR_3` are stored as
key-value pairs in the Secrets Manager as `MY-SECRET-1`, `MY-SECRET-2`, and 
`MY-SECRET-3`.

```json
{
  "MY_ENV_VAR_0":"hello world",
  "MY_ENV_VAR_1":"foo",
  "MY_ENV_VAR_2":"bar",
  "MY_ENV_VAR_3":"baz"
}
```