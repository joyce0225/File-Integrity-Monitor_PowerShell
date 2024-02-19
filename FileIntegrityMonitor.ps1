
# Email configuration
$smtpServer = 'your.smtp.server'
$smtpFrom = 'your-email@example.com'
$smtpTo = 'recipient-email@example.com'
$smtpSubject = 'Security Alert: Potential Compromise Detected'

# Function to send an email
function SendEmail($body) {
    $mailMessage = New-Object System.Net.Mail.MailMessage $smtpFrom, $smtpTo
    $mailMessage.Subject = $smtpSubject
    $mailMessage.Body = $body
    $smtpClient = New-Object Net.Mail.SmtpClient($smtpServer)
    $smtpClient.Send($mailMessage)
}

# Directory to monitor for security-sensitive files
$securitySensitiveDirs = @(
    'C:\Windows\System32', # Common target for system exploits
    'C:\Users',            # User profile directories
    'C:\ProgramData'       # Application configuration and data
    # Add more directories as needed
)

# Hash algorithm
$hashAlgorithm = 'SHA512'

# Build baseline of target files/folders
$baseline = @{}
$securitySensitiveDirs | ForEach-Object {
    Get-ChildItem -Path $_ -Recurse | ForEach-Object {
        $baseline[$_.FullName] = (Get-FileHash -Path $_.FullName -Algorithm $hashAlgorithm).Hash
    }
}

# Monitor for changes
while ($true) {
    # Check actual files against baseline
    $changesDetected = $false
    $alertMessage = ""
    $securitySensitiveDirs | ForEach-Object {
        Get-ChildItem -Path $_ -Recurse | ForEach-Object {
            $currentHash = (Get-FileHash -Path $_.FullName -Algorithm $hashAlgorithm).Hash
            if ($baseline[$_.FullName] -ne $currentHash) {
                # Detected changes in sensitive files
                $changesDetected = $true
                $alertMessage += 'Change detected in file: $($_.FullName)`n'
                # Update baseline
                $baseline[$_.FullName] = $currentHash
            }
        }
    }

    if ($changesDetected) {
        # Log and send email alert
        $alertMessage += 'Potential compromise detected. Please investigate immediately.'
        Write-Host $alertMessage
        SendEmail $alertMessage
    }

    # Sleep for a minute before checking again
    Start-Sleep -Seconds 60
}
