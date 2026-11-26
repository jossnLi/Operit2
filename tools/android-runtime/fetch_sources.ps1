$ErrorActionPreference = "Stop"

$runtimeDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$downloadsDir = Join-Path $runtimeDir "downloads"
$sourcesDir = Join-Path $runtimeDir "sources"

New-Item -ItemType Directory -Force -Path $downloadsDir | Out-Null
New-Item -ItemType Directory -Force -Path $sourcesDir | Out-Null

function Get-ArchiveSha256([string] $Path) {
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToUpperInvariant()
}

function Get-CurlExecutable {
    $candidates = if ($env:OS -eq "Windows_NT") { @("curl.exe") } else { @("curl", "curl.exe") }
    foreach ($candidate in $candidates) {
        # Linux images expose curl through more than one path, so take the first match.
        $command = @(Get-Command $candidate -CommandType Application -ErrorAction SilentlyContinue) |
            Select-Object -First 1
        if ($command -and $command.Source) {
            return [string] $command.Source
        }
    }
    throw "curl is required to download the Android runtime sources"
}

function Get-VerifiedArchive($Item, [string] $ArchivePath) {
    if (Test-Path -LiteralPath $ArchivePath -PathType Leaf) {
        $cachedSha256 = Get-ArchiveSha256 $ArchivePath
        if ($cachedSha256 -eq $Item.Sha256) {
            Write-Host "Using verified archive $($Item.Archive)"
            return
        }
        Write-Warning "Discarding incomplete or invalid archive $($Item.Archive)"
        Remove-Item -LiteralPath $ArchivePath -Force
    }

    $curl = Get-CurlExecutable
    $maxAttempts = 6
    $downloadUrls = if ($Item.Urls) { @($Item.Urls) } else { ,@($Item.Url) }
    $lastError = $null
    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        $urlIndex = ($attempt - 1) % $downloadUrls.Count
        $downloadUrl = $downloadUrls[$urlIndex]

        # A failed request leaves a partial file behind; never reuse it on retry.
        if (Test-Path -LiteralPath $ArchivePath) {
            Remove-Item -LiteralPath $ArchivePath -Force
        }

        Write-Host "Downloading $($Item.Name) from $downloadUrl (attempt $attempt/$maxAttempts)"
        # curl retries stalled connections and 5xx itself; mirrors that hang on the
        # first byte no longer eat the whole step timeout.
        $curlArgs = @(
            "--fail", "--location", "--silent", "--show-error",
            "--retry", "4", "--retry-all-errors", "--retry-delay", "3",
            "--connect-timeout", "20", "--max-time", "600",
            "--output", $ArchivePath, "--url", $downloadUrl
        )
        & $curl @curlArgs 2>&1 | ForEach-Object { Write-Host $_ }
        $curlExitCode = $LASTEXITCODE

        if ($curlExitCode -eq 0 -and (Test-Path -LiteralPath $ArchivePath -PathType Leaf)) {
            $actualSha256 = Get-ArchiveSha256 $ArchivePath
            if ($actualSha256 -eq $Item.Sha256) {
                return
            }
            $lastError = "$($Item.Archive) SHA256 mismatch: expected $($Item.Sha256), got $actualSha256"
        }
        else {
            $lastError = "curl exit code $curlExitCode"
        }

        if (Test-Path -LiteralPath $ArchivePath) {
            Remove-Item -LiteralPath $ArchivePath -Force
        }
        if ($attempt -lt $maxAttempts) {
            $delaySeconds = [Math]::Min(15, 2 * $attempt)
            Write-Warning "Download failed from $downloadUrl`: $lastError. Retrying in $delaySeconds seconds."
            Start-Sleep -Seconds $delaySeconds
        }
    }

    throw "Failed to download and verify $($Item.Archive) after $maxAttempts attempts over $($downloadUrls.Count) mirror(s). Last URL: $downloadUrl. Last error: $lastError"
}

$items = @(
    @{
        Name = "busybox-1.38.0"
          Urls = @(
              "https://busybox.net/downloads/busybox-1.38.0.tar.bz2"
              "https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/busybox/1%3A1.38.0-3ubuntu5/busybox_1.38.0.orig.tar.bz2"
          )
        Archive = "busybox-1.38.0.tar.bz2"
        Sha256 = "34F9EA6FF8636F2C9241153B9114EEFA9E65674A45318AE1EF95BB5F31C53BB2"
        Extracted = "busybox-1.38.0"
    },
    @{
        Name = "termux-proot-v5.1.107.78"
        Url = "https://github.com/termux/proot/archive/refs/tags/v5.1.107.78.tar.gz"
        Archive = "termux-proot-v5.1.107.78.tar.gz"
        Sha256 = "F3377BA49DCD833370420C34C5081B4C243ECBB85B2A9881A4F4586012599AFA"
        Extracted = "proot-5.1.107.78"
    },
    @{
        Name = "talloc-2.4.3"
        Urls = @(
            "https://distfiles.macports.org/talloc/talloc-2.4.3.tar.gz"
            "https://www.samba.org/ftp/talloc/talloc-2.4.3.tar.gz"
            "https://ftp.samba.org/pub/talloc/talloc-2.4.3.tar.gz"
        )
        Archive = "talloc-2.4.3.tar.gz"
        Sha256 = "DC46C40B9F46BB34DD97FE41F548B0E8B247B77A918576733C528E83ABD854DD"
        Extracted = "talloc-2.4.3"
    },
    @{
        Name = "bash-5.2.37"
        Urls = @(
            "https://ftpmirror.gnu.org/bash/bash-5.2.37.tar.gz"
            "https://ftp.gnu.org/gnu/bash/bash-5.2.37.tar.gz"
            "https://github.com/gnu-mirror-unofficial/bash/archive/refs/tags/bash-5.2.37.tar.gz"
        )
        Archive = "bash-5.2.37.tar.gz"
        Sha256 = "9599B22ECD1D5787AD7D3B7BF0C59F312B3396D1E281175DD1F8A4014DA621FF"
        Extracted = "bash-5.2.37"
    }
)

foreach ($item in $items) {
    $archivePath = Join-Path $downloadsDir $item.Archive
    Get-VerifiedArchive $item $archivePath

    $extractPath = Join-Path $sourcesDir $item.Extracted
    if (Test-Path $extractPath) {
        Remove-Item -LiteralPath $extractPath -Recurse -Force
    }

    tar -xf $archivePath -C $sourcesDir
}
