### Creating a secret
Create a secret in kv/admins-only, the secret will be pass and the values is secret-password with key of password
```
vault kv put kv/admins-only/pass password="secret-password"
```

Create a secret in kv/u-a, the secret will be u-a-pass and the values is secret-password with key of password
```
vault kv put kv/u-a/u-a-pass password="ua-password"
```

### Creating a new userpass method
```
vault write auth/userpass/users/u-a \
password=u-a-pass
```

### Attaching policy to a new user
```
vault write auth/userpass/users/u-a/policies \
token_policies=["u-a"]
```

### Policy to allow to view all path but only to acess the given one 
```
path "fase/team1/*" {
    capabilities = ["create", "read", "update", "list", "patch"]
}

path "fase/team2" {
  capabilities = ["deny"]
}

path "fase/*" {
  capabilities = ["list"]
}
```