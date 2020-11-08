# 自作関数を読み込む
$FunctionsDir = "..\powershell-functions\scripts"
Get-ChildItem -Path $FunctionsDir | ForEach-Object -Process { .$_.FullName }

# フォルダ構成を作る
$LastMonth = (Get-Date).AddMonths(-1).ToString("yyyyMM")
$DateTime = (Get-Date).ToString("yyyyMMddHHmmss")
$DataDir = (New-Item -Path "${PSScriptRoot}\data" -ItemType Directory -Force).FullName
$MonthDir = (New-Item -Path "${DataDir}\${LastMonth}" -ItemType Directory -Force).FullName
$LogDir = (New-Item -Path "${PSScriptRoot}\log" -ItemType Directory -Force).FullName

# ログトレースを開始する
$LogFile = "${LogDir}\${DateTime}.log"
Start-Transcript -Path $LogFile -Force -IncludeInvocationHeader >$null

# 自作関数 - Remove-PastFiles: 指定ディレクトリ内で指定日数を経過したファイルを削除する
Remove-PastFiles -Path $DataDir, $LogDir -Day 365 -Recurse

# 自作関数 - Get-UnixTimeFromDateTime: 日時の文字列からUNIX時間を取得する
$From = (Get-Date).AddMonths(-1).ToString("yyyy/MM") + "/01 00:00:00" | Get-UnixTimeFromDateTime
$To = (Get-Date).ToString("yyyy/MM") + "/01 00:00:00" | Get-UnixTimeFromDateTime

# パラメータがストアされたJSONをHostごとのPSCustomObjectに変換する
$Params = [PSCustomObject](Get-Content -Path "${PSScriptRoot}\params.json" | ConvertFrom-Json).Hosts

# メイン処理
$Params | ForEach-Object -Process {

    # Host単位のパラメータを変数に格納する
    $Headers  = @{ "X-Api-Key" = $_.ApiKey }
    $HostId   = $_.HostId
    $HostName = $_.HostName

    # Metrics単位の処理
    $_.Metrics | ForEach-Object -Process {

        # MetricsをGETするためのURIを組み立てる
        $Uri = "https://api.mackerelio.com/api/v0/hosts/${HostId}/metrics?name=${_}&from=${From}&to=${To}"
        
        # APIをコールする
        $Response = Invoke-WebRequest -Uri $Uri -Method Get -Headers $Headers -UseBasicParsing
        
        # 出力ファイルパスを定義する（後処理のためにホスト名とメトリクス名をドットで結合する必要がある）
        $OutputPath = "${MonthDir}\${HostName}.${_}.csv"
        
        # 戻り値のJSONを文字化け対策でエンコードしてからContentをPSCustomObjectに変換し、metricsプロパティを取得する
        $Result = ([System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($Response.Content)) | ConvertFrom-Json).metrics

        # metricsをファイルに書き出す
        $Result | Export-Csv -Path $OutputPath -Encoding Default -Force -NoTypeInformation
        
        # 自作関数 - Out-Log: ログにmetricsごとの取得完了を記録する
        Out-Log "Done: ${HostName} - ${_}"
    }
}

# ログトレースを終了する
Stop-Transcript >$null

# 変数をクリアする
Get-Variable | Remove-Variable -ErrorAction SilentlyContinue
