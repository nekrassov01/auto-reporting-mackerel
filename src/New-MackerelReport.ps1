# Create directories
$reportDir = (New-Item -Path "${PSScriptRoot}\report" -ItemType Directory -Force).FullName
$logDir = (New-Item -Path "${PSScriptRoot}\log" -ItemType Directory -Force).FullName

# Bundle parameters to be passed to Start-Process
$params = @{

    # Path of the executable file
    FilePath = "C:\Program Files\Python38\Scripts\jupyter-nbconvert.exe"
    
    # Arguments to be passed to the executable file
    ArgumentList = "--execute ${PSScriptRoot}\auto-reporting.ipynb --output ${reportDir}\mackerel-monthly-report_$((Get-Date).AddMonths(-1).ToString("yyyyMM")).html --to html --no-input --no-prompt --allow-errors -y --template basic --ExecutePreprocessor.kernel_name=python --ExecutePreprocessor.timeout=2678400"
    
    # Executable directory 
    WorkingDirectory = ${PSScriptRoot}

    # Redirect standard output to
    RedirectStandardOutput = "${logDir}\stdout_$((Get-Date).ToString("yyyyMMddHHmmss")).log"

    # Redirect error output to
    RedirectStandardError = "${logDir}\stderr_$((Get-Date).ToString("yyyyMMddHHmmss")).log"

    # Don't show the prompt
    NoNewWindow = $True

    # Don't accept input until the process is complete
    Wait = $True

    # Enable the return value
    PassThru = $True
}

# Execute command
Start-Process @params
