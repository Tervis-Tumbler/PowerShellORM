function New-PowerShellORMModule {
    param (
        $ModuleName,
        $Table
    )
    #New-Item -Path function:New-Test
}

function New-SQLSelect {
    param (
        [Parameter(Mandatory)]$TableName,
        $Parameters = @(),
        $ArbitraryWherePredicate
    )

    $OFSBeforeChange = $OFS
    $OFS = ""

@"
select
*
from
$TableName with (nolock)
where 1 = 1
$(
    $Parameters.GetEnumerator() | New-SQLWherePredicate -TableName $TableName
    $ArbitraryWherePredicate
)
"@
    $OFS = $OFSBeforeChange
}

function New-SQLWherePredicate {
    [Cmdletbinding(DefaultParameterSetName="Name")]
    param (
        [Parameter(Mandatory)]$TableName,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName,ParameterSetName="Name")]$Name,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName,ParameterSetName="Key")]$Key,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]$Value
    )
    process {
        if ($Key) {$Name = $Key}
        
        if ($Value.count -gt 1) {
            $ValuesQuoted = $Value | ForEach-Object { 
                "'$_'"
            }
            $ValuesAsSQLArrayLiteral = "($($ValuesQuoted -join ","))"

            "AND $TableName.$Name in $ValuesAsSQLArrayLiteral`r`n"
        } else {
            "AND $TableName.$Name = '$Value'`r`n"
        }
    }
}
