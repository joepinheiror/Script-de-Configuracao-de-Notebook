@echo off

title Configuração Automática de Notebooks - TI 3E

::Senha Padrão da TI (Altere entre as aspas abaixo)
set SENHAADMIN=3ece@TI0897,

:: Verificar privilégio de Administração
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERRO] Execute este script como ADMINISTRADOR!
    pause
    exit /b
)

cls
echo ==================================================================
echo         INICIANDO CONFIGURAÇÃO AUTOMÁTICA DE NOTEBOOK            
echo ==================================================================
echo.
:: ENTRADA DE DADOS (Nome da máquina mantido manualmente pelo colaborador)
set /p NOMEUSUARIO="Digite o NOME DO USUARIO local que sera rebaixado para Padrao: "

echo.
echo [+] Informacoes registradas. Iniciando automacao...
timeout /t 3 >nul

cls
echo ==================================================================
echo         INSTALACAO DOS SOFTWARES E ATUALIZACOES           
echo ==================================================================
echo.

echo [1/4] Instalando Softwares Base via Winget (Chrome, Firefox, VLC, Spotify, LibreOffice, WinRAR, 7-Zip, AnyDesk, TeamViewer, Acrobat)...

winget install --id Google.Chrome --silent --accept-package-agreements --accept-source-agreements
winget install --id Mozilla.Firefox --silent --accept-package-agreements --accept-source-agreements
winget install --id VideoLAN.VLC --silent --accept-package-agreements --accept-source-agreements
winget install --id Spotify.Spotify --silent --accept-package-agreements --accept-source-agreements
winget install --id TheDocumentFoundation.LibreOffice --silent --accept-package-agreements --accept-source-agreements
winget install --id RARLab.WinRAR --silent --accept-package-agreements --accept-source-agreements
winget install --id 7zip.7zip --silent --accept-package-agreements --accept-source-agreements
winget install --id AnyDeskSoftwareGmbH.AnyDesk --silent --accept-package-agreements --accept-source-agreements
winget install --id TeamViewer.TeamViewer --silent --accept-package-agreements --accept-source-agreements
winget install --id Adobe.Acrobat.Reader.64-bit --silent --accept-package-agreements --accept-source-agreements

echo.
echo [2/4] Buscando e aplicando atualizacoes do Windows Update...
powershell -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force; Install-Module -Name PSWindowsUpdate -Force -Confirm:$false -Scope CurrentUser; Import-Module PSWindowsUpdate -Force; Get-WindowsUpdate -AcceptAll -Install -AutoReboot:$false"

cls
echo ==================================================================
echo         CONFIG DE CONTAS, DESEMPENHO E INICIALIZACAO           
echo ==================================================================
echo.

echo [3/4] Configurando Contas, Otimizacoes Visuais e Inicializacao...

echo [+] Configurando conta Administrador local...
net user administrador /active:yes >nul 2>&1
net user administrador %SENHAADMIN% >nul 2>&1

:: Ocultar conta Administrador da tela de login (ativa mas invisivel)
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList" /v Administrador /t REG_DWORD /d 0 /f >nul 2>&1

echo [+] Rebaixando conta '%NOMEUSUARIO%' para usuario Padrao (sem excluir a conta)...
net localgroup administradores "%NOMEUSUARIO%" /delete >nul 2>&1

:: Garantir que a conta do colaborador NAO esta oculta na tela de login
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList" /v "%NOMEUSUARIO%" /f >nul 2>&1

:: Definir o colaborador como usuario padrao da tela de login apos reinicio
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName /t REG_SZ /d "%NOMEUSUARIO%" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d 0 /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /f >nul 2>&1

echo [+] Aplicando configuracoes de otimizacao visual de desempenho...
:: Otimizacao Visual (Melhor desempenho mantendo: miniaturas, fontes arredondadas e sombras de icones)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 3 /f >nul
reg add "HKCU\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9012038010000000 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v IconsOnly /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewShadow /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Control Panel\Desktop" /v FontSmoothing /t REG_SZ /d 2 /f >nul
reg add "HKCU\Control Panel\Desktop" /v FontSmoothingType /t REG_DWORD /d 2 /f >nul
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d 0 /f >nul

echo [+] Otimizando aplicativos de inicializacao (mantendo apenas Realtek, OneDrive, AnyDesk e SecurityHealth)...
powershell -ExecutionPolicy Bypass -Command ^
  "$allowed = @('RtkAudioService64', 'Realtek*', 'OneDrive*', 'AnyDesk*', 'SecurityHealth*'); " ^
  "$paths = @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Run', 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run'); " ^
  "foreach ($p in $paths) { " ^
  "  if (Test-Path $p) { " ^
  "    $props = (Get-ItemProperty -Path $p).PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' }; " ^
  "    foreach ($prop in $props) { " ^
  "      $keep = $false; " ^
  "      foreach ($pat in $allowed) { if ($prop.Name -like $pat) { $keep = $true; break } }; " ^
  "      if (-not $keep) { " ^
  "        Write-Host ('  [-] Removido da inicializacao: ' + $prop.Name); " ^
  "        Remove-ItemProperty -Path $p -Name $prop.Name -ErrorAction SilentlyContinue; " ^
  "      } else { " ^
  "        Write-Host ('  [+] Mantido na inicializacao: ' + $prop.Name); " ^
  "      } " ^
  "    } " ^
  "  } " ^
  "}"

timeout /t 4 >nul

echo.
echo ==================================================================
echo                      GLPI AGENT           
echo ==================================================================
echo.

echo [4/4] Instalando GLPI Agent e executando inventario...
set SERVER_URL=https://glpi.estoque.3e.eng.br/

echo [+] Instalando GLPI Agent via Winget...
winget install --id GLPI-Project.GLPI-Agent --silent --accept-package-agreements --accept-source-agreements --override "/qn SERVER=\"%SERVER_URL%\" QUICKINSTALL=1 /norestart"

if %errorLevel% neq 0 (
    echo [!] Winget retornou codigo diferente de 0. Executando instalador direto como garantia...
    powershell -ExecutionPolicy Bypass -Command ^
      "$url = 'https://github.com/glpi-project/glpi-agent/releases/download/1.21/GLPI-Agent-1.21-x64.msi'; " ^
      "$dest = Join-Path $env:TEMP 'GLPI-Agent.msi'; " ^
      "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; " ^
      "(New-Object System.Net.WebClient).DownloadFile($url, $dest); " ^
      "Start-Process msiexec.exe -ArgumentList ('/i `\"' + $dest + '`\" /qn SERVER=`\"%SERVER_URL%`\" QUICKINSTALL=1 /norestart') -Wait"
)

echo [+] Aguardando o servico GLPI Agent iniciar...
timeout /t 10 >nul
echo [+] Solicitando inventario local...
powershell -Command "try { Invoke-WebRequest -Uri 'http://127.0.0.1:62354/now' -UseBasicParsing | Out-Null; Write-Host '[+] Inventario enviado com sucesso!' } catch { Write-Host '[-] Sincronizacao pendente pos-reinicio.' }"

echo.
echo ==================================================================
echo   CONFIGURACAO CONCLUIDA! REINICIANDO EM 10 SEGUNDOS...
echo ==================================================================
timeout /t 10
shutdown /r /t 0 /f