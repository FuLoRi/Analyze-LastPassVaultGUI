# Analyze-LastPassVaultGUI PowerShell script
# Version 0.5
# Written by Rob Woodruff and ChatGPT
# More information and updates can be found at https://github.com/FuLoRi/Analyze-LastPassVaultGUI

# PURPOSE:
# This script prompts the user for the XML contents of their LastPass vault (input file) and the location,
# name, and format (HTML or CSV) of the analysis file (output file). The script then does the following:
#    1) Decodes the hex-encoded URL into human-readable ASCII characters
#    2) Marks fields encrypted with CBC as "OK"
#    3) Marks fields encrypted with ECB with a warning message
#    4) Marks empty fields (only the ones that are normally encrypted) as "Blank" 
#    5) Generates the requested output file
#    6) Displays a status message

# LICENSE:
# This software is licensed under GNU General Public License (GPL) v3.

# DISCLAIMER:
# By downloading, installing, or using this software, you agree to the terms of this software disclaimer.
# This software is provided “as is” and no warranties, either expressed or implied, are made regarding its
# accuracy, reliability, or performance. The user assumes the entire risk associated with the use and
# performance of this software. In no event shall the creators and/or distributors of this software be liable
# for any damages, including, but not limited to, direct, indirect, special, incidental, or consequential
# damages arising out of the use of or inability to use this software, even if the creators and/or
# distributors of this software have been advised of the possibility of such damages.

# Load the System.Windows.Forms assembly
Add-Type -AssemblyName System.Windows.Forms

# Create the GUI form
$form = New-Object System.Windows.Forms.Form
$form.Size = New-Object System.Drawing.Size(620, 220)
$form.StartPosition = "CenterScreen"
$form.Text = "Analyze LastPass Vault"

# Create the left pane
$leftPane = New-Object System.Windows.Forms.GroupBox
$leftPane.Size = New-Object System.Drawing.Size(280, 160)
$leftPane.Location = New-Object System.Drawing.Point(10, 10)
$leftPane.Text = "Select LastPass vault (XML) file"

# Create the "Browse" button for the left pane
$browseXMLButton = New-Object System.Windows.Forms.Button
$browseXMLButton.Size = New-Object System.Drawing.Size(75, 23)
$browseXMLButton.Location = New-Object System.Drawing.Point(195, 30)
$browseXMLButton.Text = "Browse"

# Create the text field for the left pane
$xmlTextField = New-Object System.Windows.Forms.TextBox
$xmlTextField.Size = New-Object System.Drawing.Size(165, 20)
$xmlTextField.Location = New-Object System.Drawing.Point(10, 30)

# Add the controls to the left pane
$leftPane.Controls.Add($xmlTextField)
$leftPane.Controls.Add($browseXMLButton)

# Create the right pane
$rightPane = New-Object System.Windows.Forms.GroupBox
$rightPane.Size = New-Object System.Drawing.Size(280, 160)
$rightPane.Location = New-Object System.Drawing.Point(310, 10)
$rightPane.Text = "Specify output file"

# Create the "File location" field and "Browse" button for the right pane
$fileLocationLabel = New-Object System.Windows.Forms.Label
$fileLocationLabel.Size = New-Object System.Drawing.Size(80, 13)
$fileLocationLabel.Location = New-Object System.Drawing.Point(10, 30)
$fileLocationLabel.Text = "File location:"

$fileLocationTextField = New-Object System.Windows.Forms.TextBox
$fileLocationTextField.Size = New-Object System.Drawing.Size(165, 20)
$fileLocationTextField.Location = New-Object System.Drawing.Point(95, 30)

$browseOutputButton = New-Object System.Windows.Forms.Button
$browseOutputButton.Size = New-Object System.Drawing.Size(75, 23)
$browseOutputButton.Location = New-Object System.Drawing.Point(95, 55)
$browseOutputButton.Text = "Browse"

# Create the "File name" field for the right pane
$fileNameLabel = New-Object System.Windows.Forms.Label
$fileNameLabel.Size = New-Object System.Drawing.Size(80, 13)
$fileNameLabel.Location = New-Object System.Drawing.Point(10, 90)
$fileNameLabel.Text = "File name:"

$fileNameTextField = New-Object System.Windows.Forms.TextBox
$fileNameTextField.Size = New-Object System.Drawing.Size(165, 20)
$fileNameTextField.Location = New-Object System.Drawing.Point(95, 90)

# Create the drop-down menu or radio buttons for the right pane
$formatLabel = New-Object System.Windows.Forms.Label
$formatLabel.Size = New-Object System.Drawing.Size(80, 13)
$formatLabel.Location = New-Object System.Drawing.Point(10, 120)
$formatLabel.Text = "Format:"

$formatMenu = New-Object System.Windows.Forms.ComboBox
$formatMenu.Size = New-Object System.Drawing.Size(60, 21)
$formatMenu.Location = New-Object System.Drawing.Point(95, 120)
$formatMenu.Items.AddRange(@("HTML", "CSV"))
$formatMenu.SelectedIndex = 0

# Create the "Analyze" button for the right pane
$analyzeButton = New-Object System.Windows.Forms.Button
$analyzeButton.Size = New-Object System.Drawing.Size(75, 23)
$analyzeButton.Location = New-Object System.Drawing.Point(185, 120)
$analyzeButton.Text = "Analyze"

# Add the controls to the right pane
$rightPane.Controls.Add($fileLocationLabel)
$rightPane.Controls.Add($fileLocationTextField)
$rightPane.Controls.Add($browseOutputButton)
$rightPane.Controls.Add($fileNameLabel)
$rightPane.Controls.Add($fileNameTextField)
$rightPane.Controls.Add($formatLabel)
$rightPane.Controls.Add($formatMenu)
$rightPane.Controls.Add($analyzeButton)

# Add the panes to the form
$form.Controls.Add($leftPane)
$form.Controls.Add($rightPane)

# Set up the browse buttons to open a file selection dialog
$browseXMLButton.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = "XML files (*.xml)|*.xml"
    if ($openFileDialog.ShowDialog() -eq "OK") {
        $xmlTextField.Text = $openFileDialog.FileName
    }
})

$browseOutputButton.Add_Click({
    $folderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($folderBrowserDialog.ShowDialog() -eq "OK") {
        $fileLocationTextField.Text = $folderBrowserDialog.SelectedPath
    }
})

# Set up the "Analyze" button to run
$analyzeButton.Add_Click({
    # Validate the input
    if (-not (Test-Path -Path $xmlTextField.Text)) {
        [System.Windows.Forms.MessageBox]::Show("The specified XML file does not exist.", "Error", "OK", "Error")
        return
    }
    if (-not (Test-Path -Path $fileLocationTextField.Text)) {
        [System.Windows.Forms.MessageBox]::Show("The specified output folder does not exist.", "Error", "OK", "Error")
        return
    }
    if (-not $fileNameTextField.Text) {
        [System.Windows.Forms.MessageBox]::Show("Please specify a file name for the output file.", "Error", "OK", "Error")
        return
    }

    # Set the script parameters
    $InFile = $xmlTextField.Text
    $OutFile = Join-Path -Path $fileLocationTextField.Text -ChildPath $fileNameTextField.Text
    $Format = $formatMenu.SelectedItem

    # Load the XML file into a variable
    [xml]$xml = Get-Content -Path $InFile

    # Initialize an empty array to store the results
    $results = @()

    # Iterate over the account elements in the XML file
    foreach ($account in $xml.response.accounts.account) {
        # Initialize a new object to store the data for this account
        $result = [pscustomobject]@{
            Name = $account.name
            URL = $account.url
            ID = $account.id
            Group = $account.group
            Extra = $account.extra
            IsBookmark = $account.isbookmark
            NeverAutofill = $account.never_autofill
            LastTouch = $account.last_touch
            LastModified = $account.last_modified
            LaunchCount = $account.launch_count
            UserName = $account.login.u
            Password = $account.login.p
        }

        # Convert the hexadecimal values to text/ASCII
        $hex = $result.URL
        if (-not [System.Text.RegularExpressions.Regex]::IsMatch($hex, '^[0-9a-fA-F]+$')) {
            # String is not a hexadecimal string
            $result.URL = "ERROR: Invalid hexadecimal string."
        } else {
            $result.URL = (-join($hex|sls ".."-a|% m*|%{[char]+"0x$_"}))
        }

        # Use a regular expression to identify values encrypted with ECB
        $pattern = '^!'
        $encryptedValues = @('Name', 'Extra', 'UserName', 'Password', 'Group')

        foreach ($encryptedValue in $encryptedValues) {
            if (!$result.$encryptedValue) {
                # Value is blank
                $result.$encryptedValue = "Blank"
            } elseif ($result.$encryptedValue -match $pattern) {
                # Value is encrypted with CBC
                $result.$encryptedValue = "OK"
            } else {
                # Value is encrypted with ECB
                $result.$encryptedValue = "WARNING: Encrypted with ECB!"
            }
        }

        # Add the result object to the array
        $results += $result
    }

    # Save the output file
    if ($Format -eq "CSV") {
        $results | Export-Csv -Path $OutFile -NoTypeInformation
    } else {
        $html = $results | ConvertTo-Html -Fragment
        $html | Out-File -FilePath $OutFile
    }

    # Show a success message
    [System.Windows.Forms.MessageBox]::Show("Vault analyzed and output file created successfully.", "Success", "OK", "Information")
})

# Display the GUI form
$form.ShowDialog()
