@echo off

title Configuração Automática de Notebooks - TI 3E

::Senha Padrão da TI (Altere entre as aspas abaixo)
set SENHAADMIN=3ece@TI0897,

:: Verificar privilégio de Administração[cite:1]
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
set /p NOMEUSUARIO="Digite o NOME DO USUARIO local que sera rebaixado para Padrao:"

echo.
echo [+] Informacoes registradas. Iniciado automacao...
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
powershell -Command "Install-Module -Name PSWindowsUpdate -Force -Confirm:$false -Scope CurrentUser; Import-Module PSWindowsUpdate; Get-WindowsUpdate -AcceptAll -Install -AutoReboot:$false"


cls
echo ==================================================================
echo         CONFIG DE CONTAS E DESEMPENHO VISUAL           
echo ==================================================================
echo.

echo [3/4] Configurando Contas e Otimizacoes Visuais...
:: Ativar Administrador local e aplicar a senha embutida da TI

net user administrador /active:yes
net user administrador %SENHAADMIN%
net user administrador /active:yes >nul 2>&1
net user administrador %SENHAADMIN% >nul 2>&1

::Rebaixar conta local para padrao
net localgroup administradores "%NOMEUSUARIO" delete >nul 2>&1

:: Otimização Visual (Mantendo miniaturas, fontes arredondadas e sombras)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 3 /f >nul
reg add "HKCU\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9012038010000000 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v IconsOnly /t REG_DWORD /d 0 /f >nul

cls
echo ===================================
echo           GLPI AGENT           
echo ===================================
echo.

echo [4/4] Instalando GLPI Agent e executando inventario...
set GLPI_URL=https://github.com/glpi-project/glpi-agent/releases/download/1.10/GLPI-Agent-1.10-x64.msi
set MSI_PATH=%TEMP%\GLPI-Agent.msi
set SERVER_URL=https://glpi.estoque.3e.eng.br/

powershell -Command "Install-Module -Name PSWindowsUpdate -Force -Confirm:$false -Scope CurrentUser; Import-Module PSWindowsUpdate -Force; Get-WindowsUpdate -AcceptAll -Install -AutoReboot:$false"
msiexec /i "%MSI_PATH%" /qn SERVER="%SERVER_URL%" QUICKINSTALL=1 /norestart

timeout /t 10 >nul
powershell -Command "try { Invoke-WebRequest -Uri 'http://127.0.0.1:62354/now' -UseBasicParsing | Out-Null; Write-Host 'Inventario enviado com sucesso!' } catch { Write-Host 'Sincronizacao pendente pos-reinicio.' }"

echo.
echo ==================================================================
echo   CONFIGURACAO CONCLUIDA! REINICIANDO EM 10 SEGUNDOS...
echo ==================================================================
timeout /t 10
shutdown /r /t 0 /f
