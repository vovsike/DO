path "kv/team1/*"
{
    capabilities = ["create", "read", "update", "list", "patch"]
}

path "kv/+"
{
    capabilities = ["list"]
}