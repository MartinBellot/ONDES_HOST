import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/websocket_service.dart';
import '../theme/app_theme.dart';
import '../widgets/content_header.dart';

// ─── Breakpoint helper ────────────────────────────────────────────────────────

bool _isMobile(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 700;

// ─── Data models ─────────────────────────────────────────────────────────────

class _ContainerNode {
  final String id;
  final String name;
  final String image;
  final String status;
  final double cpuPct;
  final double memPct;
  final double memMb;
  final Map<String, dynamic> labels;

  const _ContainerNode({
    required this.id,
    required this.name,
    required this.image,
    required this.status,
    required this.cpuPct,
    required this.memPct,
    required this.memMb,
    required this.labels,
  });

  factory _ContainerNode.fromJson(Map<String, dynamic> j) => _ContainerNode(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        image: j['image'] as String? ?? '',
        status: j['status'] as String? ?? 'unknown',
        cpuPct: (j['cpu_pct'] as num?)?.toDouble() ?? 0,
        memPct: (j['mem_pct'] as num?)?.toDouble() ?? 0,
        memMb: (j['mem_mb'] as num?)?.toDouble() ?? 0,
        labels: Map<String, dynamic>.from(j['labels'] as Map? ?? {}),
      );

  String get composeProject =>
      labels['com.docker.compose.project'] as String? ?? '';
  String get composeService =>
      labels['com.docker.compose.service'] as String? ?? '';

  String get displayName =>
      composeService.isNotEmpty ? composeService : name;

  _ContainerNode copyWith({double? cpuPct, double? memPct, double? memMb}) =>
      _ContainerNode(
        id: id,
        name: name,
        image: image,
        status: status,
        cpuPct: cpuPct ?? this.cpuPct,
        memPct: memPct ?? this.memPct,
        memMb: memMb ?? this.memMb,
        labels: labels,
      );
}

// ─── Layout constants ─────────────────────────────────────────────────────────

const _kNodeW = 200.0;
const _kNodeH = 130.0;
const _kGapX = 80.0;
const _kGapY = 100.0;
const _kGroupPad = 40.0;
const _kGroupGapY = 120.0;
const _kGroupLabelH = 32.0;
const _kCols = 3;

// ─── Main screen ─────────────────────────────────────────────────────────────

class InfrastructureCanvasScreen extends StatefulWidget {
  const InfrastructureCanvasScreen({super.key});

  @override
  State<InfrastructureCanvasScreen> createState() =>
      _InfrastructureCanvasScreenState();
}

class _InfrastructureCanvasScreenState
    extends State<InfrastructureCanvasScreen>
    with TickerProviderStateMixin {
  final _ws = WebSocketService();
  StreamSubscription? _wsSub;

  List<_ContainerNode> _containers = [];
  bool _wsConnected = false;
  bool _reconnectScheduled = false;

  _ContainerNode? _selectedNode;

  final _transformController = TransformationController();
  final Map<String, Offset> _positions = {};
  Set<String> _lastIds = {};
  double _currentScale = 1.0;
  Size _viewSize = Size.zero;
  bool _hasFittedOnce = false;

  @override
  void initState() {
    super.initState();
    _connectMetrics();
    _transformController.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _wsSub?.cancel();
    _ws.disconnect();
    _transformController.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() > 0.005) {
      setState(() => _currentScale = scale);
    }
  }

  Future<void> _connectMetrics() async {
    if (!mounted) return;
    await _wsSub?.cancel();
    _wsSub = null;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final token = prefs.getString('access_token') ?? '';
    _ws.disconnect();
    _ws.connect('/ws/metrics/?token=$token');
    _wsSub = _ws.stream?.listen(
      (raw) {
        if (!mounted) return;
        try {
          final msg = jsonDecode(raw as String) as Map<String, dynamic>;
          if (msg['type'] == 'metrics') {
            final list = (msg['containers'] as List? ?? [])
                .cast<Map<String, dynamic>>()
                .map(_ContainerNode.fromJson)
                .toList();
            setState(() {
              _wsConnected = true;
              _containers = list;
              if (_selectedNode != null) {
                final updated =
                    list.where((c) => c.id == _selectedNode!.id).firstOrNull;
                if (updated != null) _selectedNode = updated;
              }
            });
          }
        } catch (_) {}
      },
      onError: (_) {
        if (mounted) setState(() => _wsConnected = false);
        _scheduleReconnect();
      },
      onDone: () {
        if (mounted) setState(() => _wsConnected = false);
        _scheduleReconnect();
      },
      cancelOnError: false,
    );
  }

  void _scheduleReconnect() {
    if (!mounted || _reconnectScheduled) return;
    _reconnectScheduled = true;
    Future.delayed(const Duration(seconds: 3), () {
      _reconnectScheduled = false;
      if (mounted) _connectMetrics();
    });
  }

  void _computePositions() {
    final ids = _containers.map((c) => c.id).toSet();
    if (ids == _lastIds) return;
    _lastIds = ids;
    _positions.clear();

    final groups = <String, List<_ContainerNode>>{};
    for (final c in _containers) {
      final key = c.composeProject.isEmpty ? '__standalone' : c.composeProject;
      groups.putIfAbsent(key, () => []).add(c);
    }

    double groupY = _kGroupPad;
    for (final entry in groups.entries) {
      final nodes = entry.value;
      double rowX = _kGroupPad + _kGroupPad;
      double rowY = groupY + _kGroupLabelH + _kGroupPad;
      int col = 0;

      for (final n in nodes) {
        _positions[n.id] = Offset(rowX, rowY);
        col++;
        if (col % _kCols == 0) {
          rowX = _kGroupPad + _kGroupPad;
          rowY += _kNodeH + _kGapY;
        } else {
          rowX += _kNodeW + _kGapX;
        }
      }

      final rows = (nodes.length / _kCols).ceil();
      final groupH = _kGroupLabelH +
          _kGroupPad * 2 +
          rows * (_kNodeH + _kGapY) -
          _kGapY;
      groupY += groupH + _kGroupGapY;
    }
  }

  void _fitAll(Size viewSize) {
    if (_positions.isEmpty) return;

    double minX = double.infinity,
        minY = double.infinity,
        maxX = double.negativeInfinity,
        maxY = double.negativeInfinity;

    for (final pos in _positions.values) {
      if (pos.dx < minX) minX = pos.dx;
      if (pos.dy < minY) minY = pos.dy;
      if (pos.dx + _kNodeW > maxX) maxX = pos.dx + _kNodeW;
      if (pos.dy + _kNodeH > maxY) maxY = pos.dy + _kNodeH;
    }

    const margin = 60.0;
    final contentW = maxX - minX + margin * 2;
    final contentH = maxY - minY + margin * 2;
    final scaleX = viewSize.width / contentW;
    final scaleY = viewSize.height / contentH;
    final scale = math.min(scaleX, scaleY).clamp(0.08, 1.5);

    final scaledW = contentW * scale;
    final scaledH = contentH * scale;
    final tx = (viewSize.width - scaledW) / 2 - (minX - margin) * scale;
    final ty = (viewSize.height - scaledH) / 2 - (minY - margin) * scale;

    // Build a valid invertible 2D affine matrix via setEntry (column-major)
    final m = Matrix4.identity();
    m.setEntry(0, 0, scale);
    m.setEntry(1, 1, scale);
    m.setEntry(0, 3, tx);
    m.setEntry(1, 3, ty);
    _transformController.value = m;
  }

  void _zoom(double factor) {
    final current = _transformController.value;
    final currentScale = current.getMaxScaleOnAxis();
    final newScale = (currentScale * factor).clamp(0.08, 4.0);
    final ratio = newScale / currentScale;
    final translation = current.getTranslation();
    // Zoom toward the center of the current viewport
    final cx = _viewSize.width / 2;
    final cy = _viewSize.height / 2;
    final newTx = cx - (cx - translation.x) * ratio;
    final newTy = cy - (cy - translation.y) * ratio;
    final m = Matrix4.identity();
    m.setEntry(0, 0, newScale);
    m.setEntry(1, 1, newScale);
    m.setEntry(0, 3, newTx);
    m.setEntry(1, 3, newTy);
    _transformController.value = m;
  }

  void _showDetailMobile(_ContainerNode node) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => _MobileDetailSheet(node: node),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobile(context);
    // On mobile the bottom bar (height 75 + 2×20 padding = 115) is overlaid
    // over the content navigator via Positioned — reserve space for it so
    // the canvas is never hidden behind it.
    final bottomBarInset = mobile
        ? MediaQuery.of(context).padding.bottom + 115.0
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _CanvasHeader(
            wsConnected: _wsConnected,
            containerCount: _containers.length,
            runningCount:
                _containers.where((c) => c.status == 'running').length,
            onRefresh: _connectMetrics,
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildCanvas(mobile, bottomBarInset)),
                if (!mobile && _selectedNode != null)
                  _AnimatedDetailPanel(
                    node: _selectedNode!,
                    onClose: () => setState(() => _selectedNode = null),
                  ),
              ],
            ),
          ),
          // Push content above the mobile bottom bar
          if (mobile) SizedBox(height: bottomBarInset),
        ],
      ),
    );
  }

  Widget _buildCanvas(bool mobile, double bottomBarInset) {
    if (!_wsConnected && _containers.isEmpty) {
      return const _EmptyState(
        loading: true,
        message: 'Connexion au flux de métriques…',
        sub: 'Les données arrivent en temps réel via WebSocket.',
      );
    }

    if (_wsConnected && _containers.isEmpty) {
      return const _EmptyState(
        loading: false,
        message: 'Aucun container en cours',
        sub: 'Déployez un stack ou démarrez des containers.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _computePositions();
        _viewSize = constraints.biggest;
        // Auto-fit once on first data arrival — never again (preserves user zoom)
        if (!_hasFittedOnce && _positions.isNotEmpty && _viewSize != Size.zero) {
          _hasFittedOnce = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _fitAll(_viewSize);
          });
        }

        return Stack(
          children: [
            InteractiveViewer(
              transformationController: _transformController,
              boundaryMargin: const EdgeInsets.all(800),
              minScale: 0.08,
              maxScale: 4.0,
              child: _CanvasContent(
                containers: _containers,
                positions: _positions,
                selectedId: _selectedNode?.id,
                isMobile: mobile,
                onNodeTap: (node) {
                  if (mobile) {
                    _showDetailMobile(node);
                  } else {
                    setState(() {
                      _selectedNode =
                          _selectedNode?.id == node.id ? null : node;
                    });
                  }
                },
              ),
            ),
            Positioned(
              right: 16,
              bottom: 20,
              child: _ZoomControls(
                scale: _currentScale,
                onZoomIn: () => _zoom(1.3),
                onZoomOut: () => _zoom(1 / 1.3),
                onFitAll: () => _fitAll(_viewSize),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Canvas content ───────────────────────────────────────────────────────────

class _CanvasContent extends StatelessWidget {
  final List<_ContainerNode> containers;
  final Map<String, Offset> positions;
  final String? selectedId;
  final bool isMobile;
  final void Function(_ContainerNode) onNodeTap;

  const _CanvasContent({
    required this.containers,
    required this.positions,
    required this.selectedId,
    required this.isMobile,
    required this.onNodeTap,
  });

  @override
  Widget build(BuildContext context) {
    double maxX = 800, maxY = 600;
    for (final pos in positions.values) {
      if (pos.dx + _kNodeW + _kGroupPad > maxX) {
        maxX = pos.dx + _kNodeW + _kGroupPad;
      }
      if (pos.dy + _kNodeH + _kGroupPad > maxY) {
        maxY = pos.dy + _kNodeH + _kGroupPad;
      }
    }

    final groups = <String, List<_ContainerNode>>{};
    for (final c in containers) {
      final key = c.composeProject.isEmpty ? '' : c.composeProject;
      if (key.isNotEmpty) groups.putIfAbsent(key, () => []).add(c);
    }

    return SizedBox(
      width: maxX + 80,
      height: maxY + 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ...groups.entries.map((entry) {
            final groupNodes = entry.value;
            final nodePositions = groupNodes
                .where((n) => positions.containsKey(n.id))
                .map((n) => positions[n.id]!)
                .toList();
            if (nodePositions.isEmpty) return const SizedBox.shrink();

            const pad = _kGroupPad;
            final minX = nodePositions
                    .map((p) => p.dx)
                    .reduce((a, b) => a < b ? a : b) -
                pad;
            final minY = nodePositions
                    .map((p) => p.dy)
                    .reduce((a, b) => a < b ? a : b) -
                pad -
                _kGroupLabelH;
            final maxGX = nodePositions
                    .map((p) => p.dx)
                    .reduce((a, b) => a > b ? a : b) +
                _kNodeW +
                pad;
            final maxGY = nodePositions
                    .map((p) => p.dy)
                    .reduce((a, b) => a > b ? a : b) +
                _kNodeH +
                pad;

            return Positioned(
              left: minX,
              top: minY,
              child: _GroupBackdrop(
                label: entry.key,
                width: maxGX - minX,
                height: maxGY - minY,
              ),
            );
          }),
          ...containers.map((node) {
            final pos = positions[node.id] ?? const Offset(40, 40);
            return Positioned(
              left: pos.dx,
              top: pos.dy,
              child: GestureDetector(
                onTap: () => onNodeTap(node),
                behavior: HitTestBehavior.opaque,
                child: _ContainerNodeCard(
                  node: node,
                  isSelected: selectedId == node.id,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Group backdrop ───────────────────────────────────────────────────────────

class _GroupBackdrop extends StatelessWidget {
  final String label;
  final double width;
  final double height;

  const _GroupBackdrop({
    required this.label,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.18),
                width: 1.5,
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 14,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Node card ────────────────────────────────────────────────────────────────

class _ContainerNodeCard extends StatefulWidget {
  final _ContainerNode node;
  final bool isSelected;

  const _ContainerNodeCard({
    required this.node,
    required this.isSelected,
  });

  @override
  State<_ContainerNodeCard> createState() => _ContainerNodeCardState();
}

class _ContainerNodeCardState extends State<_ContainerNodeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Color get _statusColor {
    switch (widget.node.status) {
      case 'running':
        return AppColors.accentGreen;
      case 'exited':
      case 'dead':
        return AppColors.accentRed;
      case 'paused':
        return AppColors.accentYellow;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData get _imageIcon {
    final img = widget.node.image.toLowerCase();
    if (img.contains('nginx') ||
        img.contains('caddy') ||
        img.contains('traefik')) {
      return Icons.language;
    } else if (img.contains('postgres') ||
        img.contains('mysql') ||
        img.contains('mariadb')) {
      return Icons.storage;
    } else if (img.contains('redis') || img.contains('memcach')) {
      return Icons.bolt;
    } else if (img.contains('mongo')) {
      return Icons.data_object;
    } else if (img.contains('python') ||
        img.contains('django') ||
        img.contains('flask') ||
        img.contains('fastapi')) {
      return Icons.code;
    } else if (img.contains('node') ||
        img.contains('next') ||
        img.contains('nuxt')) {
      return Icons.javascript;
    } else if (img.contains('flutter') || img.contains('dart')) {
      return Icons.flutter_dash;
    } else if (img.contains('rabbit') || img.contains('kafka')) {
      return Icons.swap_horiz;
    }
    return Icons.widgets_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final cpuColor = node.cpuPct > 80
        ? AppColors.accentRed
        : node.cpuPct > 40
            ? AppColors.accentYellow
            : AppColors.accentGreen;

    final isRunning = node.status == 'running';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _kNodeW,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isSelected
              ? AppColors.accent
              : _statusColor.withValues(alpha: 0.4),
          width: widget.isSelected ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (widget.isSelected ? AppColors.accent : _statusColor)
                .withValues(alpha: 0.18),
            blurRadius: 18,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_imageIcon, size: 15, color: _statusColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  node.displayName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              if (isRunning)
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentGreen
                          .withValues(alpha: _pulseAnim.value),
                    ),
                  ),
                )
              else
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _statusColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            node.image.split(':').first.split('/').last,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              node.status.toUpperCase(),
              style: TextStyle(
                color: _statusColor,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _MiniBar(
            label: 'CPU',
            value: node.cpuPct / 100,
            color: cpuColor,
            text: '${node.cpuPct.toStringAsFixed(1)}%',
          ),
          const SizedBox(height: 7),
          _MiniBar(
            label: 'MEM',
            value: node.memPct / 100,
            color: AppColors.accent,
            text: '${node.memMb.toStringAsFixed(0)}M',
          ),
        ],
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String text;

  const _MiniBar({
    required this.label,
    required this.value,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 30,
          child: Text(label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              )),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 5,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(text,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontFamily: 'monospace',
            )),
      ],
    );
  }
}

// ─── Zoom controls overlay ────────────────────────────────────────────────────

class _ZoomControls extends StatelessWidget {
  final double scale;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFitAll;

  const _ZoomControls({
    required this.scale,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFitAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ZoomBtn(icon: Icons.add, tooltip: 'Zoomer', onTap: onZoomIn),
          Container(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            child: Text(
              '${(scale * 100).round()}%',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(height: 1, color: AppColors.border),
          _ZoomBtn(icon: Icons.remove, tooltip: 'Dézoomer', onTap: onZoomOut),
          Container(height: 1, color: AppColors.border),
          _ZoomBtn(
              icon: Icons.fit_screen, tooltip: 'Tout voir', onTap: onFitAll),
        ],
      ),
    );
  }
}

class _ZoomBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ZoomBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 16, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

// ─── Header bar ───────────────────────────────────────────────────────────────

class _CanvasHeader extends StatelessWidget {
  final bool wsConnected;
  final int containerCount;
  final int runningCount;
  final VoidCallback onRefresh;

  const _CanvasHeader({
    required this.wsConnected,
    required this.containerCount,
    required this.runningCount,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobile(context);
    return ContentHeader(
      title: 'Infrastructure Canvas',
      actions: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: wsConnected ? AppColors.accentGreen : AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          wsConnected ? 'Live' : 'Connexion…',
          style: TextStyle(
            color: wsConnected ? AppColors.accentGreen : AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (wsConnected && !mobile) ...[
          const SizedBox(width: 16),
          Text(
            '$runningCount / $containerCount actifs',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(width: 4),
        Tooltip(
          message: 'Rafraîchir',
          child: IconButton(
            icon: const Icon(Icons.refresh,
                size: 18, color: AppColors.textSecondary),
            onPressed: onRefresh,
          ),
        ),
        if (!mobile)
          const Tooltip(
            message: 'Scroll pour zoomer · Drag pour déplacer',
            child:
                Icon(Icons.help_outline, size: 16, color: AppColors.textMuted),
          ),
      ],
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool loading;
  final String message;
  final String sub;

  const _EmptyState({
    required this.loading,
    required this.message,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                  color: AppColors.accent, strokeWidth: 2),
            )
          else
            const Icon(Icons.cloud_off_outlined,
                size: 56, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 15)),
          const SizedBox(height: 6),
          Text(sub,
              style:
                  const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}

// ─── Animated desktop detail panel ───────────────────────────────────────────

class _AnimatedDetailPanel extends StatefulWidget {
  final _ContainerNode node;
  final VoidCallback onClose;

  const _AnimatedDetailPanel({required this.node, required this.onClose});

  @override
  State<_AnimatedDetailPanel> createState() => _AnimatedDetailPanelState();
}

class _AnimatedDetailPanelState extends State<_AnimatedDetailPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _slide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: _NodeDetailPanel(
          node: widget.node,
          onClose: widget.onClose,
        ),
      ),
    );
  }
}

// ─── Node detail panel (desktop) ─────────────────────────────────────────────

class _NodeDetailPanel extends StatelessWidget {
  final _ContainerNode node;
  final VoidCallback onClose;

  const _NodeDetailPanel({required this.node, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final cpuColor = node.cpuPct > 80
        ? AppColors.accentRed
        : node.cpuPct > 40
            ? AppColors.accentYellow
            : AppColors.accentGreen;

    final statusColor = node.status == 'running'
        ? AppColors.accentGreen
        : node.status == 'exited' || node.status == 'dead'
            ? AppColors.accentRed
            : AppColors.accentYellow;

    return Container(
      width: 290,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    node.displayName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      size: 16, color: AppColors.textSecondary),
                  onPressed: onClose,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          Expanded(
            child: _DetailPanelBody(node: node, cpuColor: cpuColor),
          ),
        ],
      ),
    );
  }
}

// ─── Mobile detail bottom sheet ───────────────────────────────────────────────

class _MobileDetailSheet extends StatelessWidget {
  final _ContainerNode node;

  const _MobileDetailSheet({required this.node});

  @override
  Widget build(BuildContext context) {
    final cpuColor = node.cpuPct > 80
        ? AppColors.accentRed
        : node.cpuPct > 40
            ? AppColors.accentYellow
            : AppColors.accentGreen;

    final statusColor = node.status == 'running'
        ? AppColors.accentGreen
        : node.status == 'exited' || node.status == 'dead'
            ? AppColors.accentRed
            : AppColors.accentYellow;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(color: AppColors.border),
              left: BorderSide(color: AppColors.border),
              right: BorderSide(color: AppColors.border),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: statusColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        node.displayName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.border, height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  child: _DetailPanelBody(node: node, cpuColor: cpuColor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Shared detail body ───────────────────────────────────────────────────────

class _DetailPanelBody extends StatelessWidget {
  final _ContainerNode node;
  final Color cpuColor;

  const _DetailPanelBody({required this.node, required this.cpuColor});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow('ID', node.id, mono: true),
          _DetailRow('Nom', node.name),
          _DetailRow('Image', node.image, mono: true),
          _DetailRow('Statut', node.status),
          if (node.composeProject.isNotEmpty)
            _DetailRow('Stack', node.composeProject),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _BigMetricTile(
                  label: 'CPU',
                  value: '${node.cpuPct.toStringAsFixed(1)}%',
                  color: cpuColor,
                  progress: node.cpuPct / 100,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BigMetricTile(
                  label: 'Mémoire',
                  value: '${node.memMb.toStringAsFixed(0)} MB',
                  color: AppColors.accent,
                  progress: node.memPct / 100,
                  subtitle: '${node.memPct.toStringAsFixed(1)}% du lim.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (node.labels.isNotEmpty) ...[
            const Text(
              'LABELS',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            ...node.labels.entries
                .where((e) => e.key.startsWith('com.docker.compose'))
                .map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _DetailRow(
                        e.key.split('.').last,
                        e.value.toString(),
                        mono: true,
                      ),
                    )),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;

  const _DetailRow(this.label, this.value, {this.mono = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontFamily: mono ? 'monospace' : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _BigMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final double progress;
  final String? subtitle;

  const _BigMetricTile({
    required this.label,
    required this.value,
    required this.color,
    required this.progress,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              )),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              )),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9,
                )),
          ],
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}
