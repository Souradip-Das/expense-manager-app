import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../providers/auth_provider.dart';
import '../providers/budget_provider.dart';
import '../services/app_theme.dart';
import '../services/auth_service.dart';
import '../services/snackbar_service.dart';
import '../widgets/balance_card.dart';
import '../widgets/category_card.dart';
import '../widgets/credit_card_tile.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/section_header.dart';
import '../widgets/transaction_filter_bar.dart';
import '../widgets/add_category_dialog.dart';
import '../widgets/add_transaction_dialog.dart';
import '../widgets/add_credit_card_dialog.dart';
import 'auth_gate.dart';
import 'export_import_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isLoadingData = false;
  TransactionFilter _filter = const TransactionFilter();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    final monthKey = ref.read(selectedMonthProvider.notifier).monthKey;
    await Future.wait([
      ref.read(monthDataProvider.notifier).loadMonth(monthKey),
      ref.read(categoriesProvider.notifier).loadCategories(monthKey),
      ref.read(transactionsProvider.notifier).loadTransactions(monthKey),
      ref.read(creditCardsProvider.notifier).loadCreditCards(monthKey),
    ]);
    if (mounted) {
      setState(() {
        _isLoadingData = false;
        _filter = const TransactionFilter();
      });
    }
  }

  String get _monthKey =>
      ref.read(selectedMonthProvider.notifier).monthKey;

  void _changeMonth(int delta) {
    if (delta > 0) {
      ref.read(selectedMonthProvider.notifier).nextMonth();
    } else {
      ref.read(selectedMonthProvider.notifier).prevMonth();
    }
    _loadData();
  }

  List<TransactionModel> _applyFilter(List<TransactionModel> txs) {
    return txs.where((tx) {
      if (_filter.category != null &&
          tx.categoryId != _filter.category!.id) return false;
      if (_filter.date != null) {
        final d = _filter.date!;
        if (tx.date.year != d.year ||
            tx.date.month != d.month ||
            tx.date.day != d.day) return false;
      }
      if (_filter.minAmount != null && tx.amount < _filter.minAmount!)
        return false;
      if (_filter.maxAmount != null && tx.amount > _filter.maxAmount!)
        return false;
      return true;
    }).toList();
  }

  Future<void> _editBalance({required bool isOpening}) async {
    final monthData = ref.read(monthDataProvider);
    final currentVal = isOpening
        ? (monthData?.openingBalance ?? 0)
        : ref.read(currentBalanceProvider);
    final ctrl =
        TextEditingController(text: currentVal.toStringAsFixed(0));

    final result = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
            isOpening ? 'Set Opening Balance' : 'Adjust Balance',
            style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Amount (₹)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textMuted))),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.cardGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextButton(
              onPressed: () =>
                  Navigator.pop(context, double.tryParse(ctrl.text)),
              child: const Text('Save',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );

    if (result != null) {
      if (isOpening) {
        await ref
            .read(monthDataProvider.notifier)
            .setOpeningBalance(_monthKey, result);
        if (mounted) {
          SnackbarService.show(context,
              'Opening balance set to ₹${result.toStringAsFixed(0)}');
        }
      } else {
        await ref
            .read(monthDataProvider.notifier)
            .setCurrentBalance(_monthKey, result);
        if (mounted) SnackbarService.show(context, 'Balance updated.');
      }
      ref.read(monthDataProvider.notifier).loadMonth(_monthKey);
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out',
            style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to sign out?',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textMuted))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sign Out',
                  style: TextStyle(color: AppTheme.accentRed))),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonth  = ref.watch(selectedMonthProvider);
    final monthData      = ref.watch(monthDataProvider);
    final categories     = ref.watch(categoriesProvider);
    final transactions   = ref.watch(transactionsProvider);
    final creditCards    = ref.watch(creditCardsProvider);
    final currentBalance = ref.watch(currentBalanceProvider);
    final totalBudget    = ref.watch(totalBudgetProvider);
    final txNotifier     = ref.read(transactionsProvider.notifier);
    final user           = ref.watch(currentUserProvider);

    final totalTxSpend = transactions.fold<double>(0, (s, t) => s + t.amount);
    final totalCCSpend = creditCards.fold<double>(0, (s, c) => s + c.amount);
    final totalSpends  = totalTxSpend + totalCCSpend;
    final monthLabel   = DateFormat('MMMM yyyy').format(selectedMonth);
    final filteredTxs  = _applyFilter(transactions);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primary,
        backgroundColor: AppTheme.cardBg,
        child: CustomScrollView(
          slivers: [
            // ── Gradient Header ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.headerGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    child: Column(
                      children: [
                        // ── Top row ──────────────────────────────────────
                        Row(
                          children: [
                            // User avatar
                            GestureDetector(
                              onTap: _confirmSignOut,
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: user?.photoURL != null
                                    ? ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        child: Image.network(
                                            user!.photoURL!,
                                            fit: BoxFit.cover),
                                      )
                                    : const Icon(Icons.person_outline,
                                        color: Colors.white, size: 20),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.displayName?.split(' ').first ??
                                        'Welcome',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const Text('Budget Tracker',
                                      style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: 11)),
                                ],
                              ),
                            ),
                            // Export button
                            _HeaderBtn(
                              icon: Icons.import_export_outlined,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const ExportImportScreen()),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Refresh button
                            _HeaderBtn(
                              icon: _isLoadingData
                                  ? Icons.hourglass_empty
                                  : Icons.refresh,
                              onTap:
                                  _isLoadingData ? null : _loadData,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── Month selector ───────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => _changeMonth(-1),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.chevron_left,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              monthLabel,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5),
                            ),
                            const SizedBox(width: 14),
                            GestureDetector(
                              onTap: () => _changeMonth(1),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.chevron_right,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── Current Balance (hero number) ────────────────
                        const Text('CURRENT BALANCE',
                            style: TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Text(
                          '₹${_formatLarge(currentBalance)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1),
                        ),

                        const SizedBox(height: 20),

                        // ── 3 stat pills ─────────────────────────────────
                        Row(
                          children: [
                            _StatPill(
                              label: 'Opening',
                              value:
                                  '₹${_formatLarge(monthData?.openingBalance ?? 0)}',
                              icon: Icons.account_balance_wallet_outlined,
                              onTap: () =>
                                  _editBalance(isOpening: true),
                            ),
                            const SizedBox(width: 8),
                            _StatPill(
                              label: 'Budget',
                              value: '₹${_formatLarge(totalBudget)}',
                              icon: Icons.pie_chart_outline,
                            ),
                            const SizedBox(width: 8),
                            _StatPill(
                              label: 'Spent',
                              value: '₹${_formatLarge(totalSpends)}',
                              icon: Icons.trending_down_outlined,
                              isNegative: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Loading bar ────────────────────────────────────────────────
            if (_isLoadingData)
              const SliverToBoxAdapter(
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: AppTheme.primary,
                  minHeight: 2,
                ),
              ),

            // ── Categories ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Budget Categories',
                subtitle: '${categories.length} categories this month',
                onAdd: () => showDialog(
                  context: context,
                  builder: (_) =>
                      AddCategoryDialog(monthKey: _monthKey),
                ),
                onRemove: categories.isNotEmpty
                    ? () {
                        final last = categories.last;
                        ref
                            .read(categoriesProvider.notifier)
                            .deleteCategory(last.id);
                        SnackbarService.show(context,
                            '"${last.name}" deleted.',
                            type: SnackType.info);
                      }
                    : null,
              ),
            ),

            if (categories.isEmpty)
              const SliverToBoxAdapter(
                child: _EmptyState(
                    icon: Icons.category_outlined,
                    message: 'No categories yet.\nTap + to add one.'),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final cat = categories[i];
                      final spent = txNotifier
                          .totalSpentForCategory(cat.id, creditCards);
                      return CategoryCard(
                        category: cat,
                        spent: spent,
                        onEdit: () => showDialog(
                          context: context,
                          builder: (_) => AddCategoryDialog(
                              monthKey: _monthKey, existing: cat),
                        ),
                        onDelete: () {
                          ref
                              .read(categoriesProvider.notifier)
                              .deleteCategory(cat.id);
                          SnackbarService.show(context,
                              '"${cat.name}" deleted.',
                              type: SnackType.info);
                        },
                      );
                    },
                    childCount: categories.length,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.45,
                    mainAxisSpacing: 0,
                    crossAxisSpacing: 0,
                  ),
                ),
              ),

            // ── Credit Card Spends ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Credit Card Spends',
                subtitle: '${creditCards.length} entries',
                onAdd: () => showDialog(
                  context: context,
                  builder: (_) =>
                      AddCreditCardDialog(monthKey: _monthKey),
                ),
              ),
            ),

            if (creditCards.isEmpty)
              const SliverToBoxAdapter(
                child: _EmptyState(
                    icon: Icons.credit_card_off_outlined,
                    message: 'No credit card entries yet.'),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => CreditCardTile(
                    item: creditCards[i],
                    onDelete: () {
                      ref
                          .read(creditCardsProvider.notifier)
                          .deleteCreditCard(creditCards[i].id);
                      SnackbarService.show(
                          context, 'Entry deleted.',
                          type: SnackType.info);
                    },
                  ),
                  childCount: creditCards.length,
                ),
              ),

            // ── Expense History ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Expense History',
                subtitle: transactions.isEmpty
                    ? 'No transactions'
                    : '${transactions.length} transactions',
                onAdd: () => showDialog(
                  context: context,
                  builder: (_) =>
                      AddTransactionDialog(monthKey: _monthKey),
                ),
              ),
            ),

            // Filter bar
            if (transactions.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TransactionFilterBar(
                    filter: _filter,
                    categories: categories,
                    onChanged: (f) => setState(() => _filter = f),
                  ),
                ),
              ),

            // Result count
            if (_filter.hasAny)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_alt_outlined,
                          size: 13, color: AppTheme.primaryLight),
                      const SizedBox(width: 6),
                      Text(
                        '${filteredTxs.length} of ${transactions.length} transactions',
                        style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(
                            () => _filter = const TransactionFilter()),
                        child: const Text('Clear',
                            style: TextStyle(
                                color: AppTheme.primaryLight,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ),

            if (transactions.isEmpty)
              const SliverToBoxAdapter(
                child: _EmptyState(
                    icon: Icons.receipt_long_outlined,
                    message:
                        'No transactions yet.\nTap + or the FAB to add one.'),
              )
            else if (filteredTxs.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(Icons.search_off,
                          color: AppTheme.textMuted, size: 44),
                      const SizedBox(height: 12),
                      const Text('No transactions match your filters.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 13)),
                      const SizedBox(height: 14),
                      TextButton.icon(
                        onPressed: () => setState(
                            () => _filter = const TransactionFilter()),
                        icon: const Icon(Icons.clear,
                            color: AppTheme.primaryLight, size: 16),
                        label: const Text('Clear Filters',
                            style: TextStyle(
                                color: AppTheme.primaryLight)),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => TransactionTile(
                    item: filteredTxs[i],
                    onDelete: () {
                      ref
                          .read(transactionsProvider.notifier)
                          .deleteTransaction(filteredTxs[i].id);
                      SnackbarService.show(
                          context, 'Transaction deleted.',
                          type: SnackType.info);
                    },
                  ),
                  childCount: filteredTxs.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),

      // ── FABs ──────────────────────────────────────────────────────────────
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Refresh FAB
          // FloatingActionButton.small(
          //   heroTag: 'refresh',
          //   onPressed: _isLoadingData ? null : _loadData,
          //   backgroundColor: AppTheme.cardBgAlt,
          //   tooltip: 'Refresh',
          //   child: _isLoadingData
          //       ? const SizedBox(
          //           width: 18,
          //           height: 18,
          //           child: CircularProgressIndicator(
          //               color: AppTheme.primaryLight, strokeWidth: 2),
          //         )
          //       : const Icon(Icons.refresh,
          //           color: AppTheme.primaryLight, size: 20),
          // ),
          const SizedBox(height: 10),
          // Add Expense FAB
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.cardGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              heroTag: 'add',
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AddTransactionDialog(monthKey: _monthKey),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Expense',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLarge(double val) {
    if (val >= 100000) return '${(val / 100000).toStringAsFixed(1)}L';
    if (val >= 1000)   return '${(val / 1000).toStringAsFixed(1)}K';
    return val.toStringAsFixed(0);
  }
}

// ─── Header Action Button ──────────────────────────────────────────────────────
class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _HeaderBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

// ─── Stat Pill (inside header) ─────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isNegative;
  final VoidCallback? onTap;

  const _StatPill({
    required this.label,
    required this.value,
    required this.icon,
    this.isNegative = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.white70, size: 13),
                  const SizedBox(width: 4),
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                          letterSpacing: 0.3)),
                  if (onTap != null) ...[
                    const Spacer(),
                    const Icon(Icons.edit_outlined,
                        color: Colors.white38, size: 11),
                  ],
                ],
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: TextStyle(
                    color: isNegative ? const Color(0xFFFF8A80) : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Icon(icon, color: AppTheme.textMuted, size: 26),
            ),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
