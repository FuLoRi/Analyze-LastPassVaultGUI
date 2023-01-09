# Analyze-LastPassVaultGUI PowerShell script
# Version 0.9
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
$form.Size = New-Object System.Drawing.Size(620, 560)
$form.StartPosition = "CenterScreen"
$form.Text = "Analyze LastPass Vault"

# Create the "Instructions" group
$instructionsGroup = New-Object System.Windows.Forms.GroupBox
$instructionsGroup.Size = New-Object System.Drawing.Size(580, 290)
$instructionsGroup.Location = New-Object System.Drawing.Point(10, 10)
$instructionsGroup.Text = "Instructions for use"

$instructionsText = @'
1. Press the "Copy Query" button below to copy a short 3-line JavaScript query to your clipboard.

2. Open Chrome or Edge. Login to LastPass so that you're looking at your vault.

3. Press F12 to open the developer tools. Select the "Console" tab to move to that view. You'll have a cursor.

4. Paste the JavaScript query into the console and press "Enter". Your page will fill with a large XML dump.

5. Look carefully at the bottom of the page for the "Show More" and "Copy" options.

6. Click "Copy" to copy all of that query response data onto the clipboard.

7. Return here and press the "Paste" button to paste the vault XML into the text field.

8. Specify your desired location, name, and format for the output file and click "Analyze".

9. Open the output file to see the decoded URLs and a brief analysis of each encrypted field.
Note: "OK" means it's encrypted with CBC, "Blank" means the field is empty, and a warning means it's encrypted with ECB.
'@

# Create the instructions label
$instructionsLabel = New-Object System.Windows.Forms.Label
$instructionsLabel.Location = New-Object System.Drawing.Point(10, 20)
$instructionsLabel.Size = New-Object System.Drawing.Size(560, 240)
$instructionsLabel.Text = $instructionsText

# Create the "Copy Query" button
$copyQueryButton = New-Object System.Windows.Forms.Button
$copyQueryButton.Size = New-Object System.Drawing.Size(75, 23)
$copyQueryButton.Location = New-Object System.Drawing.Point(250, 260)
$copyQueryButton.Text = "Copy Query"

# Add an action when the "Copy Query" button is clicked
$copyQueryButton.Add_Click({
	# Create a literal multiline string containing the JavaScript query
	$jsQuery=@'
fetch("https://lastpass.com/getaccts.php", {method: "POST"})
  .then(response => response.text())
  .then(text => console.log(text.replace(/>/g, ">\n")));
'@
	
    # Copy the text to the clipboard
    [System.Windows.Forms.Clipboard]::SetText($jsQuery)

    # Display a green check mark to the right of the "Copy Query" button
    $checkMarkLabel = New-Object System.Windows.Forms.Label
    $checkMarkLabel.Size = New-Object System.Drawing.Size(20, 20)
    $checkMarkLabel.Location = New-Object System.Drawing.Point(335, 220)
<#     
    $checkMarkLabel.Text = "✔"
    $checkMarkLabel.ForeColor = 'Green'
    $form.Controls.Add($checkMarkLabel)
    
    # Wait for 5 seconds
    Start-Sleep -Seconds 5
    
    # Remove the green check mark from the form
    $form.Controls.Remove($checkMarkLabel)
 #>	
})

# Add the instructions label to the instructions group
$instructionsGroup.Controls.Add($instructionsLabel)

# Add the "Copy Query" button to the "Instructions" group
$instructionsGroup.Controls.Add($copyQueryButton)

# Add the instructions group to the form
$form.Controls.Add($instructionsGroup)

# Create the left pane
$leftPane = New-Object System.Windows.Forms.GroupBox
$leftPane.Size = New-Object System.Drawing.Size(280, 200)
$leftPane.Location = New-Object System.Drawing.Point(10, 310)
$leftPane.Text = "Provide LastPass vault XML"

# Create the radio buttons for the left pane
$browseXMLRadio = New-Object System.Windows.Forms.RadioButton
$browseXMLRadio.Size = New-Object System.Drawing.Size(75, 17)
$browseXMLRadio.Location = New-Object System.Drawing.Point(10, 20)
$browseXMLRadio.Text = "Browse"
$browseXMLRadio.Checked = $true
$browseXMLRadio.Add_CheckedChanged({
$xmlBrowseField.Enabled = $true
$browseXMLButton.Enabled = $true
$xmlPasteField.Enabled = $false
$pasteXMLButton.Enabled = $false
})

$pasteXMLRadio = New-Object System.Windows.Forms.RadioButton
$pasteXMLRadio.Size = New-Object System.Drawing.Size(75, 17)
$pasteXMLRadio.Location = New-Object System.Drawing.Point(10, 70)
$pasteXMLRadio.Text = "Paste"
$pasteXMLRadio.Add_CheckedChanged({
$xmlBrowseField.Enabled = $false
$browseXMLButton.Enabled = $false
$xmlPasteField.Enabled = $true
$pasteXMLButton.Enabled = $true
})

# Create the "Browse" button for the left pane
$browseXMLButton = New-Object System.Windows.Forms.Button
$browseXMLButton.Size = New-Object System.Drawing.Size(75, 23)
$browseXMLButton.Location = New-Object System.Drawing.Point(195, 40)
$browseXMLButton.Text = "Browse"

# Create the "Browse" text field for the left pane
$xmlBrowseField = New-Object System.Windows.Forms.TextBox
$xmlBrowseField.Size = New-Object System.Drawing.Size(165, 20)
$xmlBrowseField.Location = New-Object System.Drawing.Point(10, 40)

# Create the "Paste" button for the left pane
$pasteXMLButton = New-Object System.Windows.Forms.Button
$pasteXMLButton.Size = New-Object System.Drawing.Size(75, 23)
$pasteXMLButton.Location = New-Object System.Drawing.Point(10, 90)
$pasteXMLButton.Text = "Paste"
$pasteXMLButton.Enabled = $false

# Create the "Paste" text field for the left pane
$xmlPasteField = New-Object System.Windows.Forms.TextBox
$xmlPasteField.Size = New-Object System.Drawing.Size(260, 60)
$xmlPasteField.Location = New-Object System.Drawing.Point(10, 120)
$xmlPasteField.Multiline = $true
$xmlPasteField.ScrollBars = "Vertical"
$xmlPasteField.Enabled = $false

# Add the controls to the left pane
$leftPane.Controls.Add($browseXMLRadio)
$leftPane.Controls.Add($pasteXMLRadio)
$leftPane.Controls.Add($xmlBrowseField)
$leftPane.Controls.Add($browseXMLButton)
$leftPane.Controls.Add($xmlPasteField)
$leftPane.Controls.Add($pasteXMLButton)

# Create the right pane
$rightPane = New-Object System.Windows.Forms.GroupBox
$rightPane.Size = New-Object System.Drawing.Size(280, 160)
$rightPane.Location = New-Object System.Drawing.Point(310, 310)
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

# Create the drop-down menu for the right pane
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

# Create the author label
$authorLabel = New-Object System.Windows.Forms.Label
$authorLabel.Size = New-Object System.Drawing.Size(130, 20)
$authorLabel.Location = New-Object System.Drawing.Point(310, 480)
$authorLabel.Text = "Written by Rob Woodruff"

# Add the author label to the form
$form.Controls.Add($authorLabel)

# Create the "Check for updates" button
$checkForUpdatesButton = New-Object System.Windows.Forms.Button
$checkForUpdatesButton.Size = New-Object System.Drawing.Size(130, 23)
$checkForUpdatesButton.Location = New-Object System.Drawing.Point(460, 480)
$checkForUpdatesButton.Text = "Check for updates"

# Open the URL in the default web browser when the button is clicked
$checkForUpdatesButton.Add_Click({
Start-Process "https://github.com/FuLoRi/Analyze-LastPassVaultGUI/"
})

# Add the "Check for updates" button to the form
$form.Controls.Add($checkForUpdatesButton)

# Set up the browse button to open a file selection dialog
$browseXMLButton.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = "XML files (*.xml)|*.xml"
    if ($openFileDialog.ShowDialog() -eq "OK") {
		# Insert the selected file's path into the existing text field
		$xmlBrowseField.Text = $openFileDialog.FileName

		# Clear the contents of the "Paste" text field
		$xmlPasteField.Text = ""
    }
})

# Add an event handler for the "Paste" button's "Click" event
$pasteXMLButton.Add_Click({
    # Read the contents of the clipboard and insert it into the "Paste" text field
    $xmlPasteField.Text = [System.Windows.Forms.Clipboard]::GetText()

	# Convert the XML content to an XML object
	[xml]$xml = $xmlPasteField.Text
	
})

# Set up the browse button to open a folder selection dialog
$browseOutputButton.Add_Click({
    $folderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($folderBrowserDialog.ShowDialog() -eq "OK") {
        $fileLocationTextField.Text = $folderBrowserDialog.SelectedPath
    }
})

# Set up the "Analyze" button to run
$analyzeButton.Add_Click({
	# Check if the "Browse" radio button is checked
	if ($browseXMLRadio.Checked) {
		# Use the contents of the "Browse" text field as the input file
		$InFile = $xmlBrowseField.Text
	}
	else {
		# Set $InFile to a dummy value since it won't be used
		$InFile = "<xml>"
	}

    # Check which input method is being used
    if ($pasteXMLRadio.Checked) {
        # Validate the pasted XML data
        if (-not $xmlPasteField.Text) {
            # Display an error message if the pasted data is empty
            [System.Windows.Forms.MessageBox]::Show("Please enter or paste XML data into the text field.")
			return
        }
        else {
            # Set the XML data variable to the pasted data
            [xml]$xml = $xmlPasteField.Text

            # Proceed with the rest of the script here...
        }
    }
    else {
        # Validate the input file path
        if (-not $xmlBrowseField.Text) {
            # Display an error message if the file path is empty
            [System.Windows.Forms.MessageBox]::Show("Please enter a valid file path.")
			return
        }
        else {
            # Check if the input file exists
            if (-not (Test-Path -Path $xmlBrowseField.Text)) {
                # Display an error message if the file does not exist
                [System.Windows.Forms.MessageBox]::Show("The specified file does not exist.")
				return
            }
            else {
                # Set the XML data variable to the contents of the input file
                [xml]$xml = Get-Content -Path $InFile

                # Proceed with the rest of the script here...
            }
        }
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
    $OutFile = Join-Path -Path $fileLocationTextField.Text -ChildPath $fileNameTextField.Text
    $Format = $formatMenu.SelectedItem

     # Load the XML into a variable
	if ($browseXMLRadio.Checked) {
		[xml]$xml = Get-Content -Path $InFile
	} else {
		[xml]$xml = $xmlPasteField.Text
	}

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
    [System.Windows.Forms.MessageBox]::Show("Analysis complete.", "Success", "OK", "Information")
})

# Display the GUI form
$form.ShowDialog()
