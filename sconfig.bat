@echo off
chcp 65001 >nul

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

echo [1/3] Instalando Softwares Base via Winget (Chrome, Firefox, VLC, Spotify, LibreOffice, WinRAR, 7-Zip, AnyDesk, TeamViewer, Acrobat)...

echo [+] Reparando e atualizando repositorio do Winget...
winget source reset --force >nul 2>&1
winget source update --name winget

winget install --id Google.Chrome --source winget --silent --accept-package-agreements --accept-source-agreements
winget install --id Mozilla.Firefox --source winget --silent --accept-package-agreements --accept-source-agreements
winget install --id VideoLAN.VLC --source winget --silent --accept-package-agreements --accept-source-agreements
winget install --id Spotify.Spotify --source winget --silent --accept-package-agreements --accept-source-agreements
winget install --id TheDocumentFoundation.LibreOffice --source winget --silent --accept-package-agreements --accept-source-agreements
winget install --id RARLab.WinRAR --source winget --silent --accept-package-agreements --accept-source-agreements
winget install --id 7zip.7zip --source winget --silent --accept-package-agreements --accept-source-agreements
winget install --id AnyDeskSoftwareGmbH.AnyDesk --source winget --silent --accept-package-agreements --accept-source-agreements
winget install --id TeamViewer.TeamViewer --source winget --silent --accept-package-agreements --accept-source-agreements
winget install --id Adobe.Acrobat.Reader.64-bit --source winget --silent --accept-package-agreements --accept-source-agreements

cls
echo ==================================================================
echo         CONFIG DE CONTAS, DESEMPENHO E INICIALIZACAO           
echo ==================================================================
echo.

echo [2/3] Configurando Contas, Otimizacoes Visuais e Inicializacao...

echo [+] Configurando conta Administrador local...
net user administrador /active:yes >nul 2>&1
net user administrator /active:yes >nul 2>&1
net user administrador %SENHAADMIN% >nul 2>&1
net user administrator %SENHAADMIN% >nul 2>&1

:: Garantir que o Administrador tem privilegios totais
net localgroup administradores administrador /add >nul 2>&1
net localgroup administrators administrator /add >nul 2>&1
net localgroup administradores administrator /add >nul 2>&1
net localgroup administrators administrador /add >nul 2>&1

echo [+] Rebaixando conta '%NOMEUSUARIO%' para usuario Padrao...
:: 1. Ativar a conta
net user "%NOMEUSUARIO%" /active:yes >nul 2>&1

:: 2. Adicionar ao grupo de Usuarios comuns (para nao sumir da tela de login)
:: Executa via PowerShell usando SID universal (S-1-5-32-545 = Grupo Usuarios / Users) e via net localgroup
powershell -ExecutionPolicy Bypass -Command "$u = '%NOMEUSUARIO%'.Trim([char]34); try { $grpUsers = (Get-LocalGroup | Where-Object { $_.SID -like 'S-1-5-32-545' }).Name; if ($grpUsers) { Add-LocalGroupMember -Group $grpUsers -Member $u -ErrorAction SilentlyContinue } } catch {}"
net localgroup "Usuários" "%NOMEUSUARIO%" /add >nul 2>&1
net localgroup "Users" "%NOMEUSUARIO%" /add >nul 2>&1
net localgroup "Usuarios" "%NOMEUSUARIO%" /add >nul 2>&1

:: 3. Remover dos Administradores (deixando apenas como usuario padrao)
:: Executa via PowerShell usando SID universal (S-1-5-32-544 = Grupo Administradores) e via net localgroup
powershell -ExecutionPolicy Bypass -Command "$u = '%NOMEUSUARIO%'.Trim([char]34); try { $grpAdmin = (Get-LocalGroup | Where-Object { $_.SID -like 'S-1-5-32-544' }).Name; if ($grpAdmin) { Remove-LocalGroupMember -Group $grpAdmin -Member $u -ErrorAction SilentlyContinue } } catch {}"
net localgroup administradores "%NOMEUSUARIO%" /delete >nul 2>&1
net localgroup administrators "%NOMEUSUARIO%" /delete >nul 2>&1

:: Validacao das permissoes na tela para o operador da TI
powershell -ExecutionPolicy Bypass -Command "$u = '%NOMEUSUARIO%'.Trim([char]34); $adm = (Get-LocalGroupMember -Group (Get-LocalGroup | Where-Object { $_.SID -like 'S-1-5-32-544' }).Name -ErrorAction SilentlyContinue | Where-Object { $_.Name -like ('*' + $u) }); if ($adm) { Write-Host '[-] AVISO: Falha ao desvincular! Usuario ainda esta em Administradores.' -ForegroundColor Red } else { Write-Host '[+] Sucesso: Usuario rebaixado para Padrao.' -ForegroundColor Green }"

:: 4. Garantir que nenhum usuario fique oculto na tela de login
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v dontdisplaylastusername /t REG_DWORD /d 0 /f >nul 2>&1

echo [+] Aplicando configuracoes de otimizacao visual de desempenho (Modo Personalizado)...

:: 1. Configurar defaults globais do sistema em HKLM (desativa todas exceto as 3 solicitadas)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\FontSmoothing" /v DefaultValue /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\ListviewShadow" /v DefaultValue /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\ThumbnailsOrIcon" /v DefaultValue /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\AnimateMinMax" /v DefaultValue /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\ComboBoxAnimation" /v DefaultValue /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\ControlAnimations" /v DefaultValue /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\CursorShadow" /v DefaultValue /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\DragFullWindows" /v DefaultValue /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\DropShadow" /v DefaultValue /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\DWMAeroPeekEnabled" /v DefaultValue /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\ListBoxSmoothScrolling" /v DefaultValue /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\ListviewAlphaSelect" /v DefaultValue /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\MenuAnimation" /v DefaultValue /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\SelectionFade" /v DefaultValue /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\TaskbarAnimations" /v DefaultValue /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\TooltipAnimation" /v DefaultValue /t REG_DWORD /d 0 /f >nul 2>&1

:: 2. Aplicar no usuario atual (HKCU - Administrador)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9012038010000000 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v IconsOnly /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v FontSmoothing /t REG_SZ /d 2 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v FontSmoothingType /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewShadow /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewAlphaSelect /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d 0 /f >nul 2>&1

:: 3. Aplicar em todos os perfis ativos em HKEY_USERS (SIDs de usuarios comuns)
for /f "tokens=*" %%k in ('reg query HKU 2^>nul ^| findstr /r /c:"S-1-5-21-[0-9\-]*$"') do (
    reg add "%%k\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 3 /f >nul 2>&1
    reg add "%%k\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9012038010000000 /f >nul 2>&1
    reg add "%%k\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v IconsOnly /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "%%k\Control Panel\Desktop" /v FontSmoothing /t REG_SZ /d 2 /f >nul 2>&1
    reg add "%%k\Control Panel\Desktop" /v FontSmoothingType /t REG_DWORD /d 2 /f >nul 2>&1
    reg add "%%k\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewShadow /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "%%k\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%k\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "%%k\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewAlphaSelect /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "%%k\Software\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "%%k\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d 0 /f >nul 2>&1
)

:: 4. Aplicar no perfil de novo usuario padrao (C:\Users\Default\NTUSER.DAT)
reg load HKU\DefProfile "C:\Users\Default\NTUSER.DAT" >nul 2>&1
if %errorLevel% equ 0 (
    reg add "HKU\DefProfile\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 3 /f >nul 2>&1
    reg add "HKU\DefProfile\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9012038010000000 /f >nul 2>&1
    reg add "HKU\DefProfile\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v IconsOnly /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKU\DefProfile\Control Panel\Desktop" /v FontSmoothing /t REG_SZ /d 2 /f >nul 2>&1
    reg add "HKU\DefProfile\Control Panel\Desktop" /v FontSmoothingType /t REG_DWORD /d 2 /f >nul 2>&1
    reg add "HKU\DefProfile\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewShadow /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKU\DefProfile\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f >nul 2>&1
    reg add "HKU\DefProfile\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKU\DefProfile\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewAlphaSelect /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKU\DefProfile\Software\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKU\DefProfile\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d 0 /f >nul 2>&1
    reg unload HKU\DefProfile >nul 2>&1
)

:: 5. Aplicar no perfil do colaborador se a pasta de usuario ja existir em C:\Users
if exist "C:\Users\%NOMEUSUARIO%\NTUSER.DAT" (
    reg load HKU\ColabProfile "C:\Users\%NOMEUSUARIO%\NTUSER.DAT" >nul 2>&1
    if %errorLevel% equ 0 (
        reg add "HKU\ColabProfile\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 3 /f >nul 2>&1
        reg add "HKU\ColabProfile\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9012038010000000 /f >nul 2>&1
        reg add "HKU\ColabProfile\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v IconsOnly /t REG_DWORD /d 0 /f >nul 2>&1
        reg add "HKU\ColabProfile\Control Panel\Desktop" /v FontSmoothing /t REG_SZ /d 2 /f >nul 2>&1
        reg add "HKU\ColabProfile\Control Panel\Desktop" /v FontSmoothingType /t REG_DWORD /d 2 /f >nul 2>&1
        reg add "HKU\ColabProfile\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewShadow /t REG_DWORD /d 1 /f >nul 2>&1
        reg add "HKU\ColabProfile\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f >nul 2>&1
        reg add "HKU\ColabProfile\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t REG_DWORD /d 0 /f >nul 2>&1
        reg add "HKU\ColabProfile\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewAlphaSelect /t REG_DWORD /d 0 /f >nul 2>&1
        reg add "HKU\ColabProfile\Software\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 0 /f >nul 2>&1
        reg add "HKU\ColabProfile\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d 0 /f >nul 2>&1
        reg unload HKU\ColabProfile >nul 2>&1
    )
)

echo [+] Detectando nucleos logicos da CPU (NumberOfLogicalProcessors)...
for /f "tokens=*" %%p in ('powershell -NoProfile -Command "(Get-CimInstance Win32_Processor | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum"') do set TOTAL_NUCLEOS=%%p
if "%TOTAL_NUCLEOS%"=="" set TOTAL_NUCLEOS=%NUMBER_OF_PROCESSORS%

echo [+] Total de processadores logicos detectados: %TOTAL_NUCLEOS%
echo [+] Configurando msconfig / bcdedit para inicializacao com %TOTAL_NUCLEOS% nucleos...
bcdedit /set {current} numproc %TOTAL_NUCLEOS% >nul 2>&1
if %errorLevel% equ 0 (
    echo [+] Sucesso: Marcada opcao de %TOTAL_NUCLEOS% processadores no boot!
) else (
    echo [!] Aviso: Nao foi possivel aplicar bcdedit numproc.
)

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

echo [3/3] Instalando GLPI Agent e executando inventario...
set SERVER_URL=https://glpi.estoque.3e.eng.br/

echo [+] Instalando GLPI Agent via Winget...
winget install --id GLPI-Project.GLPI-Agent --source winget --silent --accept-package-agreements --accept-source-agreements --override "/qn SERVER=\"%SERVER_URL%\" QUICKINSTALL=1 /norestart"

if %errorLevel% neq 0 (
    echo [!] Winget retornou codigo diferente de 0. Executando instalador direto como garantia...
    powershell -ExecutionPolicy Bypass -Command ^
      "$url = 'https://github.com/glpi-project/glpi-agent/releases/download/1.21/GLPI-Agent-1.21-x64.msi'; " ^
      "$dest = Join-Path $env:TEMP 'GLPI-Agent.msi'; " ^
      "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; " ^
      "$wc = New-Object System.Net.WebClient; " ^
      "$wc.Headers.Add('User-Agent', 'Mozilla/5.0'); " ^
      "$wc.DownloadFile($url, $dest); " ^
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