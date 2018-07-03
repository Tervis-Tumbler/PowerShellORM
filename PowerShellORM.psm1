

function New-SQLSelect {
    param (
        [Parameter(Mandatory)]$TableName,
        [Parameter(Mandatory)]$Parameters,
        $ArbitraryWherePredicate
    )

    $OFSBeforeChange = $OFS
    $OFS = ""

@"
select
*
from
$TableName
where 1 = 1
$(
    $Parameters | New-SQLWhereCondition -TableName $TableName
    $ArbitraryWherePredicate
)
"@
    $OFS = $OFSBeforeChange
}

function New-SQLWhereCondition {
    [Cmdletbinding(DefaultParameterSetName="Name")]
    param (
        [Parameter(Mandatory)]$TableName,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName,ParameterSetName="Name")]$Name,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName,ParameterSetName="Key")]$Key,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]$Value
    )
    process {
        if ($Key) {$Name = $Key}
        "AND $TableName.$Name = '$Value'`r`n"
    }
}
