// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'MyLink';

  @override
  String get appSlogan => 'Seus links, sempre à mão';

  @override
  String get startupError =>
      'Não foi possível ler os dados salvos. Nenhum dado foi sobrescrito. Feche o app e verifique o armazenamento antes de tentar novamente.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get save => 'Salvar';

  @override
  String get saving => 'Salvando…';

  @override
  String get add => 'Adicionar';

  @override
  String get close => 'Fechar';

  @override
  String get edit => 'Editar';

  @override
  String get delete => 'Excluir';

  @override
  String get generate => 'Gerar';

  @override
  String get tryAgain => 'Tentar novamente';

  @override
  String get unexpectedError => 'Não foi possível concluir. Tente novamente.';

  @override
  String get welcomeTitle => 'Seus links, organizados';

  @override
  String get welcomeSubtitle =>
      'Salve URLs, crie categorias, marque favoritos e leve seu backup CSV com você.';

  @override
  String get welcomeGetStarted => 'Começar';

  @override
  String get welcomeFooter =>
      'Feito para simplificar a forma como você guarda a web.';

  @override
  String get welcomeSaveError => 'Não foi possível salvar. Tente novamente.';

  @override
  String get drawerAddLink => 'Adicionar link';

  @override
  String get drawerScanQr => 'Ler QR Code';

  @override
  String get drawerGenerateQr => 'Gerar QR Code';

  @override
  String get drawerExportCsv => 'Exportar CSV';

  @override
  String get drawerImportCsv => 'Importar CSV';

  @override
  String get drawerImportingCsv => 'Importando…';

  @override
  String get drawerGoogleDrive => 'Google Drive';

  @override
  String get drawerGoogleDriveSubtitle => 'Backup e restauração';

  @override
  String get drawerSettings => 'Configurações';

  @override
  String get tabHome => 'Home';

  @override
  String get tabCategory => 'Category';

  @override
  String get tabTimeLine => 'TimeLine';

  @override
  String get tabFavorite => 'Favorite';

  @override
  String get sortNewest => 'New First';

  @override
  String get sortOldest => 'Old First';

  @override
  String get sortAz => 'A to Z';

  @override
  String get sortZa => 'Z to A';

  @override
  String get sortTooltip => 'Ordenar links';

  @override
  String get searchHint => 'Buscar título, URL ou categoria…';

  @override
  String get emptyNoResults => 'Nenhum resultado para a busca.';

  @override
  String get emptyFavorites => 'Nenhum link favorito.';

  @override
  String get emptyHome => 'Você ainda não adicionou URLs aqui.';

  @override
  String get emptyCategories => 'Nenhuma categoria encontrada.';

  @override
  String get createCategory => 'Criar categoria';

  @override
  String get addUrl => 'Adicionar URL';

  @override
  String linksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count links',
      one: '1 link',
    );
    return '$_temp0';
  }

  @override
  String get backToCategories => 'Voltar às categorias';

  @override
  String get linkOptionsTooltip => 'Opções do link';

  @override
  String get markFavoriteTooltip => 'Marcar favorito';

  @override
  String get removeFavoriteTooltip => 'Remover dos favoritos';

  @override
  String get copyUrl => 'Copiar URL';

  @override
  String get shareUrl => 'Compartilhar URL';

  @override
  String get openInExternalBrowser => 'Abrir no navegador externo';

  @override
  String get deleteLinkConfirmTitle => 'Excluir link?';

  @override
  String get deleteLinkConfirmMessage => 'Esta ação não pode ser desfeita.';

  @override
  String get linkCopied => 'Link copiado.';

  @override
  String get dialogAddUrlTitle => 'Adicionar URL';

  @override
  String get dialogEditUrlTitle => 'Editar link';

  @override
  String get inputTitle => 'Título';

  @override
  String get inputUrl => 'URL';

  @override
  String get inputCategory => 'Categoria';

  @override
  String get pasteLinkTooltip => 'Colar link';

  @override
  String get newCategory => 'Nova categoria';

  @override
  String get selectCategoryError => 'Crie ou selecione uma categoria.';

  @override
  String get saveDataError => 'Falha ao salvar os dados.';

  @override
  String get dialogNewCategoryTitle => 'Nova categoria';

  @override
  String get inputName => 'Nome';

  @override
  String deleteCategoryConfirmTitle(String category) {
    return 'Excluir $category?';
  }

  @override
  String deleteCategoryConfirmMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count links desta categoria também serão excluídos.',
      one: '1 link desta categoria também será excluído.',
    );
    return '$_temp0';
  }

  @override
  String get deleteCategoryTooltip => 'Excluir categoria';

  @override
  String get shareReceiveError =>
      'Não foi possível receber o compartilhamento.';

  @override
  String get shareReadError => 'Não foi possível ler o link recebido.';

  @override
  String get noValidUrlFound => 'Nenhuma URL HTTP/HTTPS encontrada.';

  @override
  String get qrNoHttpUrl => 'O QR Code não contém uma URL HTTP/HTTPS.';

  @override
  String get qrCode => 'QR Code';

  @override
  String get generateQrCode => 'Gerar QR Code';

  @override
  String get noLinksToExport => 'Nenhum link disponível para exportar.';

  @override
  String get exportLinksDialogTitle => 'Exportar links';

  @override
  String get csvExported => 'CSV exportado.';

  @override
  String get importCsvConfirmTitle => 'Importar CSV?';

  @override
  String get importCsvConfirmMessage =>
      'Os links serão adicionados à biblioteca. Importar o mesmo arquivo novamente pode criar duplicatas.';

  @override
  String get importSuccess => 'Importação concluída.';

  @override
  String get fileReadError => 'Não foi possível ler o arquivo.';

  @override
  String csvSizeLimitError(int maxSizeMb) {
    return 'O CSV deve ter no máximo $maxSizeMb MB.';
  }

  @override
  String get openBrowserError => 'Não foi possível abrir o navegador.';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get sectionAppearance => 'Aparência';

  @override
  String get themeAppTitle => 'Tema do Aplicativo';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get sectionInformation => 'Informações';

  @override
  String get aboutAppTitle => 'Sobre o Aplicativo';

  @override
  String get aboutAppSubtitle => 'Versão, desenvolvedor e links úteis.';

  @override
  String get aboutTitle => 'Sobre';

  @override
  String get sectionTechnicalDetails => 'Detalhes Técnicos';

  @override
  String get labelVersion => 'Versão';

  @override
  String get labelBuild => 'Build';

  @override
  String get labelDeveloper => 'Desenvolvedor';

  @override
  String get sectionUsefulLinks => 'Links Úteis';

  @override
  String get privacyPolicy => 'Política de Privacidade';

  @override
  String get privacyPolicyError =>
      'Não foi possível abrir a política de privacidade.';

  @override
  String get scanQrTitle => 'Ler QR Code';

  @override
  String get cameraPermissionError =>
      'Permita o acesso à câmera nas configurações do dispositivo e tente novamente.';

  @override
  String get cameraUnavailableError =>
      'Câmera indisponível. Você pode adicionar o link manualmente.';

  @override
  String get reloadTooltip => 'Recarregar';

  @override
  String get openExternalTooltip => 'Abrir externamente';

  @override
  String get pageLoadError => 'Não foi possível carregar a página.';

  @override
  String get googleDriveTitle => 'Google Drive';

  @override
  String get driveConfigMissingTitle => 'Configuração OAuth Ausente';

  @override
  String get driveConfigMissingMessage =>
      'A variável GOOGLE_SERVER_CLIENT_ID não foi informada no arquivo .env. Crie o arquivo a partir de .env.example para habilitar a conexão.';

  @override
  String get closeMessageTooltip => 'Fechar mensagem';

  @override
  String get connectDriveTitle => 'Conectar ao Google Drive';

  @override
  String get connectDriveMessage =>
      'Conecte sua conta Google para autorizar o acesso aos arquivos do Google Drive gerenciados pelo MyLink. Seus dados locais permanecem salvos no dispositivo.';

  @override
  String get connectGoogleAccount => 'Conectar Conta Google';

  @override
  String get connecting => 'Conectando…';

  @override
  String get driveAuthorized => 'Drive Autorizado';

  @override
  String get driveNotAuthorized => 'Drive Não Autorizado';

  @override
  String get sectionAuthAndAccess => 'Autorização e Acesso';

  @override
  String get driveAuthorizedScopeInfo =>
      'O aplicativo tem autorização para gerenciar apenas os arquivos criados ou abertos por ele (escopo drive.file).';

  @override
  String get driveNotAuthorizedScopeInfo =>
      'Para que o aplicativo possa acessar arquivos no Drive, você precisa autorizar a permissão drive.file.';

  @override
  String get authorizeDrive => 'Autorizar Drive';

  @override
  String get authorizing => 'Autorizando…';

  @override
  String get verifyApiAccess => 'Verificar Acesso à API';

  @override
  String get verifying => 'Verificando…';

  @override
  String get sectionDriveBackup => 'Backup no Google Drive';

  @override
  String get refreshInfoTooltip => 'Atualizar informações';

  @override
  String get backupDescription =>
      'Salve todos os seus links e categorias no Google Drive ou restaure seus dados neste aparelho.';

  @override
  String get checkingBackup => 'Consultando backup no Google Drive…';

  @override
  String get backupAvailableCloud => 'Backup disponível na nuvem';

  @override
  String lastUploaded(String date) {
    return 'Último envio: $date';
  }

  @override
  String get noBackupFound => 'Nenhum backup encontrado no Google Drive.';

  @override
  String get noLinksToBackup => 'Nenhum link disponível para backup.';

  @override
  String get backupNow => 'Fazer Backup Agora';

  @override
  String get backingUp => 'Enviando…';

  @override
  String get restoreBackup => 'Restaurar Backup';

  @override
  String get restoring => 'Restaurando…';

  @override
  String get restoreBackupConfirmTitle => 'Restaurar Backup?';

  @override
  String get restoreBackupConfirmMessage =>
      'Os links e categorias salvos no Google Drive serão adicionados à sua biblioteca neste dispositivo.';

  @override
  String get signOut => 'Encerrar sessão';

  @override
  String get signOutSubtitle => 'Desconecta a conta Google deste app.';

  @override
  String get signOutConfirmTitle => 'Encerrar sessão?';

  @override
  String get signOutConfirmMessage =>
      'Sua conta Google será desconectada do aplicativo. Seus links salvos localmente não serão alterados.';

  @override
  String get revokeAccess => 'Revogar acesso Google';

  @override
  String get revokeAccessSubtitle =>
      'Revoga as permissões concedidas pela sua conta Google a este aplicativo.';

  @override
  String get revokeAccessConfirmTitle => 'Revogar acesso?';

  @override
  String get revokeAccessConfirmMessage =>
      'Esta ação revoga todas as autorizações do aplicativo na sua conta Google. Nenhum link local ou arquivo do Drive será apagado.';

  @override
  String get driveVerifiedStatus => 'Verificado';
}
