# Analyze-LastPassVaultGUI PowerShell script
# Written by Rob Woodruff with help from ChatGPT and Steve Gibson
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

using namespace System.Windows.Forms;

# Set the version number and date
$scriptVersion = "1.1"
$scriptDate = "2023-01-08"

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
$instructionsGroup.Anchor = [AnchorStyles]::Top -bor [AnchorStyles]::Left -bor [AnchorStyles]::Bottom -bor [AnchorStyles]::Right
$instructionsGroup.Text = "Instructions for use"

$instructionsText = @'
1. Press the "Copy Query" button below to copy a short 3-line JavaScript query to your clipboard.

2. Open Chrome or Edge. Login to LastPass so that you're looking at your vault.

3. Press F12 to open the developer tools. Select the "Console" tab to move to that view. You'll have a cursor.

4. Paste the JavaScript query into the console and press "Enter". Your page will fill with a large XML dump.

5. Look carefully at the bottom of the page for the "Show More" and "Copy" options.

6. Click "Copy" to copy all of that query response data onto the clipboard.

7. Return here and press the "Paste" button to paste the vault XML into the text field. This may take a moment.

8. Specify your desired location, name, and format for the output file and click "Analyze".

9. Open the output file to see the decoded URLs and a brief analysis of each encrypted field.
Note: "OK" means it's encrypted with CBC, "Blank" means the field is empty, and a warning means it's encrypted with ECB.
'@

# Create the instructions label
$instructionsLabel = New-Object System.Windows.Forms.Label
$instructionsLabel.Location = New-Object System.Drawing.Point(10, 20)
$instructionsLabel.Size = New-Object System.Drawing.Size(560, 240)
$instructionsLabel.Anchor = [AnchorStyles]::Top -bor [AnchorStyles]::Left -bor [AnchorStyles]::Bottom -bor [AnchorStyles]::Right
$instructionsLabel.Text = $instructionsText

# Create the "Copy Query" button
$copyQueryButton = New-Object System.Windows.Forms.Button
$copyQueryButton.Size = New-Object System.Drawing.Size(75, 23)
$copyQueryButton.Location = New-Object System.Drawing.Point(250, 260)
$copyQueryButton.Anchor = [AnchorStyles]::Bottom
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

})

# Add the instructions label to the instructions group
$instructionsGroup.Controls.Add($instructionsLabel)

# Add the "Copy Query" button to the "Instructions" group
$instructionsGroup.Controls.Add($copyQueryButton)

# Add the instructions group to the form
$form.Controls.Add($instructionsGroup)

# Create split container for left & right sections
$splitContainer = New-Object System.Windows.Forms.SplitContainer
$splitContainer.Size = New-Object System.Drawing.Size(580, 200)
$splitContainer.Location = New-Object System.Drawing.Point(10, 310)
$splitContainer.Anchor = [AnchorStyles]::Bottom -bor [AnchorStyles]::Left -bor [AnchorStyles]::Right
$splitContainer.IsSplitterFixed = $true
$splitContainer.SplitterDistance = 290
$splitContainer.Orientation = [Orientation]::Vertical

# Create the left pane
$leftPane = New-Object System.Windows.Forms.GroupBox
$leftPane.Size = New-Object System.Drawing.Size(280, 200)
$leftPane.Location = New-Object System.Drawing.Point(10, 310)
$leftPane.Dock = [DockStyle]::Fill
$leftPane.Text = "Provide LastPass vault XML"

# Create the radio buttons for the left pane
$browseXMLRadio = New-Object System.Windows.Forms.RadioButton
$browseXMLRadio.Size = New-Object System.Drawing.Size(75, 17)
$browseXMLRadio.Location = New-Object System.Drawing.Point(10, 20)
$browseXMLRadio.Text = "Browse"
$browseXMLRadio.Checked = $false
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
$pasteXMLRadio.Checked = $true
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
$browseXMLButton.Anchor = [AnchorStyles]::Top -bor [AnchorStyles]::Right
$browseXMLButton.Text = "Browse"
$browseXMLButton.Enabled = $false

# Create the "Browse" text field for the left pane
$xmlBrowseField = New-Object System.Windows.Forms.TextBox
$xmlBrowseField.Size = New-Object System.Drawing.Size(165, 20)
$xmlBrowseField.Location = New-Object System.Drawing.Point(10, 40)
$xmlBrowseField.Anchor = [AnchorStyles]::Top -bor [AnchorStyles]::Left -bor [AnchorStyles]::Right
$xmlBrowseField.Enabled = $false

# Create the "Paste" button for the left pane
$pasteXMLButton = New-Object System.Windows.Forms.Button
$pasteXMLButton.Size = New-Object System.Drawing.Size(75, 23)
$pasteXMLButton.Location = New-Object System.Drawing.Point(10, 90)
$pasteXMLButton.Text = "Paste"
$pasteXMLButton.Enabled = $true

# Create the "Paste" text field for the left pane
$xmlPasteField = New-Object System.Windows.Forms.TextBox
$xmlPasteField.Size = New-Object System.Drawing.Size(260, 60)
$xmlPasteField.Location = New-Object System.Drawing.Point(10, 120)
$xmlPasteField.Anchor = [AnchorStyles]::Top -bor [AnchorStyles]::Bottom -bor [AnchorStyles]::Left -bor [AnchorStyles]::Right
$xmlPasteField.Multiline = $true
$xmlPasteField.ScrollBars = "Vertical"
$xmlPasteField.Enabled = $true

# Add the controls to the left pane
$leftPane.Controls.Add($browseXMLRadio)
$leftPane.Controls.Add($pasteXMLRadio)
$leftPane.Controls.Add($xmlBrowseField)
$leftPane.Controls.Add($browseXMLButton)
$leftPane.Controls.Add($xmlPasteField)
$leftPane.Controls.Add($pasteXMLButton)

# Create the right pane
$rightPane = New-Object System.Windows.Forms.GroupBox
$rightPane.Size = New-Object System.Drawing.Size(285, 110)
$rightPane.Location = New-Object System.Drawing.Point(0, 0)
$rightPane.Anchor = [AnchorStyles]::Bottom -bor [AnchorStyles]::Left -bor [AnchorStyles]::Right
$rightPane.Text = "Specify output file"

# Create the "File name" field and "Browse" button for the right pane
$fileNameTextField = New-Object System.Windows.Forms.TextBox
$fileNameTextField.Size = New-Object System.Drawing.Size(165, 20)
$fileNameTextField.Location = New-Object System.Drawing.Point(10, 30)
$fileNameTextField.Anchor = [AnchorStyles]::Top -bor [AnchorStyles]::Left -bor [AnchorStyles]::Right

$browseOutputButton = New-Object System.Windows.Forms.Button
$browseOutputButton.Size = New-Object System.Drawing.Size(75, 23)
$browseOutputButton.Location = New-Object System.Drawing.Point(185, 30)
$browseOutputButton.Anchor = [AnchorStyles]::Top -bor [AnchorStyles]::Right
$browseOutputButton.Text = "Browse"

# Create the drop-down menu for the right pane
$formatLabel = New-Object System.Windows.Forms.Label
$formatLabel.Size = New-Object System.Drawing.Size(45, 13)
$formatLabel.Location = New-Object System.Drawing.Point(10, 70)
$formatLabel.Text = "Format:"

$formatMenu = New-Object System.Windows.Forms.ComboBox
$formatMenu.Size = New-Object System.Drawing.Size(60, 21)
$formatMenu.Location = New-Object System.Drawing.Point(60, 70)
$formatMenu.Anchor = [AnchorStyles]::Top -bor [AnchorStyles]::Left -bor [AnchorStyles]::Right
$formatMenu.Items.AddRange(@("CSV", "HTML"))
$formatMenu.SelectedIndex = 0

# Create the "Analyze" button for the right pane
$analyzeButton = New-Object System.Windows.Forms.Button
$analyzeButton.Size = New-Object System.Drawing.Size(75, 23)
$analyzeButton.Location = New-Object System.Drawing.Point(185, 70)
$analyzeButton.Anchor = [AnchorStyles]::Top -bor [AnchorStyles]::Right
$analyzeButton.Text = "Analyze"

# Add the controls to the right pane
$rightPane.Controls.Add($fileNameTextField)
$rightPane.Controls.Add($browseOutputButton)
$rightPane.Controls.Add($formatLabel)
$rightPane.Controls.Add($formatMenu)
$rightPane.Controls.Add($analyzeButton)

# Create the author label
$authorLabel = New-Object System.Windows.Forms.Label
$authorLabel.Size = New-Object System.Drawing.Size(150, 60)
$authorLabel.Location = New-Object System.Drawing.Point(0, 120)
$authorLabel.Anchor = [AnchorStyles]::Top -bor [AnchorStyles]::Left -bor [AnchorStyles]::Right
$authorLabel.Text = @"
Written by Rob Woodruff
Version: $scriptVersion
Date: $scriptDate
"@

# Create the "Check for updates" button
$checkForUpdatesButton = New-Object System.Windows.Forms.Button
$checkForUpdatesButton.Size = New-Object System.Drawing.Size(130, 23)
$checkForUpdatesButton.Location = New-Object System.Drawing.Point(155, 120)
$checkForUpdatesButton.Anchor = [AnchorStyles]::Bottom -bor [AnchorStyles]::Right
$checkForUpdatesButton.Text = "Check for updates"

# Open the URL in the default web browser when the button is clicked
$checkForUpdatesButton.Add_Click({
	Start-Process "https://github.com/FuLoRi/Analyze-LastPassVaultGUI/"
})

# Add the left and right panes to the left-right split container
$splitContainer.Panel1.Controls.Add($leftPane)
$splitContainer.Panel2.Controls.Add($rightPane)
$splitContainer.Panel2.Controls.Add($authorLabel)
$splitContainer.Panel2.Controls.Add($checkForUpdatesButton)

# Add the left-right split container to the form
$form.Controls.Add($splitContainer)


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
    $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
	$saveFileDialog.Filter = "CSV files (*.csv)|*.csv|HTML files (*.html)|*.html"
    if ($saveFileDialog.ShowDialog() -eq "OK") {
        $fileNameTextField.Text = $saveFileDialog.FileName
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
	
   # Set the script parameters
    $OutFile = $fileNameTextField.Text
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
	
	# Open the output file in the default viewer
	Start-Process $OutFile
})

# Display the GUI form
$form.ShowDialog()
