<# Custom Script for Windows to join an RDSH to an RDS Collection - run it from the RDSH you want to add #>
param (
    [string]$connectionBroker,
    [string]$collection
)
$myFQDN=(Get-WmiObject win32_computersystem).DNSHostName+"."+(Get-WmiObject win32_computersystem).Domain

Add-RDServer -Server $myFQDN -ConnectionBroker $connectionBroker -Role RDS-RD-SERVER
 
Add-RDSessionHost -CollectionName $collection -SessionHost $myFQDN -ConnectionBroker $connectionBroker