Set-Location $PSScriptRoot

$ambiente = Read-Host "Escolha o tipo de compilação (d=Debug ou r=Release)"
$isBuildRunner = Read-Host "Deseja rodar o build_runner? (y = sim / n = não)"

# Validação do arquivo .env e credenciais de compilação
$envPath = Join-Path $PSScriptRoot ".env"
if (!(Test-Path $envPath)) {
    Write-Host "Erro: Arquivo .env não encontrado na raiz do projeto ($envPath)!" -ForegroundColor Red
    Write-Host "Crie o arquivo .env a partir de .env.example e configure as variáveis antes de compilar." -ForegroundColor Yellow
    exit 1
}

$envContent = Get-Content -Path $envPath -Raw
if ($envContent -notmatch '(?m)^GOOGLE_SERVER_CLIENT_ID=\s*([^\s#]+)') {
    Write-Host "Atenção: A variável GOOGLE_SERVER_CLIENT_ID não está preenchida no arquivo .env." -ForegroundColor Yellow
    Write-Host "A integração com o Google Drive ficará desabilitada nesta compilação." -ForegroundColor Yellow
    $prosseguir = Read-Host "Deseja continuar mesmo sem GOOGLE_SERVER_CLIENT_ID? (y = sim / n = não)"
    if ($prosseguir -ne "y") {
        Write-Host "Build abortado pelo usuário." -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host "Arquivo .env verificado: GOOGLE_SERVER_CLIENT_ID presente." -ForegroundColor Green
}

# Extrai a versão do pubspec.yaml para o pipeline de build e controle de versão (RF01)
$pubspecPath = Join-Path $PSScriptRoot "pubspec.yaml"
if (Test-Path $pubspecPath) {
    $pubspec = Get-Content -Path $pubspecPath -Raw
    if ($pubspec -match '(?m)^version:\s*([^\s]+)') {
        $appVersion = $Matches[1]
    }
    else {
        Write-Host "Erro ao extrair a versão do pubspec.yaml" -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host "Erro: pubspec.yaml não encontrado" -ForegroundColor Red
    exit 1
}
Write-Host "Versão do aplicativo detectada no pubspec.yaml: $appVersion" -ForegroundColor Cyan

# Por default, o build é preparado para ambiente debug
$origem = "./build/app/outputs/flutter-apk/app-debug.apk"
$nomeArquivoFinal = "staging_mylink_$appVersion.apk"

# Prepara a build para o ambiente escolhido
if ($ambiente -eq "d") {
    Write-Host "Iniciando limpeza e build do APK ($appVersion) [Debug]..." -ForegroundColor Cyan
    flutter clean
    flutter pub get
    if ($isBuildRunner -eq "y") {
        dart run build_runner build --delete-conflicting-outputs
    }
    flutter build apk --debug --dart-define-from-file=.env
}
elseif ($ambiente -eq "r") {
    Write-Host "Iniciando limpeza e build do appbundle ($appVersion) [Release]..." -ForegroundColor Cyan
    flutter clean
    flutter pub get
    if ($isBuildRunner -eq "y") {
        dart run build_runner build --delete-conflicting-outputs
    }
    flutter build appbundle --release --obfuscate --split-debug-info=key/obfuscate --dart-define-from-file=.env
    
    $origem = "./build/app/outputs/bundle/release/app-release.aab"
    $nomeArquivoFinal = "mylink_$appVersion.aab"
}
else {
    Write-Host "Tipo de compilação inválido. Digite 'd' ou 'r'." -ForegroundColor Red
    exit 1
}

# Verifica se o build foi bem-sucedido antes de mover
if ($LASTEXITCODE -eq 0) {
    
    # Define os novos caminhos
    $diretorioDestino = "C:\TEMP\bundle"
    $caminhoCompletoDestino = Join-Path $diretorioDestino $nomeArquivoFinal

    # Verifica e cria o diretório C:\TEMP\bundle caso não exista
    if (!(Test-Path $diretorioDestino)) {
        Write-Host "Criando diretório $diretorioDestino..." -ForegroundColor Gray
        New-Item -ItemType Directory -Path $diretorioDestino -Force | Out-Null
    }

    # 3. Move o arquivo para C:/TEMP/bundle/
    Write-Host "Movendo arquivo para $caminhoCompletoDestino..." -ForegroundColor Cyan
    Move-Item -Path $origem -Destination $caminhoCompletoDestino -Force

    Write-Host "Processo concluído com sucesso!" -ForegroundColor Green

    # Abre o diretório no Windows Explorer
    Write-Host "Abrindo pasta de destino..." -ForegroundColor Gray
    explorer.exe $diretorioDestino

}
else {
    Write-Host "Erro durante o build do Flutter. O arquivo não foi movido." -ForegroundColor Red
}