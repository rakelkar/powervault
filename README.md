# powervault :diamond_shape_with_a_dot_inside::guardsman::star:
Scripts to load and save encrypted values in a local file vault and apply them as PROCESS environment variables

Uses Windows DPAPI to encrypt at rest.

Useful when you have tokens that you are using for DEV work and dont want to save them to your disk as plain text or hardcode them in your prototype code. This allows you to save them encrypted to a vault file and apply to PROCESS environment variables when you need them. Since it uses DPAPI there are no other passwords or certs to manage (Though to be honest I havent investigated how secure this is or what happens when your domain password changes).

```
# add fns to context
. .\vault.ps1

# set the VAULT_PATH env var for the current user
Set-Vault-Path -vaultPath c:\myvault.json

# create an empty vault
Initialize-Vault

# add or update an item (prompts for secret)
Update-Vault -key MY_SECRET

# enter vault (applies secrets to env vars scoped to the shell process)
Enter-Vault
```
