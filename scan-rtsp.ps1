param (
    [string]$Subnet = "192.168.1.",
    [string[]]$Credentials = @(),
    [bool]$MaskPasswords = $true,
    [switch]$PromptCredentials
)

# ==========================================
# DEFAULT SCANNER SETTINGS
# ==========================================
$Range = 1..254
$Ports = @(554, 8554, 10554, 5554, 7070, 8000, 8080, 1935)
$TimeoutMs = 100
$MaxThreads = 50

# DEFAULT CREDENTIALS IN FILE (leave empty before publishing)
$FileCredentials = @(
    "",         # Anonymous check (always recommended)
    "admin:"    # Example: admin with empty password
)

# Merge CLI credentials with file credentials
$AllCredentials = New-Object System.Collections.Generic.List[string]
$AllCredentials.Add("")
foreach ($c in $Credentials) { if ($c -ne "") { $AllCredentials.Add($c) } }
foreach ($c in $FileCredentials) { if ($c -ne "") { $AllCredentials.Add($c) } }

# Optional secure interactive prompt (does not save to shell history)
if ($PromptCredentials) {
    $inUser = Read-Host "Enter RTSP username (leave blank to skip)"
    if ($inUser -ne "") {
        $secPass = Read-Host "Enter RTSP password" -AsSecureString
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secPass)
        $plainPass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        $AllCredentials.Add("${inUser}:${plainPass}")
    }
}

# COMMON RTSP PATHS
$Paths = @(
    "/", "/stream1", "/stream2", "/live", "/live/ch0", "/live/main", "/live/sub",
    "/h264", "/h264Preview_01_main", "/Streaming/Channels/101", "/Streaming/Channels/102",
    "/cam/realmonitor?channel=1&subtype=0", "/user=admin&password=&channel=1&stream=0.sdp",
    "/ch0_0.h264", "/media/video1", "/axis-media/media.amp", "/videoMain", "/11", "/12", "/1"
)

# AUTO-SAVE TO CURRENT USER DESKTOP
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$OutputFile = Join-Path -Path $DesktopPath -ChildPath "RTSP_Scan_$Timestamp.txt"
$SavedResults = New-Object System.Collections.Generic.List[string]

Write-Host "Starting RTSP scan on ${Subnet}0/24 (MaskPasswords: $MaskPasswords)..." -ForegroundColor Cyan

$Pool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads)
$Pool.Open()
$Jobs = @()

$ScriptBlock = {
    param($ip, $Ports, $TimeoutMs, $Paths, $CredList, $MaskPasswords)
    $found = @()

    function Send-RtspRequest {
        param($ip, $port, $method, $uri, $cred, $cseq)
        $client = New-Object System.Net.Sockets.TcpClient
        try {
            $connect = $client.BeginConnect($ip, $port, $null, $null)
            if (-not ($connect.AsyncWaitHandle.WaitOne(300, $false) -and $client.Connected)) { return $null }
            $client.EndConnect($connect)
            $stream = $client.GetStream()
            $stream.ReadTimeout = 400

            $authHeader = ""
            if ($cred -ne "") {
                $b64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($cred))
                $authHeader = "Authorization: Basic $b64`r`n"
            }

            $req = "$method $uri RTSP/1.0`r`nCSeq: $cseq`r`n${authHeader}Accept: application/sdp`r`n`r`n"
            $bytes = [Text.Encoding]::ASCII.GetBytes($req)
            $stream.Write($bytes, 0, $bytes.Length)

            $buffer = New-Object byte[] 1024
            $read = $stream.Read($buffer, 0, $buffer.Length)
            $resp = [Text.Encoding]::ASCII.GetString($buffer, 0, $read)

            if ($resp -match "401 Unauthorized" -and $resp -match 'WWW-Authenticate:\s*Digest\s+realm="([^"]+)",\s*nonce="([^"]+)"' -and $cred -ne "") {
                $realm = $matches
                $nonce = $matches
                $parts = $cred -split ":", 2
                $user = $parts
                $pass = if ($parts.Count -gt 1) { $parts } else { "" }

                $md5 = [System.Security.Cryptography.MD5]::Create()
                $ha1 = [BitConverter]::ToString($md5.ComputeHash([Text.Encoding]::UTF8.GetBytes("${user}:${realm}:${pass}"))).Replace("-", "").ToLower()
                $ha2 = [BitConverter]::ToString($md5.ComputeHash([Text.Encoding]::UTF8.GetBytes("${method}:${uri}"))).Replace("-", "").ToLower()
                $responseHash = [BitConverter]::ToString($md5.ComputeHash([Text.Encoding]::UTF8.GetBytes("${ha1}:${nonce}:${ha2}"))).Replace("-", "").ToLower()

                $digestHeader = "Authorization: Digest username=`"$user`", realm=`"$realm`", nonce=`"$nonce`", uri=`"$uri`", response=`"$responseHash`"`r`n"
                $cseq++
                $req2 = "$method $uri RTSP/1.0`r`nCSeq: $cseq`r`n${digestHeader}Accept: application/sdp`r`n`r`n"
                $bytes2 = [Text.Encoding]::ASCII.GetBytes($req2)
                $stream.Write($bytes2, 0, $bytes2.Length)

                $read2 = $stream.Read($buffer, 0, $buffer.Length)
                $resp = [Text.Encoding]::ASCII.GetString($buffer, 0, $read2)
            }
            return $resp
        } catch {
            return $null
        } finally {
            $client.Close()
        }
    }

    foreach ($port in $Ports) {
        $probe = New-Object System.Net.Sockets.TcpClient
        $conn = $probe.BeginConnect($ip, $port, $null, $null)
        $isOpen = $conn.AsyncWaitHandle.WaitOne($TimeoutMs, $false) -and $probe.Connected
        $probe.Close()
        if (-not $isOpen) { continue }

        $baseUrl = "rtsp://${ip}:${port}/"
        $respOpt = Send-RtspRequest -ip $ip -port $port -method "OPTIONS" -uri $baseUrl -cred "" -cseq 1

        if ($respOpt -and $respOpt -match "^RTSP/1\.0") {
            $msgRtsp = "[RTSP SERVER] $baseUrl"
            $found += [PSCustomObject]@{ Type = "RTSP"; Msg = $msgRtsp; FileMsg = $msgRtsp }

            $validCred = $null
            foreach ($cred in ($CredList | Select-Object -Unique)) {
                $testResp = Send-RtspRequest -ip $ip -port $port -method "DESCRIBE" -uri $baseUrl -cred $cred -cseq 2
                if ($testResp -and ($testResp -match "200 OK" -or $testResp -match "404 Not Found" -or $testResp -match "400 Bad Request")) {
                    $validCred = $cred
                    break
                }
            }

            if ($null -eq $validCred) {
                $msgAuth = "   -> [AUTH REQUIRED] No matching credentials"
                $found += [PSCustomObject]@{ Type = "AUTH"; Msg = $msgAuth; FileMsg = $msgAuth }
                continue
            }

            $credPrefix = ""
            $filePrefix = ""
            if ($validCred -ne "") {
                $credPrefix = "$validCred@"
                if ($MaskPasswords) {
                    $cParts = $validCred -split ":", 2
                    $uName = $cParts
                    $uPass = if ($cParts.Count -gt 1) { $cParts } else { "" }
                    if ($uPass.Length -gt 1) {
                        $maskedPass = $uPass.Substring(0, 1) + ("*" * ($uPass.Length - 1))
                    } else {
                        $maskedPass = $uPass
                    }
                    $filePrefix = "${uName}:${maskedPass}@"
                } else {
                    $filePrefix = "$validCred@"
                }
            }

            foreach ($path in $Paths) {
                $targetUrl = "rtsp://${ip}:${port}${path}"
                $respDesc = Send-RtspRequest -ip $ip -port $port -method "DESCRIBE" -uri $targetUrl -cred $validCred -cseq 3
                if ($respDesc -and $respDesc -match "200 OK") {
                    $finalLink = "rtsp://${credPrefix}${ip}:${port}${path}"
                    $fileLink = "rtsp://${filePrefix}${ip}:${port}${path}"
                    $found += [PSCustomObject]@{
                        Type = "OPEN"
                        Msg = "   -> [STREAM FOUND] $finalLink"
                        FileMsg = "   -> [STREAM FOUND] $fileLink"
                    }
                }
            }
        } else {
            $msgPort = "[OPEN PORT] ${ip}:${port} (not RTSP)"
            $found += [PSCustomObject]@{ Type = "PORT"; Msg = $msgPort; FileMsg = $msgPort }
        }
    }
    return $found
}

foreach ($i in $Range) {
    $ip = "$Subnet$i"
    $PS = [powershell]::Create().AddScript($ScriptBlock).AddArgument($ip).AddArgument($Ports).AddArgument($TimeoutMs).AddArgument($Paths).AddArgument($AllCredentials).AddArgument($MaskPasswords)
    $PS.RunspacePool = $Pool
    $Jobs += [PSCustomObject]@{ Pipe = $PS; Handle = $PS.BeginInvoke() }
}

while ($Jobs.Count -gt 0) {
    $Done = $Jobs | Where-Object { $_.Handle.IsCompleted }
    foreach ($Job in $Done) {
        $Results = $Job.Pipe.EndInvoke($Job.Handle)
        foreach ($res in $Results) {
            switch ($res.Type) {
                "RTSP" { Write-Host $res.Msg -ForegroundColor Cyan; $SavedResults.Add($res.FileMsg) }
                "OPEN" { Write-Host $res.Msg -ForegroundColor Green; $SavedResults.Add($res.FileMsg) }
                "AUTH" { Write-Host $res.Msg -ForegroundColor Yellow; $SavedResults.Add($res.FileMsg) }
                "PORT" { Write-Host $res.Msg -ForegroundColor DarkGray }
            }
        }
        $Job.Pipe.Dispose()
        $Jobs = $Jobs | Where-Object { $_ -ne $Job }
    }
    Start-Sleep -Milliseconds 50
}

$Pool.Close()
$Pool.Dispose()

if ($SavedResults.Count -gt 0) {
    $SavedResults | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Host "`nScan complete. Results saved to:" -ForegroundColor Cyan
    Write-Host $OutputFile -ForegroundColor White
} else {
    Write-Host "`nScan complete. No RTSP sources found." -ForegroundColor Yellow
}
