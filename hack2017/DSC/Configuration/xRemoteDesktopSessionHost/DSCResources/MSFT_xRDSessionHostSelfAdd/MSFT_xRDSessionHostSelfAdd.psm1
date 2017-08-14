if ([System.Environment]::OSVersion.Version -lt "6.2.9200.0") { Throw "The minimum OS requirement was not met."}

Import-Module RemoteDesktop

$localhost = [System.Net.Dns]::GetHostByName((hostname)).HostName


#######################################################################
# The Get-TargetResource cmdlet.
#######################################################################
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (    
        [string] $ConnectionBroker,
 
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $CollectionName
    )

    $result = $null

    $collection = Get-RDSessionCollection @PSBoundParameters -ea SilentlyContinue 

    if ($collection)
    {
        Write-verbose "found the collection, now getting list of RD Session Host servers..."

        $SessionHosts = Get-RDSessionHost @PSBoundParameters | % SessionHost
        write-verbose "found $($SessionHosts.Count) host servers assigned to the collection."
        
        #loop
        $SessionHosts | ForEach-Object {
            if ($_ -ieq $localhost){
                $result = 
                @{
                    "ConnectionBroker" = $ConnectionBroker
                
                    "CollectionName"   = $collection.CollectionName

                    "SessionHosts" = $SessionHosts
                }

                write-verbose "-- Collection name:  $($result.CollectionName)"
                write-verbose "-- RD Connection Broker:  $($result.ConnectionBroker.ToLower())"
                write-verbose "-- RD Session Host servers:  $($result.SessionHosts.ToLower() -join '; ')"
            }
        }
    }
    else
    {
        write-verbose "RD Session collection '$CollectionName' not found."
    }

    return $result
}


######################################################################## 
# The Set-TargetResource cmdlet.
########################################################################
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (    
        [string] $ConnectionBroker,
        
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $CollectionName
    )

    write-verbose "adding local server to RDS deployment"
    Add-RDServer -Server $localhost -Role RDS-RD-SERVER -ConnectionBroker $ConnectionBroker

    if(Get-RDSessionCollection -CollectionName $CollectionName -ErrorAction SilentlyContinue){
        write-verbose "Simply adding local server to RD Session collection '$CollectionName'"
        Add-RDSessionHost @PSBoundParameters -SessionHost $localhost
    }
    else {
        write-verbose "calling New-RdSessionCollection cmdlet..."
        if(-not (New-RDSessionCollection @PSBoundParameters -SessionHost $localhost -ErrorAction SilentlyContinue)){
           write-verbose "retry adding local server to RD Session collection '$CollectionName'"
           Add-RDSessionHost @PSBoundParameters -SessionHost $localhost
        }
    }
    

    #    Add-RDSessionHost @PSBoundParameters,  that's if the Session host is not in the collection
}


#######################################################################
# The Test-TargetResource cmdlet.
#######################################################################
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [string] $ConnectionBroker,

        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $CollectionName
    )

    write-verbose "Checking for existence of current session host in RD Session collection named '$CollectionName'..."
    
    $collection = Get-TargetResource @PSBoundParameters
    
    $result = $collection -ne $null

    write-verbose "Test-TargetResource returning:  $result"
    return $result
}


Export-ModuleMember -Function *-TargetResource