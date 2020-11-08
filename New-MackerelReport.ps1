# 出力用フォルダを作る
New-Item -Path "${PSScriptRoot}\report" -ItemType Directory -Force >$null
New-Item -Path "${PSScriptRoot}\log" -ItemType Directory -Force >$null

# Start-Processに渡すパラメータをバンドルする
$Params = @{

    # 実行ファイルのパス
    FilePath = "C:\Program Files\Python38\Scripts\jupyter-nbconvert.exe"
    
    # 実行ファイルに渡す引数
    ArgumentList = "--execute ${PSScriptRoot}\mackerel-auto-reporting.ipynb --output ${PSScriptRoot}\report\Mackerel_月次レポート_$((Get-Date).AddMonths(-1).ToString("yyyyMM")).html --to html --no-input --no-prompt --allow-errors -y --template basic --ExecutePreprocessor.kernel_name=python"
    
    # 実行ディレクトリ
    WorkingDirectory = ${PSScriptRoot}

    # 標準出力のリダイレクト先
    RedirectStandardOutput = "${PSScriptRoot}\log\stdout_$((Get-Date).ToString("yyyyMMddHHmmss")).log"

    # エラー出力のリダイレクト先
    RedirectStandardError = "${PSScriptRoot}\log\stderr_$((Get-Date).ToString("yyyyMMddHHmmss")).log"
}

# コマンドを実行する
Start-Process @Params -Wait -PassThru

# 変数をクリアする
Get-Variable | Remove-Variable -ErrorAction SilentlyContinue