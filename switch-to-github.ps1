<#
  switch-to-github.ps1
  把本机 git 仓库从 gitee 切到 github。

  用法:
    # 预演（只看会改成什么，不动手）
    .\switch-to-github.ps1 -GithubUser YourName -DryRun

    # 真改（自动扫描 D:\code 下的仓库）
    .\switch-to-github.ps1 -GithubUser YourName

    # 指定仓库 + 同时换提交邮箱
    .\switch-to-github.ps1 -GithubUser YourName -Repos D:\code\demo,D:\code\library_test -Email you@example.com

  说明:
    - 默认保持仓库名不变: gitee.com/<OLD_OWNER>/<repo>  ->  github.com/<GithubUser>/<repo>
    - 用 SSH 地址（git@github.com:...），前提是公钥已加到 GitHub 账号
    - 想走 HTTPS 就加 -Https
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$GithubUser,
    [string[]]$Repos,
    [string]$ScanRoot = 'D:\code',
    [string]$Email,
    [switch]$Https,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

function Get-Repos {
    if ($Repos) { return $Repos }
    Get-ChildItem -Path $ScanRoot -Directory -Filter '.git' -Recurse -Depth 3 -Force -ErrorAction SilentlyContinue |
        ForEach-Object { $_.Parent.FullName } | Sort-Object -Unique
}

# gitee URL -> github URL
function Convert-RemoteUrl {
    param([string]$Url, [string]$User, [bool]$UseHttps)

    # https://gitee.com/owner/repo(.git)   或   git@gitee.com:owner/repo(.git)
    $repo = $null
    if ($Url -match 'gitee\.com[:/]+([^/]+)/(.+?)(?:\.git)?/?$') {
        $repo = $Matches[2] -replace '\.git$', ''
    }
    elseif ($Url -match 'github\.com[:/]+([^/]+)/(.+?)(?:\.git)?/?$') {
        $repo = $Matches[2] -replace '\.git$', ''   # 已经是 github，只纠正 owner
    }
    else { return $null }   # 非 gitee/github，跳过

    if ($UseHttps) { "https://github.com/$User/$repo.git" }
    else { "git@github.com:$User/$repo.git" }
}

$targets = Get-Repos
if (-not $targets) { Write-Host "没找到任何 git 仓库（扫描根: $ScanRoot）" -ForegroundColor Yellow; return }

foreach ($path in $targets) {
    Write-Host "`n=== $path ===" -ForegroundColor Cyan
    $remotes = & git -C $path remote
    if (-not $remotes) { Write-Host "  无 remote，跳过"; continue }

    foreach ($r in $remotes) {
        $old = (& git -C $path remote get-url $r).Trim()
        $new = Convert-RemoteUrl -Url $old -User $GithubUser -UseHttps:$Https.IsPresent

        if (-not $new) { Write-Host "  [$r] 非 gitee/github 地址，保持: $old"; continue }
        if ($new -eq $old) { Write-Host "  [$r] 已是目标地址: $old"; continue }

        if ($DryRun) {
            Write-Host "  [$r] $old" -ForegroundColor DarkGray
            Write-Host "    -> $new" -ForegroundColor Green
        }
        else {
            & git -C $path remote set-url $r $new
            Write-Host "  [$r] $old  ->  $new" -ForegroundColor Green
        }
    }

    if ($Email) {
        if ($DryRun) { Write-Host "  [email] -> $Email (预演)" -ForegroundColor Green }
        else { & git -C $path config user.email $Email; Write-Host "  [email] 已设为 $Email" -ForegroundColor Green }
    }
}

if ($DryRun) { Write-Host "`n[预演结束] 去掉 -DryRun 才会真正改。" -ForegroundColor Yellow }
else { Write-Host "`n完成。验证: git -C <repo> remote -v ; ssh -T git@github.com" -ForegroundColor Yellow }
