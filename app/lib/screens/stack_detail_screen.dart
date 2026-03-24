import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/stacks_provider.dart';
import '../services/websocket_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class StackDetailScreen extends StatefulWidget {
  final int stackId;

  const StackDetailScreen({super.key, required this.stackId});

  @override
  State<StackDetailScreen> createState() => _StackDetailScreenState();
}

class _StackDetailScreenState extends State<StackDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // ── WebSocket ─────────────────────────────────────────────────────────────
  final _ws = WebSocketService();
  final List<_LogEntry> _deployLogs = [];
  StreamSubscription? _wsSub;

  // ── Stack data ────────────────────────────────────────────────────────────
  Map<String, dynamic> _stack = {};
  bool _isLoading = true;

  // ── Env editor ────────────────────────────────────────────────────────────
  final Map<String, TextEditingController> _envControllers = {};
  bool _isSavingEnv = false;

  // ── Logs tab ──────────────────────────────────────────────────────────────
  String _staticLogs = '';
  bool _isLoadingLogs = false;

  final _api = ApiService();
  final _logsScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 2 && _staticLogs.isEmpty) {
        _loadStaticLogs();
      }
    });
    _loadStack();
    _connectWs();
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _ws.disconnect();
    _tabController.dispose();
    _logsScrollCtrl.dispose();
    for (final c in _envControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadStack() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getStack(widget.stackId);
      setState(() {
        _stack = data;
        _buildEnvControllers(
            Map<String, String>.from((data['env_vars'] as Map? ?? {})
                .map((k, v) => MapEntry(k.toString(), v.toString()))));
      });
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  void _buildEnvControllers(Map<String, String> vars) {
    for (final c in _envControllers.values) {
      c.dispose();
    }
    _envControllers.clear();
    for (final e in vars.entries) {
      _envControllers[e.key] = TextEditingController(text: e.value);
    }
  }

  Future<void> _connectWs() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    _ws.connect('/ws/deploy/${widget.stackId}/?token=$token');
    _wsSub = _ws.stream?.listen((raw) {
      if (!mounted) return;
      try {
        final msg = jsonDecode(raw as String) as Map<String, dynamic>;
        final type = msg['type'] as String? ?? '';
        if (type == 'log') {
          setState(() => _deployLogs.add(_LogEntry(
                message: msg['message'] as String? ?? '',
                level: msg['level'] as String? ?? 'info',
              )));
          _scrollLogsToBottom();
        } else if (type == 'status') {
          setState(() {
            _stack = Map.from(_stack)
              ..['status'] = msg['status']
              ..['status_message'] = msg['message'];
          });
          // Also update the provider list
          context
              .read<StacksProvider>()
              .refreshStack(widget.stackId);
        }
      } catch (_) {}
    });
  }

  void _scrollLogsToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logsScrollCtrl.hasClients) {
        _logsScrollCtrl.animateTo(
          _logsScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _loadStaticLogs() async {
    setState(() => _isLoadingLogs = true);
    _staticLogs = await context.read<StacksProvider>().fetchLogs(widget.stackId);
    setState(() => _isLoadingLogs = false);
  }

  Future<void> _deploy() async {
    setState(() => _deployLogs.clear());
    _tabController.animateTo(0); // Switch to deploy log tab
    await context.read<StacksProvider>().deployStack(widget.stackId);
  }

  Future<void> _action(String action) async {
    await context.read<StacksProvider>().stackAction(widget.stackId, action);
    await _loadStack();
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Supprimer ce stack ?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
            'Cette action supprimera les containers et les données associées.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.accentRed),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<StacksProvider>().deleteStack(widget.stackId);
      Navigator.pop(context);
    }
  }

  Future<void> _saveEnv() async {
    setState(() => _isSavingEnv = true);
    final vars = {
      for (final e in _envControllers.entries) e.key: e.value.text,
    };
    final ok = await context
        .read<StacksProvider>()
        .updateEnv(widget.stackId, vars);
    setState(() => _isSavingEnv = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Variables sauvegardées'
            : 'Erreur lors de la sauvegarde'),
        backgroundColor:
            ok ? AppColors.accentGreen : AppColors.accentRed,
      ));
    }
  }

  void _addEnvVar() {
    showDialog(
      context: context,
      builder: (_) => _AddEnvVarDialog(
        onAdd: (key, value) {
          setState(() {
            _envControllers[key] =
                TextEditingController(text: value);
          });
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
            backgroundColor: AppColors.surface,
            title: const Text('Stack',
                style: TextStyle(color: AppColors.textPrimary))),
        body: const Center(
            child:
                CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    final name = _stack['name'] as String? ?? 'Stack';
    final status = _stack['status'] as String? ?? 'idle';
    final statusMsg = _stack['status_message'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(name,
            style: const TextStyle(color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.delete_outline, color: AppColors.accentRed),
            tooltip: 'Supprimer',
            onPressed: _confirmDelete,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accent,
          tabs: const [
            Tab(text: 'Déploiement'),
            Tab(text: 'Variables'),
            Tab(text: 'Logs'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Status banner ──────────────────────────────────────────────
          _StatusBanner(
              status: status, message: statusMsg),
          // ── Action bar ─────────────────────────────────────────────────
          _ActionBar(
              status: status,
              onDeploy: _deploy,
              onStart: () => _action('start'),
              onStop: () => _action('stop'),
              onRestart: () => _action('restart')),
          // ── Tabs ───────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Deploy log
                _DeployLogTab(
                  logs: _deployLogs,
                  scrollCtrl: _logsScrollCtrl,
                ),
                // Env vars editor
                _EnvVarsTab(
                  controllers: _envControllers,
                  isSaving: _isSavingEnv,
                  onSave: _saveEnv,
                  onAdd: _addEnvVar,
                  onRemove: (key) {
                    setState(() {
                      _envControllers.remove(key)?.dispose();
                    });
                  },
                ),
                // Static logs
                _StaticLogsTab(
                  logs: _staticLogs,
                  isLoading: _isLoadingLogs,
                  onRefresh: _loadStaticLogs,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status banner ────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final String status;
  final String message;

  const _StatusBanner({required this.status, required this.message});

  static const _statusMeta = {
    'running': ("En cours d'exécution", AppColors.accentGreen),
    'error': ('Erreur', AppColors.accentRed),
    'building': ('Construction…', AppColors.accentYellow),
    'cloning': ('Clonage…', AppColors.accentYellow),
    'starting': ('Démarrage…', AppColors.accentYellow),
    'stopped': ('Arrêté', AppColors.textSecondary),
    'idle': ('Inactif', AppColors.textSecondary),
  };

  @override
  Widget build(BuildContext context) {
    final meta = _statusMeta[status];
    final label = meta?.$1 ?? status;
    final color = meta?.$2 ?? AppColors.textSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: color.withOpacity(0.08),
      child: Row(
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
          if (message.isNotEmpty) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Action bar ───────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  final String status;
  final VoidCallback onDeploy;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onRestart;

  const _ActionBar({
    required this.status,
    required this.onDeploy,
    required this.onStart,
    required this.onStop,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final isRunning = status == 'running';
    final isBusy = ['building', 'cloning', 'starting'].contains(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _ActionBtn(
            icon: Icons.rocket_launch_outlined,
            label: 'Redéployer',
            color: AppColors.accent,
            onTap: isBusy ? null : onDeploy,
          ),
          const SizedBox(width: 10),
          if (!isRunning)
            _ActionBtn(
              icon: Icons.play_arrow,
              label: 'Démarrer',
              color: AppColors.accentGreen,
              onTap: isBusy ? null : onStart,
            ),
          if (isRunning)
            _ActionBtn(
              icon: Icons.stop,
              label: 'Arrêter',
              color: AppColors.accentRed,
              onTap: onStop,
            ),
          const SizedBox(width: 10),
          _ActionBtn(
            icon: Icons.restart_alt,
            label: 'Redémarrer',
            color: AppColors.accentYellow,
            onTap: isBusy ? null : onRestart,
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5)),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// ─── Deploy log tab ───────────────────────────────────────────────────────────

class _LogEntry {
  final String message;
  final String level;
  _LogEntry({required this.message, required this.level});
}

class _DeployLogTab extends StatelessWidget {
  final List<_LogEntry> logs;
  final ScrollController scrollCtrl;

  const _DeployLogTab({required this.logs, required this.scrollCtrl});

  static const _levelColors = {
    'error': AppColors.accentRed,
    'warning': AppColors.accentYellow,
    'success': AppColors.accentGreen,
    'info': AppColors.textPrimary,
  };

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 48, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text("Aucun log de déploiement",
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 15)),
            SizedBox(height: 6),
            Text("Cliquez sur Redéployer pour commencer.",
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollCtrl,
      padding: const EdgeInsets.all(12),
      itemCount: logs.length,
      itemBuilder: (_, i) {
        final entry = logs[i];
        final color = _levelColors[entry.level] ?? AppColors.textPrimary;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Text(
            entry.message,
            style: TextStyle(
                color: color,
                fontSize: 12,
                fontFamily: 'monospace'),
          ),
        );
      },
    );
  }
}

// ─── Env vars tab ─────────────────────────────────────────────────────────────

class _EnvVarsTab extends StatelessWidget {
  final Map<String, TextEditingController> controllers;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  const _EnvVarsTab({
    required this.controllers,
    required this.isSaving,
    required this.onSave,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              const Text("Variables d'environnement",
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8)),
              const Spacer(),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Ajouter'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.accent),
              ),
            ],
          ),
        ),
        if (controllers.isEmpty)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_outlined,
                      size: 48, color: AppColors.textSecondary),
                  SizedBox(height: 10),
                  Text("Aucune variable définie",
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14)),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16),
              children: controllers.entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(e.key,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontFamily: 'monospace')),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: e.value,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontFamily: 'monospace'),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                    color: AppColors.border)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                    color: AppColors.border)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                    color: AppColors.accent)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.close,
                            size: 18,
                            color: AppColors.textSecondary),
                        onPressed: () => onRemove(e.key),
                        visualDensity:
                            VisualDensity.compact,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isSaving ? null : onSave,
              icon: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white))
                  : const Icon(Icons.save_outlined),
              label: Text(isSaving ? 'Sauvegarde…' : 'Sauvegarder'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(
                    vertical: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Static logs tab ──────────────────────────────────────────────────────────

class _StaticLogsTab extends StatelessWidget {
  final String logs;
  final bool isLoading;
  final VoidCallback onRefresh;

  const _StaticLogsTab(
      {required this.logs,
      required this.isLoading,
      required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
          child:
              CircularProgressIndicator(color: AppColors.accent));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
          child: Row(
            children: [
              const Text('Logs container',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh,
                    size: 18, color: AppColors.textSecondary),
                tooltip: 'Rafraîchir',
                onPressed: onRefresh,
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              logs.isEmpty ? '(aucun log)' : logs,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Add env var dialog ───────────────────────────────────────────────────────

class _AddEnvVarDialog extends StatefulWidget {
  final void Function(String key, String value) onAdd;
  const _AddEnvVarDialog({required this.onAdd});

  @override
  State<_AddEnvVarDialog> createState() => _AddEnvVarDialogState();
}

class _AddEnvVarDialogState extends State<_AddEnvVarDialog> {
  final _keyCtrl = TextEditingController();
  final _valCtrl = TextEditingController();

  @override
  void dispose() {
    _keyCtrl.dispose();
    _valCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Ajouter une variable',
          style: TextStyle(color: AppColors.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _keyCtrl,
            autofocus: true,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              labelText: 'Clé (ex: PORT)',
              labelStyle:
                  TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _valCtrl,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              labelText: 'Valeur',
              labelStyle:
                  TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler',
              style:
                  TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () {
            final k = _keyCtrl.text.trim();
            if (k.isNotEmpty) {
              widget.onAdd(k, _valCtrl.text);
              Navigator.pop(context);
            }
          },
          style: TextButton.styleFrom(
              foregroundColor: AppColors.accent),
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}
