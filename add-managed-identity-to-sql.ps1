Param(
    [Parameter(Mandatory=$true)][string]$SqlServer,
    [Parameter(Mandatory=$true)][string]$SqlDb,
    [Parameter(Mandatory=$true)][string]$SqlUserName,
    [Parameter(Mandatory=$true)][securestring]$SqlPassword,
    [Parameter(Mandatory=$true)][string]$ManagedIdentityName
)

Install-Module Sqlserver

$createUserQuery = @"
CREATE USER [$ManagedIdentityName] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [$ManagedIdentityName];
ALTER ROLE db_datawriter ADD MEMBER [$ManagedIdentityName];
GO
"@

$clearPw = ConvertFrom-SecureString -SecureString $SqlPassword -AsPlainText

Invoke-Sqlcmd -ServerInstance $SqlServer -Database $SqlDb -Username $SqlUserName -Password $clearPw -Query $createUserQuery

