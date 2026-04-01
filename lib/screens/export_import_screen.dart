// lib/screens/export_import_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../services/export_import_service.dart';
import '../services/hive_service.dart';
import '../services/snackbar_service.dart';

class ExportImportScreen extends ConsumerStatefulWidget {
  const ExportImportScreen({super.key});

  @override
  ConsumerState<ExportImportScreen> createState() => _ExportImportScreenState();
}

class _ExportImportScreenState extends ConsumerState<ExportImportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _isLoading = false;
  String? _statusMessage;
  bool _statusSuccess = false;

  // Export options
  bool _exportAllMonths = true;
  String? _selectedExportMonth;
  List<String> _availableMonths = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadAvailableMonths();
  }

  void _loadAvailableMonths() {
    final keys = <String>{};
    keys.addAll(HiveService.monthData.keys.cast<String>());
    for (final c in HiveService.categories.values) keys.add(c.monthKey);
    for (final t in HiveService.transactions.values) keys.add(t.monthKey);
    for (final cc in HiveService.creditCards.values) keys.add(cc.monthKey);

    final sorted = keys.toList()
      ..sort((a, b) {
        DateTime parse(String k) {
          try {
            final p = k.split('-');
            return DateTime(int.parse(p[1]), int.parse(p[0]));
          } catch (_) {
            return DateTime(2000);
          }
        }

        return parse(b).compareTo(parse(a)); // newest first
      });

    setState(() {
      _availableMonths = sorted;
      if (sorted.isNotEmpty) _selectedExportMonth = sorted.first;
    });
  }

  String _formatMonthKey(String key) {
    try {
      final parts = key.split('-');
      final dt = DateTime(int.parse(parts[1]), int.parse(parts[0]));
      return DateFormat('MMMM yyyy').format(dt);
    } catch (_) {
      return key;
    }
  }

  Future<void> _doExport() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });
    try {
      final monthKey = _exportAllMonths ? null : _selectedExportMonth;
      await ExportImportService.exportToExcel(specificMonthKey: monthKey);
      setState(() {
        _statusSuccess = true;
        _statusMessage = _exportAllMonths
            ? 'All months exported successfully!'
            : 'Exported ${_formatMonthKey(_selectedExportMonth!)} successfully!';
        SnackbarService.show(
          context,
          'Export successful! File ready to share.',
        );
      });
    } catch (e) {
      setState(() {
        _statusSuccess = false;
        _statusMessage = 'Export failed: ${e.toString()}';
        SnackbarService.show(
          context,
          'Export failed. Please try again.',
          type: SnackType.error,
        );
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _doImport() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });
    try {
      final result = await ExportImportService.importFromExcel();
      setState(() {
        _statusSuccess = result.success;
        _statusMessage = result.message;
      });
      if (result.success) {
        // Reload current month data in providers
        final monthKey = ref.read(selectedMonthProvider.notifier).monthKey;
        ref.read(monthDataProvider.notifier).loadMonth(monthKey);
        ref.read(categoriesProvider.notifier).loadCategories(monthKey);
        ref.read(transactionsProvider.notifier).loadTransactions(monthKey);
        ref.read(creditCardsProvider.notifier).loadCreditCards(monthKey);
        _loadAvailableMonths();
        SnackbarService.show(context, result.message);
      }
    } catch (e) {
      setState(() {
        _statusSuccess = false;
        _statusMessage = 'Import failed: ${e.toString()}';
        SnackbarService.show(context, 'Import failed. Please try again.', type: SnackType.error);
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Export & Import'),
        backgroundColor: const Color(0xFF6A0DAD),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.upload_file), text: 'Export'),
            Tab(icon: Icon(Icons.download_for_offline), text: 'Import'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [_buildExportTab(), _buildImportTab()],
      ),
    );
  }

  Widget _buildExportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //Info Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF6A0DAD), width: 1),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF9B59B6), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Export your budget data as an Excel file (.xlsx). '
                    'The file can be saved, shared, or used to restore data on a new device.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
          const Text(
            'EXPORT SCOPE',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),

          //All months toggle
          _OptionTile(
            icon: Icons.calendar_view_month,
            title: 'All Months',
            subtitle:
                'Export complete history (${_availableMonths.length} month${_availableMonths.length == 1 ? '' : 's'})',
            selected: _exportAllMonths,
            onTap: () => setState(() => _exportAllMonths = true),
          ),
          const SizedBox(height: 8),
          _OptionTile(
            icon: Icons.calendar_today,
            title: 'Specific Month',
            subtitle: 'Export one month only',
            selected: !_exportAllMonths,
            onTap: () => setState(() => _exportAllMonths = false),
          ),

          //Month dropdown
          if (!_exportAllMonths) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1C),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedExportMonth,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1C1C1C),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  items: _availableMonths
                      .map(
                        (mk) => DropdownMenuItem(
                          value: mk,
                          child: Text(_formatMonthKey(mk)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedExportMonth = v),
                ),
              ),
            ),
          ],

          const SizedBox(height: 28),

          //What's included
          const Text(
            'WHAT\'S INCLUDED IN EXPORT',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          ..._exportItems.map(
            (item) => _ExportItemRow(
              icon: item['icon'] as IconData,
              label: item['label'] as String,
              sheet: item['sheet'] as String,
            ),
          ),

          const SizedBox(height: 32),

          //Export Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isLoading || _availableMonths.isEmpty
                  ? null
                  : _doExport,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.upload_file, color: Colors.white),
              label: Text(
                _isLoading
                    ? 'Exporting...'
                    : _availableMonths.isEmpty
                    ? 'No data to export'
                    : 'Export to Excel',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A0DAD),
                disabledBackgroundColor: Colors.grey.shade800,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          if (_statusMessage != null && _tabCtrl.index == 0) ...[
            const SizedBox(height: 16),
            _StatusBanner(message: _statusMessage!, success: _statusSuccess),
          ],
        ],
      ),
    );
  }

  Widget _buildImportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //Info Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2E1A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade700, width: 1),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.green, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Select a .xlsx file previously exported from this app. '
                    'Existing data will NOT be overwritten — only new entries are added.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          //Steps
          const Text(
            'HOW TO IMPORT',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          ..._importSteps.asMap().entries.map(
            (e) => _StepRow(step: e.key + 1, text: e.value),
          ),

          const SizedBox(height: 32),

          //Import Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _doImport,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.download_for_offline, color: Colors.white),
              label: Text(
                _isLoading ? 'Importing...' : 'Select & Import Excel File',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                disabledBackgroundColor: Colors.grey.shade800,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          if (_statusMessage != null) ...[
            const SizedBox(height: 16),
            _StatusBanner(message: _statusMessage!, success: _statusSuccess),
          ],
        ],
      ),
    );
  }

  static const List<Map<String, dynamic>> _exportItems = [
    {'icon': Icons.summarize, 'label': 'Monthly Summary', 'sheet': 'Sheet 1'},
    {'icon': Icons.category, 'label': 'Budget Categories', 'sheet': 'Sheet 2'},
    {
      'icon': Icons.receipt_long,
      'label': 'All Transactions',
      'sheet': 'Sheet 3',
    },
    {
      'icon': Icons.credit_card,
      'label': 'Credit Card Spends',
      'sheet': 'Sheet 4',
    },
  ];

  static const List<String> _importSteps = [
    'Tap "Select & Import Excel File" below',
    'Choose the .xlsx file exported from this app',
    'New data will be merged — duplicates are skipped',
    'All months in the file will be restored automatically',
  ];
}

//Helper Widgets

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2A1A40) : const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF6A0DAD) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? const Color(0xFF9B59B6) : Colors.white38,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF6A0DAD),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _ExportItemRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sheet;

  const _ExportItemRow({
    required this.icon,
    required this.label,
    required this.sheet,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              sheet,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int step;
  final String text;

  const _StepRow({required this.step, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.green.shade800,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$step',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String message;
  final bool success;

  const _StatusBanner({required this.message, required this.success});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: success ? const Color(0xFF1A3A1A) : const Color(0xFF3A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: success ? Colors.green.shade700 : Colors.red.shade700,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            success ? Icons.check_circle_outline : Icons.error_outline,
            color: success ? Colors.greenAccent : Colors.redAccent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: success ? Colors.greenAccent : Colors.redAccent,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
