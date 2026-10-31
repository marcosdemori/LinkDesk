import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/state_model.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class LinkDeskUpdateService {
  LinkDeskUpdateService._();
  static final LinkDeskUpdateService instance = LinkDeskUpdateService._();

  // Endpoints configurados
  static const String customEndpoint = 'https://connect.linkdesk.io/version.json';
  static const String githubEndpoint =
      'https://api.github.com/repos/marcosdemori/LinkDesk/releases/latest';

  final RxBool hasUpdate = false.obs;
  final RxString latestVersion = ''.obs;
  final RxString currentVersion = ''.obs;
  final RxString downloadUrl = ''.obs;
  final RxString releasePageUrl = ''.obs;
  final RxString changelog = ''.obs;
  final RxBool isChecking = false.obs;
  final RxBool isDownloading = false.obs;
  final RxDouble downloadProgress = 0.0.obs;
  final RxString updateStatus = ''.obs;

  bool _initialized = false;

  void init() {
    if (_initialized) return;
    _initialized = true;
    // Checar atualização 2 segundos após a inicialização
    Timer(const Duration(seconds: 2), () {
      checkForUpdates();
    });
    // Verificação periódica a cada 4 horas
    Timer.periodic(const Duration(hours: 4), (_) {
      checkForUpdates();
    });
  }

  Future<void> checkForUpdates({bool manual = false}) async {
    if (isChecking.value) return;
    isChecking.value = true;
    updateStatus.value = 'Verificando atualizações...';

    try {
      final currentVer = await bind.mainGetVersion();
      currentVersion.value = currentVer;

      bool found = false;

      // 1. Tentar primeiro o endpoint customizado (servidor LinkDesk)
      try {
        final client = http.Client();
        final response = await client
            .get(Uri.parse(customEndpoint))
            .timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          if (data is Map<String, dynamic> && data['version'] != null) {
            final remoteVer = (data['version'] as String).replaceFirst('v', '');
            final isSos = isSosMode();
            final dl = isSos
                ? (data['sos_download_url'] ?? data['download_url'] ?? '')
                : (data['download_url'] ?? '');
            final page = data['url'] ?? 'https://github.com/marcosdemori/LinkDesk/releases';
            final notes = data['changelog'] ?? '';

            if (_isVersionNewer(remoteVer, currentVer)) {
              latestVersion.value = remoteVer;
              downloadUrl.value = dl;
              releasePageUrl.value = page;
              changelog.value = notes;
              hasUpdate.value = true;
              stateGlobal.updateUrl.value = dl.isNotEmpty ? dl : page;
              found = true;
            }
          }
        }
      } catch (e) {
        debugPrint('[LinkDesk Update] Falha no endpoint customizado: $e');
      }

      // 2. Se não encontrou no servidor customizado, buscar no GitHub Releases oficial
      if (!found) {
        try {
          final client = http.Client();
          final response = await client.get(
            Uri.parse(githubEndpoint),
            headers: {'Accept': 'application/vnd.github.v3+json'},
          ).timeout(const Duration(seconds: 6));

          if (response.statusCode == 200) {
            final data = jsonDecode(utf8.decode(response.bodyBytes));
            if (data is Map<String, dynamic>) {
              final tagName = (data['tag_name'] as String? ?? '').replaceFirst('v', '');
              final htmlUrl = data['html_url'] as String? ?? '';
              final body = data['body'] as String? ?? '';
              final assets = data['assets'] as List<dynamic>? ?? [];

              String targetUrl = '';
              final isSos = isSosMode();

              for (var asset in assets) {
                if (asset is Map<String, dynamic>) {
                  final name = (asset['name'] as String? ?? '').toLowerCase();
                  final browserUrl = asset['browser_download_url'] as String? ?? '';
                  if (isSos) {
                    if (name.contains('sos') && name.endsWith('.exe')) {
                      targetUrl = browserUrl;
                      break;
                    }
                  } else {
                    if ((name.contains('install') || name.contains('linkdesk')) &&
                        name.endsWith('.exe')) {
                      targetUrl = browserUrl;
                      break;
                    }
                  }
                }
              }

              if (targetUrl.isEmpty) {
                targetUrl = htmlUrl;
              }

              if (_isVersionNewer(tagName, currentVer)) {
                latestVersion.value = tagName;
                downloadUrl.value = targetUrl;
                releasePageUrl.value = htmlUrl;
                changelog.value = body;
                hasUpdate.value = true;
                stateGlobal.updateUrl.value = targetUrl;
                found = true;
              }
            }
          }
        } catch (e) {
          debugPrint('[LinkDesk Update] Falha no GitHub Releases: $e');
        }
      }

      if (found) {
        updateStatus.value = 'Nova versão v${latestVersion.value} disponível!';
        if (manual) {
          showToast('Nova versão disponível: v${latestVersion.value}');
        }
      } else {
        hasUpdate.value = false;
        updateStatus.value = 'LinkDesk atualizado (v$currentVer)';
        if (manual) {
          showToast('O LinkDesk já está na versão mais recente (v$currentVer).');
        }
      }
    } catch (e) {
      debugPrint('[LinkDesk Update] Erro geral: $e');
      updateStatus.value = 'Falha ao verificar atualização';
    } finally {
      isChecking.value = false;
    }
  }

  bool _isVersionNewer(String remote, String current) {
    if (remote.isEmpty || current.isEmpty) return false;
    final rParts = remote.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final cParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final maxLen = rParts.length > cParts.length ? rParts.length : cParts.length;

    for (int i = 0; i < maxLen; i++) {
      final r = i < rParts.length ? rParts[i] : 0;
      final c = i < cParts.length ? cParts[i] : 0;
      if (r > c) return true;
      if (r < c) return false;
    }
    return false;
  }

  void showUpdateModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? MyTheme.darkCard : Colors.white;
    final textMain = isDark ? const Color(0xFFEEF1F5) : MyTheme.dark;
    final textMuted = isDark ? MyTheme.darkGray : const Color(0xFF6B7280);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: MyTheme.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.rocket_launch_rounded,
                  color: MyTheme.accent, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nova Versão do LinkDesk',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Versão Atual: ${currentVersion.value}  ➔  Nova: ${latestVersion.value}',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (changelog.value.isNotEmpty) ...[
                Text(
                  'Novidades e Correções:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textMain,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF181B21) : MyTheme.grayBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? MyTheme.darkLine : MyTheme.lightLine,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      changelog.value,
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Obx(() {
                if (isDownloading.value) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Baixando atualização...',
                              style: TextStyle(fontSize: 12, color: textMain)),
                          Text(
                            '${(downloadProgress.value * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: MyTheme.accent),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: downloadProgress.value,
                        backgroundColor: MyTheme.accent.withOpacity(0.15),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(MyTheme.accent),
                      ),
                    ],
                  );
                }
                return Text(
                  'Deseja atualizar agora para aproveitar melhorias de performance e segurança?',
                  style: TextStyle(fontSize: 13, color: textMuted),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Mais Tarde', style: TextStyle(color: textMuted)),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.open_in_browser_rounded, size: 16),
            label: const Text('Ver no GitHub'),
            style: OutlinedButton.styleFrom(
              foregroundColor: textMain,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              final url = releasePageUrl.value.isNotEmpty
                  ? releasePageUrl.value
                  : 'https://github.com/marcosdemori/LinkDesk/releases';
              launchUrl(Uri.parse(url));
            },
          ),
          Obx(() {
            return ElevatedButton.icon(
              icon: isDownloading.value
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download_rounded, size: 16),
              label: Text(isDownloading.value ? 'Baixando...' : 'Atualizar Agora'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyTheme.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: isDownloading.value
                  ? null
                  : () {
                      _downloadAndExecuteUpdate(ctx);
                    },
            );
          }),
        ],
      ),
    );
  }

  Future<void> _downloadAndExecuteUpdate(BuildContext ctx) async {
    final url = downloadUrl.value;
    if (url.isEmpty || !url.startsWith('http')) {
      launchUrl(Uri.parse(releasePageUrl.value));
      Navigator.of(ctx).pop();
      return;
    }

    // Se a URL for apenas uma página web e não arquivo executável, abrir no navegador
    if (!url.toLowerCase().endsWith('.exe')) {
      launchUrl(Uri.parse(url));
      Navigator.of(ctx).pop();
      return;
    }

    try {
      isDownloading.value = true;
      downloadProgress.value = 0.0;

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      final tempDir = Directory.systemTemp.path;
      final fileName = isSosMode() ? 'LinkDesk-SOS-Update.exe' : 'LinkDesk-Update.exe';
      final saveFile = File('$tempDir\\$fileName');

      final sink = saveFile.openWrite();
      int received = 0;

      await for (var chunk in response.stream) {
        received += chunk.length;
        sink.add(chunk);
        if (contentLength > 0) {
          downloadProgress.value = received / contentLength;
        }
      }
      await sink.close();

      isDownloading.value = false;
      Navigator.of(ctx).pop();

      // Executar o novo instalador/portátil em processo separado
      showToast('Iniciando atualização...');
      await Process.start(saveFile.path, ['--update'], mode: ProcessStartMode.detached);
      exit(0);
    } catch (e) {
      isDownloading.value = false;
      debugPrint('[LinkDesk Update] Falha no download direto: $e');
      showToast('Falha no download direto. Abrindo página de download...');
      launchUrl(Uri.parse(url));
      Navigator.of(ctx).pop();
    }
  }
}

