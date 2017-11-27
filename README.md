# powervault
Scripts to load and save encrypted strings into environment variables

```
# set the VAULT_PATH env var for the current user
Set-Vault-Path -vaultPath c:\myvault.json

# create an empty vault
Initialize-Vault

# add or update an item (prompts for secret)
Update-Vault -key MY_SECRET

# enter vault (applies to env vars scoped the shell process)
Enter-Vault
```

```
