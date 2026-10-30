import re

def patch():
    path = r'c:\Projetos\acesso-remoto\client\flutter\lib\desktop\pages\desktop_setting_page.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Replace service()
    old_service = """  Widget service() {
    if (bind.isOutgoingOnly()) {
      return const Offstage();
    }

    final hideStopService =
        bind.mainGetBuildinOption(key: kOptionHideStopService) == 'Y';

    return Obx(() {
      if (hideStopService && !serviceStop.value) {
        return const Offstage();
      }

      return _Card(title: 'Service', children: [
        _Button(serviceStop.value ? 'Start' : 'Stop', () {
          () async {
            serviceBtnEnabled.value = false;
            await start_service(serviceStop.value);
            // enable the button after 1 second
            Future.delayed(const Duration(seconds: 1), () {
              serviceBtnEnabled.value = true;
            });
          }();
        }, enabled: serviceBtnEnabled.value)
      ]);
    });
  }"""

    new_service = """  Widget service() {
    if (bind.isOutgoingOnly()) {
      return const Offstage();
    }

    final hideStopService =
        bind.mainGetBuildinOption(key: kOptionHideStopService) == 'Y';

    return Obx(() {
      if (hideStopService && !serviceStop.value) {
        return const Offstage();
      }

      return _Card(
        title: 'Serviço em Segundo Plano',
        title_suffix: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: serviceStop.value
                  ? Colors.amber.withOpacity(0.15)
                  : Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: serviceStop.value
                    ? Colors.amber.withOpacity(0.5)
                    : Colors.green.withOpacity(0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: serviceStop.value ? Colors.amber : Colors.green,
                ),
                const SizedBox(width: 6),
                Text(
                  serviceStop.value ? 'Pausado' : 'Em Execução',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: serviceStop.value ? Colors.amber : Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
        children: [
          Text(
            'Permite conexões de entrada com inicialização automática do LinkDesk junto ao Windows.',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ).marginOnly(left: 10, bottom: 8),
          _Button(serviceStop.value ? 'Iniciar Serviço' : 'Parar Serviço', () {
            () async {
              serviceBtnEnabled.value = false;
              await start_service(serviceStop.value);
              Future.delayed(const Duration(seconds: 1), () {
                serviceBtnEnabled.value = true;
              });
            }();
          }, enabled: serviceBtnEnabled.value)
        ],
      );
    });
  }"""

    if old_service in content:
        content = content.replace(old_service, new_service)
        print("[OK] Replaced service()")

    # 2. Update other() to split into organized cards
    start_idx = content.find('Widget other() {')
    end_pattern = "return _Card(title: 'Other', children: children);"
    end_idx = content.find(end_pattern, start_idx) + len(end_pattern)

    new_other = """Widget other() {
    final incomingOnly = bind.isIncomingOnly();
    final outgoingOnly = bind.isOutgoingOnly();
    final showAutoUpdate = (isWindows && bind.mainIsInstalled()) ||
    (isMacOS && bind.mainIsInstalled() && bind.mainIsInstalledDaemon(prompt: false) && !bind.isCustomClient());

    final uiChildren = <Widget>[
      if (!isWeb && !incomingOnly)
        _OptionCheckBox(context, 'Confirm before closing multiple tabs',
            kOptionEnableConfirmClosingTabs,
            isServer: false),
      if (!isWeb && !incomingOnly)
        _OptionCheckBox(
          context,
          'Open connection in new tab',
          kOptionOpenNewConnInTabs,
          isServer: false,
        ),
      if (!incomingOnly)
        _OptionCheckBox(
          context,
          'allow-remote-toolbar-docking-any-edge',
          kOptionAllowMultiEdgeToolbarDock,
          isServer: false,
          update: (_) {
            reloadAllWindows();
          },
        ),
      if (!incomingOnly)
        _OptionCheckBox(
          context,
          'Show monitor switch button on the main toolbar',
          kOptionAllowMonitorSwitchMainToolbar,
          isServer: false,
          update: (enabled) async {
            if (!enabled) {
              await mainSetLocalBoolOption(
                  kOptionAllowMonitorSwitchMinToolbar, false);
            }
            if (mounted) setState(() {});
            reloadAllWindows();
            if (enabled) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final ctx = _minToolbarOptionKey.currentContext;
                if (ctx != null) {
                  Scrollable.ensureVisible(
                    ctx,
                    alignment: 0.5,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  );
                }
              });
            }
          },
        ),
      if (mainGetLocalBoolOptionSync(kOptionAllowMonitorSwitchMainToolbar))
        KeyedSubtree(
          key: _minToolbarOptionKey,
          child: _OptionCheckBox(
            context,
            'Show on the minimized toolbar',
            kOptionAllowMonitorSwitchMinToolbar,
            isServer: false,
            update: (_) {
              reloadAllWindows();
            },
          ).marginOnly(left: _kCheckBoxLeftMargin * 3),
        ),
      if (!isWeb && !incomingOnly)
        Tooltip(
          message: translate('sync-clipboard-between-sessions-tip'),
          child: _OptionCheckBox(
            context,
            'Sync clipboard between sessions',
            kOptionAllowSyncClipboardBetweenSessions,
            isServer: false,
          ),
        ),
      if (!bind.isIncomingOnly())
        _OptionCheckBox(
          context,
          'keep-awake-during-outgoing-sessions-label',
          kOptionKeepAwakeDuringOutgoingSessions,
          isServer: false,
        ),
      if (!bind.isDisableAccount())
        _OptionCheckBox(
          context,
          'note-at-conn-end-tip',
          kOptionAllowAskForNoteAtEndOfConnection,
          isServer: false,
          optSetter: (key, value) async {
            if (value && !gFFI.userModel.isLogin) {
              final res = await loginDialog();
              if (res != true) return;
            }
            await mainSetLocalBoolOption(key, value);
          },
        ),
    ];

    final perfChildren = <Widget>[
      if (!isWeb && !outgoingOnly)
        _OptionCheckBox(context, 'Adaptive bitrate', kOptionEnableAbr),
      if (!isWeb) wallpaper(),
      if (isWindows && !outgoingOnly)
        _OptionCheckBox(
          context,
          'Capture screen using DirectX',
          kOptionDirectxCapture,
        ),
      if (isWindows && !incomingOnly)
        Tooltip(
          message: translate('d3d_render_tip'),
          child: _OptionCheckBox(
            context,
            'Use D3D rendering',
            kOptionD3DRender,
            isServer: false,
          ),
        ),
      if (!isWeb && !incomingOnly)
        Tooltip(
          message: translate('texture_render_tip'),
          child: _OptionCheckBox(
            context,
            'Use texture rendering',
            kOptionTextureRender,
            optGetter: bind.mainGetUseTextureRender,
            optSetter: (k, v) async =>
                await bind.mainSetLocalOption(key: k, value: v ? 'Y' : 'N'),
          ),
        ),
      if (isLinux && !incomingOnly)
        Tooltip(
          message: translate('software_render_tip'),
          child: _OptionCheckBox(
            context,
            'Always use software rendering',
            kOptionAllowAlwaysSoftwareRender,
          ),
        ),
    ];

    final netChildren = <Widget>[
      if (!isWeb && !incomingOnly) ...[
        _OptionCheckBox(
          context,
          'Enable UDP hole punching',
          kOptionEnableUdpPunch,
          isServer: false,
        ),
        _OptionCheckBox(
          context,
          'Enable TCP hole punching',
          kOptionEnableTcpPunch,
          isServer: false,
        ),
        _OptionCheckBox(
          context,
          'Enable IPv6 P2P connection',
          kOptionEnableIpv6Punch,
          isServer: false,
        ),
        Tooltip(
          message: translate('port-forward-mux-tip'),
          child: _OptionCheckBox(
            context,
            'Reuse one connection for port forwarding',
            kOptionEnablePortForwardMux,
            isServer: false,
          ),
        ),
      ],
      if (!incomingOnly) ...webrtcOptions(context),
      if (!isWeb && !bind.isCustomClient())
        _OptionCheckBox(
          context,
          'Check for software update on startup',
          kOptionEnableCheckUpdate,
          isServer: false,
        ),
      if (showAutoUpdate)
        _OptionCheckBox(
          context,
          'Auto update',
          kOptionAllowAutoUpdate,
          isServer: true,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Card(title: 'Interface e Usabilidade', children: uiChildren),
        _Card(title: 'Desempenho e Aceleracao de Video', children: perfChildren),
        _Card(title: 'Conexao Direta P2P e Rede', children: netChildren),
      ],
    );"""

    if start_idx != -1 and end_idx != -1:
        content = content[:start_idx] + new_other + content[end_idx:]
        print("[OK] Replaced other()")

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("[OK] Finished patching desktop_setting_page.dart!")

if __name__ == '__main__':
    patch()
