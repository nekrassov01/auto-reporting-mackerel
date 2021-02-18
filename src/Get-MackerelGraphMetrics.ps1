# Create directories
$dataDir  = (New-Item -Path "${PSScriptRoot}\data" -ItemType Directory -Force).FullName
$logDir   = (New-Item -Path "${PSScriptRoot}\log" -ItemType Directory -Force).FullName
$monthDir = (New-Item -Path "${dataDir}\$((Get-Date).AddMonths(-1).ToString("yyyyMM"))" -ItemType Directory -Force).FullName

# Start log trace
Start-Transcript -Path "${logDir}\apiget_$((Get-Date).ToString("yyyyMMddHHmmss")).log" -Force | Out-Null

# Remove previous files
Get-ChildItem -LiteralPath $dataDir, $logDir -File -Recurse | Where-Object { $_.CreationTime -le (Get-Date).AddDays(-365) } | Remove-Item -Force

# Convert date time to unix time
$baseTime = Get-Date -Date '1970/1/1 0:0:0 GMT'
$from     = [int]([datetime]((Get-Date).AddMonths(-1).ToString('yyyy/MM') + '/01 0:0:0') - $baseTime).TotalSeconds
$to       = [int]([datetime]((Get-Date).ToString('yyyy/MM') + '/01 0:0:0') - $baseTime).TotalSeconds

# Convert parameter-stored json to PSCustomObject for each host
$params = [PSCustomObject](Get-Content -Path "${PSScriptRoot}\params.json" | ConvertFrom-Json).Hosts

# Main process
$params | ForEach-Object -Process {

    $headers  = @{ 'X-Api-Key' = $_.ApiKey }
    $hostId   = $_.HostId
    $hostName = $_.HostName

    # Processing for each metrics
    $_.Metrics | ForEach-Object -Process {

        # Generate a URI to retrieve metrics
        $uri = "https://api.mackerelio.com/api/v0/hosts/${hostId}/metrics?name=${_}&from=${from}&to=${to}"
        
        # Call API
        $response = Invoke-WebRequest -Uri $uri -Method Get -Headers $headers -UseBasicParsing
        
        # Define the output file path 
        # Hostname and metrics name need to be concatenated with dots for post-processing
        $outputPath = "${monthDir}\${hostName}.${_}.csv"

        # Encode json and then convert it to PSCustomObject to get the metrics properties
        $result = ([System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding('ISO-8859-1').GetBytes($response.Content)) | ConvertFrom-Json).metrics

        # Export metrics to file
        $result | Export-Csv -Path $outputPath -Encoding Default -Force -NoTypeInformation
        
        # Record the completion of getting metrics in the log
        Write-Output ('[{0}] Done: {1} - {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $hostName, $_)
    }
}

# Stop log trace
Stop-Transcript | Out-Null
