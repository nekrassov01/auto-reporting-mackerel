# 出力用フォルダを作る
$ReportDir = (New-Item -Path "${PSScriptRoot}\report" -ItemType Directory -Force).FullName
$LogDir = (New-Item -Path "${PSScriptRoot}\log" -ItemType Directory -Force).FullName

# Start-Processに渡すパラメータをバンドルする
$Params = @{

    # 実行ファイルのパス
    FilePath = "C:\Program Files\Python38\Scripts\jupyter-nbconvert.exe"
    
    # 実行ファイルに渡す引数
    ArgumentList = "--execute ${PSScriptRoot}\mackerel-auto-reporting.ipynb --output ${ReportDir}\Mackerel_月次レポート_$((Get-Date).AddMonths(-1).ToString("yyyyMM")).html --to html --no-input --no-prompt --allow-errors -y --template basic --ExecutePreprocessor.kernel_name=python"
    
    # 実行ディレクトリ
    WorkingDirectory = ${PSScriptRoot}

    # 標準出力のリダイレクト先
    RedirectStandardOutput = "${LogDir}\stdout_$((Get-Date).ToString("yyyyMMddHHmmss")).log"

    # エラー出力のリダイレクト先
    RedirectStandardError = "${LogDir}\stderr_$((Get-Date).ToString("yyyyMMddHHmmss")).log"

    # プロンプトを表示しない
    NoNewWindow = $True

    # プロセスが完了するまで入力を受け取らない
    Wait = $True

    # 戻り値を有効にする
    PassThru = $True
}

# コマンドを実行する
Start-Process @Params

# 変数をクリアする
Get-Variable | Remove-Variable -ErrorAction SilentlyContinue