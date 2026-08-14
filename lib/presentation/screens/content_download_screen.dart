import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/app_provider.dart';
import '../../application/content_download_service.dart';
import '../../theme/app_theme.dart';
import 'grade_selection_screen.dart';
import 'language_selection_screen.dart';

class ContentDownloadScreen extends StatefulWidget {
  final int gradeId;
  final String gradeName;
  final bool isUpdateMode;

  const ContentDownloadScreen({
    super.key,
    required this.gradeId,
    required this.gradeName,
    this.isUpdateMode = false,
  });

  @override
  State<ContentDownloadScreen> createState() => _ContentDownloadScreenState();
}

class _ContentDownloadScreenState extends State<ContentDownloadScreen>
    with TickerProviderStateMixin {
  final ContentDownloadService _downloadService = ContentDownloadService();

  DownloadStage _stage = DownloadStage.checkingVersion;
  double _downloadProgress = 0.0;
  String _statusMessage = 'Initialising...';
  bool _hasError = false;
  bool _isDone = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startDownload();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startDownload() async {
    final provider = Provider.of<AppProvider>(context, listen: false);

    await _downloadService.syncGradeContent(
      gradeId: widget.gradeId,
      onStage: (stage) {
        if (!mounted) return;
        setState(() {
          _stage = stage;
          _hasError = stage == DownloadStage.error;
          _isDone = stage == DownloadStage.done;
          if (stage != DownloadStage.downloading) _downloadProgress = 0.0;
        });
      },
      onProgress: (progress) {
        if (!mounted) return;
        setState(() => _downloadProgress = progress);
      },
      onMessage: (msg) {
        if (!mounted) return;
        setState(() => _statusMessage = msg);
      },
    );

    if (!mounted) return;

    if (_isDone) {
      // Lock grade selection permanently after successful download
      await provider.lockGrade();

      if (widget.isUpdateMode) {
        // Do not auto-navigate to language screen if opened from settings
        return;
      }

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      _navigateToLanguageSelection();
    } else if (_hasError) {
      if (widget.isUpdateMode) return;
      // Show friendly message if content for this grade is unavailable
      _showContentUnavailableDialog();
    }
  }

  void _showContentUnavailableDialog() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.unlockGrade();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.info_outline, color: AppColors.royalGold),
            SizedBox(width: 8),
            Text('Content Not Available'),
          ],
        ),
        content: Text(
          'Content for ${widget.gradeName} is not yet available. Please check again later or select a different grade.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const GradeSelectionScreen()),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emeraldGreen),
            child: const Text('RESELECT OTHER GRADE'),
          ),
        ],
      ),
    );
  }

  void _navigateToLanguageSelection() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
    );
  }

  String get _stageTitle {
    switch (_stage) {
      case DownloadStage.checkingVersion:  return 'Checking for Updates';
      case DownloadStage.preparing:        return 'Preparing Download';
      case DownloadStage.downloading:      return 'Downloading Content';
      case DownloadStage.unpacking:        return 'Unpacking';
      case DownloadStage.storing:          return 'Saving to Device';
      case DownloadStage.done:             return 'All Done!';
      case DownloadStage.error:            return 'Something Went Wrong';
    }
  }

  IconData get _stageIcon {
    switch (_stage) {
      case DownloadStage.checkingVersion:  return Icons.cloud_sync;
      case DownloadStage.preparing:        return Icons.download_for_offline;
      case DownloadStage.downloading:      return Icons.download;
      case DownloadStage.unpacking:        return Icons.folder_zip;
      case DownloadStage.storing:          return Icons.storage;
      case DownloadStage.done:             return Icons.check_circle;
      case DownloadStage.error:            return Icons.error_outline;
    }
  }

  Color get _stageColor {
    if (_hasError) return const Color(0xFFEF4444);
    if (_isDone)   return AppColors.emeraldGreen;
    return AppColors.royalGold;
  }

  // Step indicator data
  static const _steps = [
    (DownloadStage.checkingVersion, 'Check'),
    (DownloadStage.preparing,       'Prepare'),
    (DownloadStage.downloading,     'Download'),
    (DownloadStage.unpacking,       'Unpack'),
    (DownloadStage.storing,         'Save'),
    (DownloadStage.done,            'Done'),
  ];

  bool _isStepComplete(DownloadStage step) {
    final stageOrder = [
      DownloadStage.checkingVersion,
      DownloadStage.preparing,
      DownloadStage.downloading,
      DownloadStage.unpacking,
      DownloadStage.storing,
      DownloadStage.done,
    ];
    return stageOrder.indexOf(_stage) > stageOrder.indexOf(step);
  }

  bool _isStepActive(DownloadStage step) => _stage == step;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48.0,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const Spacer(),

                      // ── Grade badge ──────────────────────────────────────────────
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.lightGreen,
                          border: Border.all(color: AppColors.emeraldGreen, width: 3),
                        ),
                        child: Center(
                          child: Text(
                            '${widget.gradeId}',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.emeraldGreen,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        widget.gradeName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Animated stage icon ──────────────────────────────────────
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: (!_isDone && !_hasError) ? _pulseAnimation.value : 1.0,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _stageColor.withAlpha(26),
                                border: Border.all(color: _stageColor, width: 2),
                              ),
                              child: Icon(_stageIcon, size: 40, color: _stageColor),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // ── Stage title ──────────────────────────────────────────────
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _stageTitle,
                          key: ValueKey(_stage),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _stageColor,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ── Status message ───────────────────────────────────────────
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          _statusMessage,
                          key: ValueKey(_statusMessage),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondaryLight,
                            height: 1.4,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Download progress bar ────────────────────────────────────
                      if (_stage == DownloadStage.downloading) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Downloading...', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                            Text(
                              '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.emeraldGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: _downloadProgress,
                            minHeight: 10,
                            backgroundColor: AppColors.borderLight,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.emeraldGreen),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // ── Indeterminate bar for other stages ───────────────────────
                      if (!_isDone && !_hasError && _stage != DownloadStage.downloading) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: const LinearProgressIndicator(
                            minHeight: 6,
                            backgroundColor: AppColors.borderLight,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.royalGold),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // ── Step indicator ───────────────────────────────────────────
                      _buildStepIndicator(),

                      const Spacer(),

                      // ── Bottom action buttons ────────────────────────────────────
                      if (_isDone) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: widget.isUpdateMode
                                ? () => Navigator.of(context).pop()
                                : _navigateToLanguageSelection,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.emeraldGreen,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(
                              widget.isUpdateMode ? 'Return' : 'Continue →',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],

                      if (_hasError) ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('← Go Back'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _stage = DownloadStage.checkingVersion;
                                    _hasError = false;
                                    _downloadProgress = 0.0;
                                    _statusMessage = 'Retrying...';
                                  });
                                  _startDownload();
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.emeraldGreen),
                                child: const Text('Retry'),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _steps.asMap().entries.map((entry) {
        final isLast = entry.key == _steps.length - 1;
        final (step, label) = entry.value;
        final isDone = _isStepComplete(step);
        final isActive = _isStepActive(step);

        Color circleColor = AppColors.borderLight;
        Color textColor = AppColors.textSecondaryLight;
        Widget circleChild = Text(
          '${entry.key + 1}',
          style: TextStyle(
            fontSize: 11,
            color: isActive ? Colors.white : AppColors.textSecondaryLight,
            fontWeight: FontWeight.bold,
          ),
        );

        if (isDone) {
          circleColor = AppColors.emeraldGreen;
          circleChild = const Icon(Icons.check, size: 14, color: Colors.white);
          textColor = AppColors.emeraldGreen;
        } else if (isActive) {
          circleColor = _stageColor;
          textColor = _stageColor;
        }

        return Row(
          children: [
            Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: circleColor,
                    border: Border.all(
                      color: isActive ? _stageColor : (isDone ? AppColors.emeraldGreen : AppColors.borderLight),
                      width: 2,
                    ),
                  ),
                  child: Center(child: circleChild),
                ),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(fontSize: 9, color: textColor)),
              ],
            ),
            if (!isLast)
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 28,
                height: 2,
                margin: const EdgeInsets.only(bottom: 16),
                color: isDone ? AppColors.emeraldGreen : AppColors.borderLight,
              ),
          ],
        );
      }).toList(),
    );
  }
}
