# Installera modulen PSWindowsUpdate från PowerShell Gallery med Force-parametern för att installera även om en tidigare version redan finns
Write-Host "Installerar / updaterar modulen PSWindowsUpdate..."
Install-Module -Name PSWindowsUpdate -Force

# Importera modulen PSWindowsUpdate för att använda dess cmdletar
Import-Module PSWindowsUpdate

# Hämta information om tillgängliga Windows-uppdateringar
Write-Host "Hämtar information om windows-uppdateringar..."
Get-WindowsUpdate

# Installera tillgängliga Windows-uppdateringar med AcceptAll-parametern för att acceptera alla 
# uppdateringar utan bekräftelse och AutoReboot-parametern för att automatiskt starta om systemet vid behov
Write-Host "Installerar uppdateringar och startar om ifall behov finns..."
Install-WindowsUpdate -AcceptAll -AutoReboot

# Uppdatera Windows Defender Antivirus-definitioner
Write-Host "Uppdaterar Windows Defender Antivirus-definitioner..."
Update-MpSignature
Write-Host "Uppdatering Klar..."

# Starta en snabb skanning med Windows Defender Antivirus
Write-Host "Kör en snabb scan med Windows Defender Antivirus..."
Start-MpScan -ScanType QuickScan

# Hämta hotdetaljer efter den senaste skanningen
$threats = Get-MpThreatDetection

# Kontrollera om några hot har upptäckts skriver ut ifall hoten är större än 0.
if ($threats.Count -gt 0) {
    Write-Host "Hot upptäckta:"
    # Skriver ut för varje upptäckt hot.
    foreach ($threat in $threats) {
        Write-Host "Hotnamn: $($threat.ThreatName)"
        Write-Host "Hotstatus: $($threat.DetectionSource)"
        Write-Host "Hotplats: $($threat.FullPath)"
        Write-Host "Hottyp: $($threat.ThreatType)"
    }
} else {
    Write-Host "Inga hot upptäckta."
}