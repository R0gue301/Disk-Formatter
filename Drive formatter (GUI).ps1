Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Функция определения темы Windows (0 - темная, 1 - светлая)
function Get-WindowsTheme {
    try {
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        $appsUseLightTheme = Get-ItemProperty -Path $regPath -Name "AppsUseLightTheme" -ErrorAction Stop
        if ($appsUseLightTheme.AppsUseLightTheme -eq 0) { return "Dark" }
    } catch {}
    return "Light"
}

$theme = Get-WindowsTheme

# Настройка цветовой палитры в зависимости от темы
if ($theme -eq "Dark") {
    $bgColor     = [System.Drawing.Color]::FromArgb(32, 32, 32)
    $fgColor     = [System.Drawing.Color]::White
    $inputBg     = [System.Drawing.Color]::FromArgb(45, 45, 48)
    $btnBg       = [System.Drawing.Color]::FromArgb(28, 110, 175)
    $btnFg       = [System.Drawing.Color]::White
    $statusColor = [System.Drawing.Color]::LightGray
} else {
    $bgColor     = [System.Drawing.Color]::FromArgb(243, 243, 243)
    $fgColor     = [System.Drawing.Color]::Black
    $inputBg     = [System.Drawing.Color]::White
    $btnBg       = [System.Drawing.Color]::LightCoral
    $btnFg       = [System.Drawing.Color]::Black
    $statusColor = [System.Drawing.Color]::Gray
}

# Кастомная функция для красивых динамических диалогов (замена MessageBox)
function Show-CustomDialog {
    param (
        [string]$Message,
        [string]$Title,
        [bool]$ShowYesNo = $false
    )
    
    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = $Title
    $dialog.Size = New-Object System.Drawing.Size(400, 220)
    $dialog.StartPosition = "CenterParent"
    $dialog.FormBorderStyle = "FixedDialog"
    $dialog.MaximizeBox = $false
    $dialog.MinimizeBox = $false
    $dialog.BackColor = $bgColor
    $dialog.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $Message
    $lbl.Location = New-Object System.Drawing.Point(20, 20)
    $lbl.Size = New-Object System.Drawing.Size(345, 90)
    $lbl.ForeColor = $fgColor
    $dialog.Controls.Add($lbl)
    
    $result = [System.Windows.Forms.DialogResult]::OK
    
    if ($ShowYesNo) {
        $btnYes = New-Object System.Windows.Forms.Button
        $btnYes.Text = "Yes"
        $btnYes.Location = New-Object System.Drawing.Point(80, 120)
        $btnYes.Size = New-Object System.Drawing.Size(100, 35)
        $btnYes.BackColor = $btnBg
        $btnYes.ForeColor = $btnFg
        $btnYes.FlatStyle = "Flat"
        $btnYes.FlatAppearance.BorderSize = 0
        $btnYes.Add_Click({ $global:DialogResult = [System.Windows.Forms.DialogResult]::Yes; $dialog.Close() })
        $dialog.Controls.Add($btnYes)
        
        $btnNo = New-Object System.Windows.Forms.Button
        $btnNo.Text = "No"
        $btnNo.Location = New-Object System.Drawing.Point(200, 120)
        $btnNo.Size = New-Object System.Drawing.Size(100, 35)
        $btnNo.BackColor = $inputBg
        $btnNo.ForeColor = $fgColor
        $btnNo.FlatStyle = "Flat"
        $btnNo.FlatAppearance.BorderColor = $btnBg
        $btnNo.Add_Click({ $global:DialogResult = [System.Windows.Forms.DialogResult]::No; $dialog.Close() })
        $dialog.Controls.Add($btnNo)
        
        $global:DialogResult = [System.Windows.Forms.DialogResult]::No
    } else {
        $btnOk = New-Object System.Windows.Forms.Button
        $btnOk.Text = "OK"
        $btnOk.Location = New-Object System.Drawing.Point(140, 120)
        $btnOk.Size = New-Object System.Drawing.Size(100, 35)
        $btnOk.BackColor = $btnBg
        $btnOk.ForeColor = $btnFg
        $btnOk.FlatStyle = "Flat"
        $btnOk.FlatAppearance.BorderSize = 0
        $btnOk.Add_Click({ $global:DialogResult = [System.Windows.Forms.DialogResult]::OK; $dialog.Close() })
        $dialog.Controls.Add($btnOk)
        
        $global:DialogResult = [System.Windows.Forms.DialogResult]::OK
    }
    
    [void]$dialog.ShowDialog($form)
    return $global:DialogResult
}

# 1. Получение списка дисков
$availableDrives = Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -ne 'CD-ROM' -and $_.DriveLetter -ne 'C' } | Sort-Object DriveLetter

if (-not $availableDrives) {
    # Специфичный вызов до инициализации главного окна используем стандартный
    [System.Windows.Forms.MessageBox]::Show("No available drives found!", "Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    exit
}

$driveItems = $availableDrives | ForEach-Object {
    $fs = if ($_.FileSystem) { $_.FileSystem } else { '?' }
    $free = '{0,4}' -f ($_.SizeRemaining / 1GB -as [int])
    $label = if ($_.FileSystemLabel) { $_.FileSystemLabel } else { '-' }
    
    [PSCustomObject]@{
        Letter      = $_.DriveLetter
        DisplayString = "[$($_.DriveLetter):] $label ($fs) - Free: $free GB"
    }
}

# 2. Создание окна
$form = New-Object System.Windows.Forms.Form
$form.Text = "Drive Formatter (GUI)"
$form.Size = New-Object System.Drawing.Size(450, 480)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.BackColor = $bgColor

$font = New-Object System.Drawing.Font("Segoe UI", 10)
$form.Font = $font

# Список дисков
$lblDrives = New-Object System.Windows.Forms.Label
$lblDrives.Text = "Select drives to format:"
$lblDrives.Location = New-Object System.Drawing.Point(20, 15)
$lblDrives.Size = New-Object System.Drawing.Size(400, 20)
$lblDrives.ForeColor = $fgColor
$form.Controls.Add($lblDrives)

$chkListBox = New-Object System.Windows.Forms.CheckedListBox
$chkListBox.Location = New-Object System.Drawing.Point(20, 40)
$chkListBox.Size = New-Object System.Drawing.Size(390, 180)
$chkListBox.CheckOnClick = $true
$chkListBox.BackColor = $inputBg
$chkListBox.ForeColor = $fgColor
$chkListBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
foreach ($drive in $driveItems) {
    [void]$chkListBox.Items.Add($drive, $false)
}
$chkListBox.DisplayMember = "DisplayString"
$form.Controls.Add($chkListBox)

# Выбор файловой системы
$lblFs = New-Object System.Windows.Forms.Label
$lblFs.Text = "Select filesystem:"
$lblFs.Location = New-Object System.Drawing.Point(20, 240)
$lblFs.Size = New-Object System.Drawing.Size(400, 20)
$lblFs.ForeColor = $fgColor
$form.Controls.Add($lblFs)

$cmbFs = New-Object System.Windows.Forms.ComboBox
$cmbFs.Location = New-Object System.Drawing.Point(20, 265)
$cmbFs.Size = New-Object System.Drawing.Size(390, 25)
$cmbFs.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$cmbFs.BackColor = $inputBg
$cmbFs.ForeColor = $fgColor
$fsOptions = @('NTFS', 'FAT32', 'exFAT', 'ReFS')
foreach ($fs in $fsOptions) {
    [void]$cmbFs.Items.Add($fs)
}
$cmbFs.SelectedIndex = 0
$form.Controls.Add($cmbFs)

# Кнопка Форматировать
$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Text = "Format"
$btnStart.Location = New-Object System.Drawing.Point(20, 320)
$btnStart.Size = New-Object System.Drawing.Size(185, 45)
$btnStart.BackColor = $btnBg
$btnStart.ForeColor = $btnFg
$btnStart.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnStart.FlatAppearance.BorderSize = 0
$btnStart.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($btnStart)

# Кнопка Отмена
$btnCancel = New-Object System.Windows.Forms.Button
$btnCancel.Text = "Cancel"
$btnCancel.Location = New-Object System.Drawing.Point(225, 320)
$btnCancel.Size = New-Object System.Drawing.Size(185, 45)
$btnCancel.BackColor = $inputBg
$btnCancel.ForeColor = $fgColor
$btnCancel.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnCancel.FlatAppearance.BorderSize = 1
$btnCancel.FlatAppearance.BorderColor = $btnBg
$form.Controls.Add($btnCancel)

# Статус-бар
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Waiting for selection..."
$lblStatus.Location = New-Object System.Drawing.Point(20, 390)
$lblStatus.Size = New-Object System.Drawing.Size(390, 40)
$lblStatus.ForeColor = $statusColor
$form.Controls.Add($lblStatus)

$btnCancel.Add_Click({ $form.Close() })

$btnStart.Add_Click({
    $selectedDrives = $chkListBox.CheckedItems
    if ($selectedDrives.Count -eq 0) {
        Show-CustomDialog -Message "Please select at least one drive!" -Title "Warning"
        return
    }

    $selectedFs = $cmbFs.SelectedItem.ToString()
    $letters = ($selectedDrives | ForEach-Object { $_.Letter }) -join ', '

    $confirmMsg = "Selected drives: $letters`nWill be formatted to: $selectedFs`n`nWARNING: All data will be permanently deleted! Continue?"
    $confirmResult = Show-CustomDialog -Message $confirmMsg -Title "Confirmation" -ShowYesNo $true

    if ($confirmResult -ne [System.Windows.Forms.DialogResult]::Yes) {
        $lblStatus.Text = "Operation cancelled."
        $lblStatus.ForeColor = [System.Drawing.Color]::OrangeRed
        return
    }

    $btnStart.Enabled = $false
    $btnCancel.Enabled = $false
    $chkListBox.Enabled = $false
    $cmbFs.Enabled = $false

    # Отключаем показ серого системного прогресс-бара Windows
    $oldProgressPreference = $ProgressPreference
    $global:ProgressPreference = 'SilentlyContinue'

    foreach ($driveObj in $selectedDrives) {
        $drive = $driveObj.Letter
        $lblStatus.Text = "Formatting drive ${drive}: ($selectedFs)..."
        $lblStatus.ForeColor = if ($theme -eq "Dark") { [System.Drawing.Color]::DeepSkyBlue } else { [System.Drawing.Color]::Blue }
        [System.Windows.Forms.Application]::DoEvents()

        $vol = Get-Volume -DriveLetter $drive -ErrorAction SilentlyContinue
        if (-not $vol) {
            $lblStatus.Text = "Error: drive ${drive}: not found."
            $lblStatus.ForeColor = [System.Drawing.Color]::Red
            continue
        }

        $currentLabel = $vol.FileSystemLabel
        if (-not $currentLabel) { $currentLabel = "" }

        try {
            Format-Volume -DriveLetter $drive -FileSystem $selectedFs -Confirm:$false -NewFileSystemLabel $currentLabel -ErrorAction Stop
            $lblStatus.Text = "Drive ${drive}: successfully formatted!"
            $lblStatus.ForeColor = [System.Drawing.Color]::Green
        }
        catch {
            $lblStatus.Text = "Cmdlet failed. Trying format.com..."
            $lblStatus.ForeColor = [System.Drawing.Color]::DarkGoldenrod
            [System.Windows.Forms.Application]::DoEvents()

            $result = cmd /c "echo Y|format ${drive}: /FS:$selectedFs /V:$currentLabel /Q /Y" 2>&1
            if ($LASTEXITCODE -eq 0) {
                $lblStatus.Text = "Drive ${drive}: successfully formatted!"
                $lblStatus.ForeColor = [System.Drawing.Color]::Green
            } else {
                $lblStatus.Text = "Error on drive ${drive}:!"
                $lblStatus.ForeColor = [System.Drawing.Color]::Red
                Show-CustomDialog -Message "Failed to format drive ${drive}:`n$result" -Title "Error"
            }
        }
        [System.Windows.Forms.Application]::DoEvents()
    }

    # Возвращаем настройки прогресса обратно
    $global:ProgressPreference = $oldProgressPreference

    $lblStatus.Text = "All operations completed!"
    $lblStatus.ForeColor = if ($theme -eq "Dark") { [System.Drawing.Color]::LightGreen } else { [System.Drawing.Color]::DarkGreen }
    $btnStart.Enabled = $true
    $btnCancel.Enabled = $true
    $chkListBox.Enabled = $true
    $cmbFs.Enabled = $true
})

[System.Windows.Forms.Application]::Run($form)
