function New-PowerShellORMModule {
    param (
        $ModuleName,
        $Table
    )
    #New-Item -Path function:New-Test
}

function Get-PowerShellORMTableNameFullyQualified {
    param (
        [Parameter(Mandatory)]$TableName,
        $SchemaName = "dbo"
    )
    "[$SchemaName].[$TableName]"
}

function New-SQLSelect {
    param (
        [Parameter(Mandatory)]$TableName,
        $SchemaName = "dbo",
        $Parameters = @(),
        $ArbitraryWherePredicate
    )

    $OFSBeforeChange = $OFS
    $OFS = ""

    $FullyQualifiedTableName = Get-PowerShellORMTableNameFullyQualified -TableName $TableName -SchemaName $SchemaName

@"
select
*
from
$FullyQualifiedTableName with (nolock)
where 1 = 1
$(
    $Parameters.GetEnumerator() | New-SQLWherePredicate -FullyQualifiedTableName $FullyQualifiedTableName
    $ArbitraryWherePredicate
)
"@
    $OFS = $OFSBeforeChange
}

function New-SQLWherePredicate {
    [Cmdletbinding(DefaultParameterSetName="Name")]
    param (
        [Parameter(Mandatory)]$FullyQualifiedTableName,
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

            "AND $FullyQualifiedTableName.[$Name] in $ValuesAsSQLArrayLiteral`r`n"
        } else {
            "AND $FullyQualifiedTableName.[$Name] = '$Value'`r`n"
        }
    }
}

function New-SQLUpdate {
    param (
        [Parameter(Mandatory)]$TableName,
        $SchemaName = "dbo",
        $WhereParameters = @(),
        $ArbitraryWherePredicate,
        $ValueParameters
    )

    $OFSBeforeChange = $OFS
    $OFS = ""

    $FullyQualifiedTableName = Get-PowerShellORMTableNameFullyQualified -TableName $TableName -SchemaName $SchemaName

@"
update $FullyQualifiedTableName
set
$(
    $ValueParameters.GetEnumerator() | New-SQLSetValueStatement
)
where 1 = 1
$(
    $WhereParameters.GetEnumerator() | New-SQLWherePredicate -FullyQualifiedTableName $FullyQualifiedTableName
    $ArbitraryWherePredicate
)
"@
    $OFS = $OFSBeforeChange
}

function New-SQLSetValueStatement {
    [Cmdletbinding(DefaultParameterSetName="Name")]
    param (
        [Parameter(Mandatory,ValueFromPipelineByPropertyName,ParameterSetName="Name")]$Name,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName,ParameterSetName="Key")]$Key,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]$Value
    )
    begin {
        $SetStatements = New-Object -TypeName System.Collections.ArrayList
    }
    process {
        if ($Key) {$Name = $Key}
        $ValueInStatement = if ($Value -notmatch "null") {
            "'$Value'"
        } else {
            $Value
        }

        $SetStatements.Add("[$Name] = $ValueInStatement`r`n") | Out-Null
    }
    end {
        $SetStatements -join ","
    }
}