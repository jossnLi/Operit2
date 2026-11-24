$ErrorActionPreference = "Stop"

$runtimeDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$downloadsDir = Join-Path $runtimeDir "downloads"
$sourcesDir = Join-Path $runtimeDir "sources"

New-Item -ItemType Directory -Force -Path $downloadsDir | Out-Null
New-Item -ItemType Directory -Force -Path $sourcesDir | Out-Null

function Get-ArchiveSha256([string] $Path) {
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToUpperInvariant()
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

    $maxAttempts = 5
    $downloadUrls = if ($Item.Urls) { @($Item.Urls) } else { ,@($Item.Url) }
    $lastError = $null
    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        $urlIndex = ($attempt - 1) % $downloadUrls.Count
        $downloadUrl = $downloadUrls[$urlIndex]
        try {
            # A failed request can leave a partial file. Never reuse it on retry.
            if (Test-Path -LiteralPath $ArchivePath) {
                Remove-Item -LiteralPath $ArchivePath -Force
            }

            Write-Host "Downloading $($Item.Name) from $downloadUrl (attempt $attempt/$maxAttempts)"
            Invoke-WebRequest -Uri $downloadUrl -OutFile $ArchivePath -TimeoutSec 120

            $actualSha256 = Get-ArchiveSha256 $ArchivePath
            if ($actualSha256 -ne $Item.Sha256) {
                throw "$($Item.Archive) SHA256 mismatch: $actualSha256"
            }
            return
        }
        catch {
            $lastError = $_.Exception.Message
            if (Test-Path -LiteralPath $ArchivePath) {
                Remove-Item -LiteralPath $ArchivePath -Force
            }
            if ($attempt -eq $maxAttempts) {
                throw "Failed to download and verify $($Item.Archive) after $maxAttempts attempts. Last URL: $downloadUrl. Last error: $lastError"
            }

            $delaySeconds = [Math]::Min(30, [Math]::Pow(2, $attempt))
            Write-Warning "Download failed from $downloadUrl`: $lastError. Retrying in $delaySeconds seconds."
            Start-Sleep -Seconds $delaySeconds
        }
    }
}

$items = @(
    @{
        Name = "busybox-1.38.0"
        Url = "https://busybox.net/downloads/busybox-1.38.0.tar.bz2"
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
        Url = "https://www.samba.org/ftp/talloc/talloc-2.4.3.tar.gz"
        Archive = "talloc-2.4.3.tar.gz"
        Sha256 = "DC46C40B9F46BB34DD97FE41F548B0E8B247B77A918576733C528E83ABD854DD"
        Extracted = "talloc-2.4.3"
    },
    @{
        Name = "bash-5.2.37"
        Urls = @(
            "https://ftpmirror.gnu.org/bash/bash-5.2.37.tar.gz"
            "https://ftp.gnu.org/gnu/bash/bash-5.2.37.tar.gz"
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
