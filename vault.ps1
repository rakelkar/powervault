# http://get-powershell.com/post/2008/12/13/Encrypting-and-Decrypting-Strings-with-a-Key-in-PowerShell.aspx
# no key since we rely on DPAPI to encrypt based on creds: https://msdn.microsoft.com/en-us/library/ms995355.aspx
function Set-EncryptedData {
    param([string]$plainText)
    $securestring = new-object System.Security.SecureString
    $chars = $plainText.toCharArray()
    foreach ($char in $chars) {$secureString.AppendChar($char)}
    $encryptedData = ConvertFrom-SecureString -SecureString $secureString
    return $encryptedData
}

function Get-EncryptedData {
    param($data)
    $data | ConvertTo-SecureString |
    ForEach-Object {[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($_))}
}

# set the vault path env variable for the current user
function Set-Vault-Path {
    param([Parameter(Mandatory=$true)][string] $vaultPath)
    [Environment]::SetEnvironmentVariable("VAULT_PATH", $vaultPath, "User")
    [Environment]::SetEnvironmentVariable("VAULT_PATH", $vaultPath, "Process")
}

function Update-Vault {
    param(
        [string] $vaultPath = $env:VAULT_PATH,
        [bool] $applyValue = $false,
        [Parameter(Mandatory=$true)][string] $key,
        [string] $plainText
        )

    if(![System.IO.File]::Exists($vaultPath)) {
        throw 'vault not found at: [' + $vaultPath + ']'
    }

    $updated = $false
    $now=Get-Date -format "dd-MMM-yyyy HH:mm"

    if([string]::IsNullOrEmpty($plainText)) {
        Write-Host "Enter secret value: "
        $secureString = Read-Host -AsSecureString
        $secret = ConvertFrom-SecureString -SecureString $secureString
    } else {
        $secret = Set-EncryptedData($plainText)
    }

    $contents = Get-Content $vaultPath | Out-String | ConvertFrom-Json
    $contents.lastUpdated = $now
    foreach($obj in $contents.secrets) {
        if ($obj.name -eq $key) {
            Write-Host ("Updating " + $obj.name)
            $obj.secret = $secret
            $obj.lastUpdated = $now
            $updated = $true
            break
        }
    }

    if ($updated -ne $true) {
        Write-Host ("Inserting " + $key)
        $newobj = @{
            name = $key
            secret = $secret
            lastUpdated = $now
        }

        $contents.secrets += $newobj
    }
    
    $contents | ConvertTo-Json | Out-File $vaultPath

    if ($applyValue -eq $true) {
        [Environment]::SetEnvironmentVariable($key, $plainText, "Process")
    }        
}

function Initialize-Vault {
    param([string] $vaultPath = $env:VAULT_PATH)

    if([System.IO.File]::Exists($vaultPath)){
        throw 'vault exists: [' + $vaultPath + ']'
    }

    $vaultName = Split-Path $vaultPath -leaf
    $now=Get-Date -format "dd-MMM-yyyy HH:mm"
    $plainText = "Vault: [" + $vaultName + "] created by: [" + $env:UserName + "] on [" + $now + "]"
    $secretText = Set-EncryptedData($plainText)

    $contents = '{"vault": "VAULT_INFO_PLAINTEXT", "createdBy": "VAULT_OWNER", "lastUpdated": "CURRENT_DATE", "secrets": [{"name": "VAULT_INFO", "secret": "VAULT_INFO_SECRET", "lastUpdated": "CURRENT_DATE"}]}'
    $contents = $contents.Replace("VAULT_INFO_PLAINTEXT", $plainText)
    $contents = $contents.Replace("VAULT_OWNER", $env:UserName)
    $contents = $contents.Replace("CURRENT_DATE", $now)
    $contents = $contents.Replace("VAULT_INFO_SECRET", $secretText)

    $contents | Out-File $vaultPath
}
function Enter-Vault {
    param(
        [string] $vaultPath = $env:VAULT_PATH,
        [bool] $applyValue = $true,
        [string] $scope = "Process"        
        )

    if(![System.IO.File]::Exists($vaultPath)){
        throw 'vault not found at: [' + $vaultPath + ']'
    }

    $operation = "Applying"
    if ($applyValue -eq $false) {
        $operation = "Showing"
    }
    $contents = Get-Content $vaultPath | Out-String | ConvertFrom-Json
    Write-Host ($operation + " secrets for " + $scope + " from: " + $vaultPath)
    Write-Host ("vault createdBy [" + $contents.createdBy + "], last updated on: " + $contents.lastUpdated)
    foreach($obj in $contents.secrets)
    {
        $plainText = Get-EncryptedData($obj.secret)
        if ($applyValue -eq $true) {
            Write-Host ($obj.name)
            [Environment]::SetEnvironmentVariable($obj.name, $plainText, $scope)
        } else {
            Write-Host ($obj.name + ' = "' + $plainText + '"')
        }
    }
}

function Exit-Vault {
    param([string] $vaultPath = $env:VAULT_PATH)

    if(![System.IO.File]::Exists($vaultPath)){
        throw 'vault not found at: [' + $vaultPath + ']'
    }

    $contents = Get-Content $vaultPath | Out-String | ConvertFrom-Json
    foreach($obj in $contents.secrets)
    {
        Write-Host ($obj.name)
        [Environment]::SetEnvironmentVariable($obj.name, $plainText, "Process")
    }
}
