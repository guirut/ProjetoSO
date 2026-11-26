# medir.ps1 - mede swap, RAM livre, paginacao e responsividade, e grava uma linha no CSV.
# Uso (no PowerShell, na pasta do script):
#   powershell -ExecutionPolicy Bypass -File .\medir.ps1 -Conteudo inicial -Abas 10
# Conteudo: inicial | wikipedia | video1080p     Abas: 0, 10, 25, 50
# Responsividade: tempo para abrir o Firefox (3 vezes).
# A RAM e detectada sozinha e vai para a coluna RAM_GB.
# O arquivo e gravado como resultados_<RAM>GB.csv na pasta do script.

param(
    [Parameter(Mandatory = $true)][ValidateSet('inicial', 'wikipedia', 'video1080p')][string]$Conteudo,
    [Parameter(Mandatory = $true)][ValidateSet(0, 10, 25, 50)][int]$Abas,
    [int]$Amostras = 60,
    [string]$Arquivo = ''
)

$br = [System.Globalization.CultureInfo]'pt-BR'
function Num($v, $fmt) { ([double]$v).ToString($fmt, $br) }

# RAM visivel ao Windows, arredondada para GB inteiro (ex.: 7,9 -> 8)
$ramGB = [math]::Round((Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize / 1MB)

if (-not $Arquivo) {
    $pasta = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
    $Arquivo = Join-Path $pasta ("resultados_{0}GB.csv" -f $ramGB)
}

# Confere se esta condicao ja foi gravada (evita repetir o numero de abas por engano)
if (Test-Path $Arquivo) {
    $existentes = Import-Csv $Arquivo -Delimiter ';'
    $ultima = $existentes | Select-Object -Last 1
    if ($ultima) {
        Write-Host ("Ultima linha gravada: {0} | {1} abas | {2}" -f $ultima.Conteudo, $ultima.Abas, $ultima.DataHora) -ForegroundColor DarkGray
    }
    $repetida = $existentes | Where-Object { $_.Conteudo -eq $Conteudo -and [int]$_.Abas -eq $Abas }
    if ($repetida) {
        Write-Host ("ATENCAO: ja existe uma linha com {0} e {1} abas em {2}." -f $Conteudo, $Abas, (Split-Path $Arquivo -Leaf)) -ForegroundColor Red
    }
}

# Localiza o Firefox antes de comecar
$ffExe = $null
$appPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\firefox.exe'
if (Test-Path $appPath) { $ffExe = (Get-ItemProperty $appPath).'(default)' }
if (-not $ffExe -or -not (Test-Path $ffExe)) {
    $ffExe = @(
        "$env:ProgramFiles\Mozilla Firefox\firefox.exe",
        "${env:ProgramFiles(x86)}\Mozilla Firefox\firefox.exe",
        "$env:LOCALAPPDATA\Mozilla Firefox\firefox.exe"
    ) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
}
if (-not $ffExe) { Write-Host "Firefox nao encontrado. Nada foi gravado." -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host ("Vai medir: {0} | {1} abas | RAM {2} GB | app Firefox" -f $Conteudo, $Abas, $ramGB) -ForegroundColor Cyan
$ok = Read-Host "Esta certo? (s/n)"
if ($ok -notmatch '^[sS]') { Write-Host "Cancelado. Nada foi gravado."; exit }

Write-Host "Nao mexa no computador ate terminar." -ForegroundColor Yellow

# 1) Coleta de swap, RAM livre e paginacao (1 amostra por segundo, aprox.)
$swap = @(); $livre = @(); $pag = @()
for ($i = 1; $i -le $Amostras; $i++) {
    $swap  += (Get-CimInstance Win32_PageFileUsage | Measure-Object CurrentUsage -Sum).Sum
    $livre += (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1024
    $pag   += (Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory).PagesPersec
    Write-Progress -Activity "Coletando memoria" -Status "$i de $Amostras" -PercentComplete ($i / $Amostras * 100)
    Start-Sleep -Seconds 1
}
Write-Progress -Activity "Coletando memoria" -Completed

# 2) Responsividade: tempo ate a janela do Firefox aparecer (3 vezes)
#    Usa uma instancia separada, com perfil proprio, para nao mexer no Firefox
#    que voce estiver usando nos testes.

$pastaBase = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$perfil = Join-Path $pastaBase 'ff-perfil-medicao'
if (-not (Test-Path $perfil)) { New-Item -ItemType Directory -Path $perfil | Out-Null }
# Preferencias para abrir sempre limpo: sem tela de boas-vindas, sem restaurar sessao, sem modo seguro
@'
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.aboutwelcome.enabled", false);
user_pref("browser.startup.homepage_override.mstone", "ignore");
user_pref("browser.startup.page", 0);
user_pref("browser.sessionstore.resume_from_crash", false);
user_pref("toolkit.startup.max_resumed_crashes", -1);
user_pref("datareporting.policy.dataSubmissionPolicyBypassNotification", true);
user_pref("toolkit.telemetry.reportingpolicy.firstRun", false);
user_pref("app.update.auto", false);
'@ | Set-Content -Path (Join-Path $perfil 'user.js') -Encoding ASCII

function Fechar-FirefoxMedicao {
    Get-CimInstance Win32_Process -Filter "Name='firefox.exe'" |
        Where-Object { $_.CommandLine -like "*ff-perfil-medicao*" } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}

Write-Host "Medindo tempo para abrir o Firefox (3x)..."
Fechar-FirefoxMedicao
$tempos = @()
foreach ($k in 1..3) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $p = Start-Process $ffExe -ArgumentList @('-no-remote', '-new-instance', '-profile', "`"$perfil`"", 'about:blank') -PassThru
    while ($p.MainWindowHandle -eq [IntPtr]::Zero -and -not $p.HasExited -and $sw.Elapsed.TotalSeconds -lt 60) {
        Start-Sleep -Milliseconds 20
        $p.Refresh()
    }
    $sw.Stop()
    $tempos += $sw.Elapsed.TotalSeconds
    Start-Sleep -Seconds 1
    Fechar-FirefoxMedicao
    Start-Sleep -Seconds 3
}

# 3) Resultado
$swapMedioGB = ($swap   | Measure-Object -Average).Average / 1024
$swapMaxMB   = ($swap   | Measure-Object -Maximum).Maximum
$livreMedio  = ($livre  | Measure-Object -Average).Average
$pagMedia    = ($pag    | Measure-Object -Average).Average
$tempoMedio  = ($tempos | Measure-Object -Average).Average

$linha = [pscustomobject]@{
    DataHora            = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Conteudo            = $Conteudo
    Abas                = $Abas
    RAM_GB              = $ramGB
    SwapMedio_GB        = Num $swapMedioGB '0.00'
    SwapMax_MB          = Num $swapMaxMB '0'
    RAMLivreMedia_MB    = Num $livreMedio '0'
    PaginasPorSeg_Media = Num $pagMedia '0.0'
    App                 = 'firefox'
    AbrirApp1_s         = Num $tempos[0] '0.000'
    AbrirApp2_s         = Num $tempos[1] '0.000'
    AbrirApp3_s         = Num $tempos[2] '0.000'
    AbrirAppMedia_s     = Num $tempoMedio '0.000'
}

try {
    $linha | Export-Csv -Path $Arquivo -Append -NoTypeInformation -Delimiter ';' -Encoding UTF8 -Force -ErrorAction Stop
} catch {
    Write-Host "Nao consegui gravar no CSV (esta aberto no Excel?). Feche e rode de novo. Valores medidos:" -ForegroundColor Red
    $linha | Format-List
    exit 1
}
$linha | Format-List
Write-Host "Gravado em: $Arquivo" -ForegroundColor Green
