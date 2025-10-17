Set-ExecutionPolicy Bypass -Scope Process -Force
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function New-RndVar {
    'v' + ([System.Guid]::NewGuid().ToString('N').Substring(0,8))
}

function Obfuscate-PS1 {
    param([string]$InputPath)

    if (-not (Test-Path $InputPath)) { throw "Input file not found." }

    $content = Get-Content -Raw -Encoding UTF8 $InputPath
    $b64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($content))

    # split into chunks (random chunk lengths around 80-140 to vary signature)
    $chunks = @()
    $i = 0
    while ($i -lt $b64.Length) {
        $len = (Get-Random -Minimum 80 -Maximum 140)
        if ($i + $len -gt $b64.Length) { $len = $b64.Length - $i }
        $chunks += $b64.Substring($i, $len)
        $i += $len
    }

    $varName = New-RndVar
    $joinVar = New-RndVar
    $outName = [IO.Path]::GetFileNameWithoutExtension($InputPath) + "_obf.ps1"
    $outPath = Join-Path $env:TEMP $outName

    $sb = New-Object System.Text.StringBuilder
    # write array with randomized variable name
    $sb.AppendLine("`$" + $varName + " = @(") | Out-Null
    foreach ($c in $chunks) {
        $escaped = $c -replace "'", "''"
        $sb.AppendLine("    '" + $escaped + "'") | Out-Null
    }
    $sb.AppendLine(")") | Out-Null
    $sb.AppendLine("`$" + $joinVar + " = (`$" + $varName + " -join '')") | Out-Null
    $sb.AppendLine("[System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(`$" + $joinVar + ")) | Out-String | Invoke-Expression") | Out-Null

    $sb.ToString() | Out-File -FilePath $outPath -Encoding UTF8
    return $outPath
}

# ============================
# GUI SETUP
# ============================
$form = New-Object System.Windows.Forms.Form
$form.Text = "PS1 → EXE Converter"
$form.Size = New-Object System.Drawing.Size(600, 430)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false

$fontTitle = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$fontNormal = New-Object System.Drawing.Font("Segoe UI", 10)

$title = New-Object System.Windows.Forms.Label
$title.Text = "PS1 → EXE Converter by drox-Ph-Ceb"
$title.ForeColor = "LimeGreen"
$title.Font = $fontTitle
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(110, 15)
$form.Controls.Add($title)

$note = New-Object System.Windows.Forms.Label
$note.Text = "For Donation: Gcash 09451035299"
$note.AutoSize = $true
$note.Font = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Italic)
$note.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FFFF00")
$note.Location = New-Object System.Drawing.Point(386,365)
$form.Controls.Add($note)

# PS1 input
$lblPS1 = New-Object System.Windows.Forms.Label
$lblPS1.Text = "PowerShell Script (.ps1):"
$lblPS1.ForeColor = "White"
$lblPS1.Font = $fontNormal
$lblPS1.AutoSize = $true
$lblPS1.Location = New-Object System.Drawing.Point(30, 60)
$form.Controls.Add($lblPS1)

$txtPS1 = New-Object System.Windows.Forms.TextBox
$txtPS1.Size = New-Object System.Drawing.Size(400, 25)
$txtPS1.Location = New-Object System.Drawing.Point(30, 85)
$form.Controls.Add($txtPS1)

$btnBrowsePS1 = New-Object System.Windows.Forms.Button
$btnBrowsePS1.Text = "Browse"
$btnBrowsePS1.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$btnBrowsePS1.ForeColor = "White"
$btnBrowsePS1.FlatStyle = 'Flat'
$btnBrowsePS1.Size = New-Object System.Drawing.Size(80, 25)
$btnBrowsePS1.Location = New-Object System.Drawing.Point(440, 85)
$btnBrowsePS1.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "PowerShell Scripts (*.ps1)|*.ps1"
    if ($ofd.ShowDialog() -eq 'OK') {
        $txtPS1.Text = $ofd.FileName
        $txtOut.Text = [System.IO.Path]::ChangeExtension($ofd.FileName, ".exe")
    }
})
$form.Controls.Add($btnBrowsePS1)

# Icon
$lblIcon = New-Object System.Windows.Forms.Label
$lblIcon.Text = "Icon (.ico) [Optional]:"
$lblIcon.ForeColor = "White"
$lblIcon.Font = $fontNormal
$lblIcon.AutoSize = $true
$lblIcon.Location = New-Object System.Drawing.Point(30, 125)
$form.Controls.Add($lblIcon)

$txtIcon = New-Object System.Windows.Forms.TextBox
$txtIcon.Size = New-Object System.Drawing.Size(400, 25)
$txtIcon.Location = New-Object System.Drawing.Point(30, 150)
$form.Controls.Add($txtIcon)

$btnBrowseIcon = New-Object System.Windows.Forms.Button
$btnBrowseIcon.Text = "Browse"
$btnBrowseIcon.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$btnBrowseIcon.ForeColor = "White"
$btnBrowseIcon.FlatStyle = 'Flat'
$btnBrowseIcon.Size = New-Object System.Drawing.Size(80, 25)
$btnBrowseIcon.Location = New-Object System.Drawing.Point(440, 150)
$btnBrowseIcon.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "Icon Files (*.ico)|*.ico|All Files (*.*)|*.*"
    if ($ofd.ShowDialog() -eq 'OK') { $txtIcon.Text = $ofd.FileName }
})
$form.Controls.Add($btnBrowseIcon)

# Output name
$lblOut = New-Object System.Windows.Forms.Label
$lblOut.Text = "Output EXE Name (editable):"
$lblOut.ForeColor = "White"
$lblOut.Font = $fontNormal
$lblOut.AutoSize = $true
$lblOut.Location = New-Object System.Drawing.Point(30, 190)
$form.Controls.Add($lblOut)

$txtOut = New-Object System.Windows.Forms.TextBox
$txtOut.Size = New-Object System.Drawing.Size(400, 25)
$txtOut.Location = New-Object System.Drawing.Point(30, 215)
$form.Controls.Add($txtOut)

# Obfuscate checkbox
$chkObf = New-Object System.Windows.Forms.CheckBox
$chkObf.Text = "Obfuscate script before convert (recommended)"
$chkObf.ForeColor = "White"
$chkObf.Font = $fontNormal
$chkObf.AutoSize = $true
$chkObf.Location = New-Object System.Drawing.Point(30, 245)
$chkObf.Checked = $true
$form.Controls.Add($chkObf)

# Progress bar & status
$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Size = New-Object System.Drawing.Size(520, 20)
$progress.Location = New-Object System.Drawing.Point(30, 270)
$progress.Minimum = 0
$progress.Maximum = 100
$progress.Value = 0
$form.Controls.Add($progress)

$status = New-Object System.Windows.Forms.Label
$status.Text = ""
$status.ForeColor = "Gold"
$status.Font = $fontNormal
$status.AutoSize = $true
$status.Location = New-Object System.Drawing.Point(30, 295)
$form.Controls.Add($status)

# Convert button
$btnConvert = New-Object System.Windows.Forms.Button
$btnConvert.Text = "Convert to EXE"
$btnConvert.BackColor = [System.Drawing.Color]::FromArgb(0, 100, 100)
$btnConvert.ForeColor = "White"
$btnConvert.FlatStyle = 'Flat'
$btnConvert.Size = New-Object System.Drawing.Size(520, 40)
$btnConvert.Location = New-Object System.Drawing.Point(30, 320)
$form.Controls.Add($btnConvert)

# ============================
# Conversion logic with obfuscation
# ============================
$btnConvert.Add_Click({
    $ps1 = $txtPS1.Text.Trim()
    $icon = $txtIcon.Text.Trim()
    $out = $txtOut.Text.Trim()
    $tempObf = $null
    if (-not (Test-Path $ps1)) {
        [System.Windows.Forms.MessageBox]::Show("Please select a valid PS1 file.", "Error", 0, 16)
        return
    }

    if (-not $out) { $out = [System.IO.Path]::ChangeExtension($ps1, ".exe") }
    if (-not $out.ToLower().EndsWith(".exe")) { $out = "$out.exe" }

    $status.ForeColor = "Gold"
    $status.Text = "Checking ps2exe module..."
    $form.Refresh()

    if (-not (Get-Module -ListAvailable -Name ps2exe)) {
        try {
            $status.Text = "Installing ps2exe module..."
            $form.Refresh()
            Install-Module -Name ps2exe -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Error installing ps2exe. Please run PowerShell as Administrator.", "Error", 0, 16)
            return
        }
    }

    Import-Module ps2exe -ErrorAction Stop

    # perform obfuscation if requested
    if ($chkObf.Checked) {
        try {
            $status.Text = "Obfuscating script..."
            $form.Refresh()
            $tempObf = Obfuscate-PS1 -InputPath $ps1
            if (Test-Path $tempObf) {
                $ps1 = $tempObf
            } else {
                throw "Obfuscation failed to produce temp file."
            }
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Obfuscation failed.`n$_", "Error", 0, 16)
            return
        }
    }

    # Reset progress
    $progress.Value = 0
    $status.Text = "Converting..."
    $form.Refresh()

    for ($i=1; $i -le 95; $i++) {
        Start-Sleep -Milliseconds 35
        $progress.Value = $i
        $form.Refresh()
    }

    try {
        if ($icon) {
            Invoke-PS2EXE $ps1 $out -noConsole -icon $icon -ErrorAction Stop
        } else {
            Invoke-PS2EXE $ps1 $out -noConsole -ErrorAction Stop
        }

        $progress.Value = 100
        $status.ForeColor = "Cyan"
        $status.Text = "✅ Conversion complete!"
        [System.Windows.Forms.MessageBox]::Show("Conversion complete!`nOutput: $out", "Success", 0, 64)
        Start-Process (Split-Path $out -Parent)
    }
    catch {
        $status.ForeColor = "Red"
        $status.Text = "❌ Conversion failed."
        [System.Windows.Forms.MessageBox]::Show("Failed to convert.`n$_", "Error", 0, 16)
    }
    finally {
        # cleanup temp obfuscated file if we created one
        if ($tempObf -and (Test-Path $tempObf)) {
            try { Remove-Item -LiteralPath $tempObf -Force } catch {}
        }
    }
})

[void]$form.ShowDialog()
