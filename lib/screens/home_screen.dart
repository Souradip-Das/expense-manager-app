// lib/screens/home_screen.dart
import 'package:expense_tracker/screens/auth_gate.dart';
import 'package:flutter/material.dart';
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
    // Reset filter when month changes
    if (mounted)
      setState(() {
        _isLoadingData = false;
        _filter = const TransactionFilter();
      });
  }

  String get _monthKey => ref.read(selectedMonthProvider.notifier).monthKey;

  void _changeMonth(int delta) {
    if (delta > 0) {
      ref.read(selectedMonthProvider.notifier).nextMonth();
    } else {
      ref.read(selectedMonthProvider.notifier).prevMonth();
    }
    _loadData();
  }

  //Apply filters
  List<TransactionModel> _applyFilter(List<TransactionModel> txs) {
    return txs.where((tx) {
      // Category filter
      if (_filter.category != null && tx.categoryId != _filter.category!.id) {
        return false;
      }
      // Date filter — match exact day
      if (_filter.date != null) {
        final d = _filter.date!;
        if (tx.date.year != d.year ||
            tx.date.month != d.month ||
            tx.date.day != d.day) {
          return false;
        }
      }
      // Min amount filter
      if (_filter.minAmount != null && tx.amount < _filter.minAmount!) {
        return false;
      }
      // Max amount filter
      if (_filter.maxAmount != null && tx.amount > _filter.maxAmount!) {
        return false;
      }
      return true;
    }).toList();
  }

  //Balance edit
  Future<void> _editBalance({required bool isOpening}) async {
    final monthData = ref.read(monthDataProvider);
    final currentVal = isOpening
        ? (monthData?.openingBalance ?? 0)
        : ref.read(currentBalanceProvider);
    final ctrl = TextEditingController(text: currentVal.toStringAsFixed(0));

    final result = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          isOpening ? 'Set Opening Balance' : 'Adjust Balance',
          style: const TextStyle(color: Colors.white),
        ),
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
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, double.tryParse(ctrl.text)),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
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
          SnackbarService.show(
            context,
            'Opening balance set to ₹${result.toStringAsFixed(0)}',
          );
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

  //Sign out
  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.white),
            ),
          ),
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
    final selectedMonth = ref.watch(selectedMonthProvider);
    final monthData = ref.watch(monthDataProvider);
    final categories = ref.watch(categoriesProvider);
    final transactions = ref.watch(transactionsProvider);
    final creditCards = ref.watch(creditCardsProvider);
    final currentBalance = ref.watch(currentBalanceProvider);
    final totalBudget = ref.watch(totalBudgetProvider);
    final txNotifier = ref.read(transactionsProvider.notifier);
    final user = ref.watch(currentUserProvider);

    // Total spends = daily transactions + CC spends
    final totalTxSpend = transactions.fold<double>(0, (s, t) => s + t.amount);
    final totalCCSpend = creditCards.fold<double>(0, (s, c) => s + c.amount);
    final totalSpends = totalTxSpend + totalCCSpend;

    final monthLabel = DateFormat('MMMM yyyy').format(selectedMonth);
    final filteredTxs = _applyFilter(transactions);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            //App Bar
            Container(
              color: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: () => _changeMonth(-1),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          monthLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (user != null)
                          Text(
                            user.displayName ?? user.email ?? '',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: () => _changeMonth(1),
                  ),
                  IconButton(
                    tooltip: 'Export / Import',
                    icon: const Icon(Icons.import_export, color: Colors.white),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ExportImportScreen(),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sign Out',
                    icon: const Icon(Icons.logout, color: Colors.white70),
                    onPressed: _confirmSignOut,
                  ),
                ],
              ),
            ),

            //Loading bar 
            if (_isLoadingData)
              const LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                color: AppTheme.primary,
                minHeight: 2,
              ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: AppTheme.primary,
                backgroundColor: const Color(0xFF1A1A1A),
                child: ListView(
                  children: [
                    //Balance Cards
                    Container(
                      color: AppTheme.bgColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              BalanceCard(
                                label: 'Opening Balance',
                                amount: monthData?.openingBalance ?? 0,
                                icon: Icons.account_balance_wallet_outlined,
                                onEdit: () => _editBalance(isOpening: true),
                              ),
                              BalanceCard(
                                label: 'Current Balance',
                                amount: currentBalance,
                                icon: Icons.savings_outlined,
                                onEdit: () => _editBalance(isOpening: false),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: BalanceCard(
                                    label: 'Total Budget',
                                    amount: totalBudget,
                                    icon: Icons.pie_chart_outline,
                                    isReadOnly: true,
                                    fullWidth: true,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: BalanceCard(
                                    label: 'Total Spends',
                                    amount: totalSpends,
                                    icon: Icons.trending_down_outlined,
                                    isReadOnly: true,
                                    fullWidth: true,
                                    isNegative: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    //Categories
                    SectionHeader(
                      title: 'Category (Budget For the Month)',
                      onAdd: () => showDialog(
                        context: context,
                        builder: (_) => AddCategoryDialog(monthKey: _monthKey),
                      ),
                      onRemove: categories.isNotEmpty
                          ? () {
                              final last = categories.last;
                              ref
                                  .read(categoriesProvider.notifier)
                                  .deleteCategory(last.id);
                              SnackbarService.show(
                                context,
                                '"${last.name}" category deleted.',
                                type: SnackType.info,
                              );
                            }
                          : null,
                    ),

                    if (categories.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'No categories yet. Tap + to add.',
                            style: TextStyle(color: Colors.white38),
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(4),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1.5,
                              mainAxisSpacing: 4,
                              crossAxisSpacing: 4,
                            ),
                        itemCount: categories.length,
                        itemBuilder: (ctx, i) {
                          final cat = categories[i];
                          final spent = txNotifier.totalSpentForCategory(
                            cat.id,
                            creditCards,
                          );
                          return CategoryCard(
                            category: cat,
                            spent: spent,
                            onEdit: () => showDialog(
                              context: context,
                              builder: (_) => AddCategoryDialog(
                                monthKey: _monthKey,
                                existing: cat,
                              ),
                            ),
                            onDelete: () {
                              ref
                                  .read(categoriesProvider.notifier)
                                  .deleteCategory(cat.id);
                              SnackbarService.show(
                                context,
                                '"${cat.name}" category deleted.',
                                type: SnackType.info,
                              );
                            },
                          );
                        },
                      ),

                    const SizedBox(height: 6),

                    //Credit Card Spends
                    SectionHeader(
                      title: 'Credit Card Spends',
                      onAdd: () => showDialog(
                        context: context,
                        builder: (_) =>
                            AddCreditCardDialog(monthKey: _monthKey),
                      ),
                    ),

                    if (creditCards.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'No credit card entries.',
                            style: TextStyle(color: Colors.white38),
                          ),
                        ),
                      )
                    else
                      ...creditCards.map(
                        (cc) => CreditCardTile(
                          item: cc,
                          onDelete: () {
                            ref
                                .read(creditCardsProvider.notifier)
                                .deleteCreditCard(cc.id);
                            SnackbarService.show(
                              context,
                              'Credit card entry deleted.',
                              type: SnackType.info,
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 6),

                    //Expense History
                    SectionHeader(
                      title: 'Expense History',
                      onAdd: () => showDialog(
                        context: context,
                        builder: (_) =>
                            AddTransactionDialog(monthKey: _monthKey),
                      ),
                    ),

                    //Filter Bar
                    if (transactions.isNotEmpty)
                      TransactionFilterBar(
                        filter: _filter,
                        categories: categories,
                        onChanged: (f) => setState(() => _filter = f),
                      ),

                    //Result count when filter active
                    if (_filter.hasAny)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.filter_alt_outlined,
                              size: 14,
                              color: AppTheme.primaryLight,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${filteredTxs.length} of ${transactions.length} transactions',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                    //Transaction list
                    if (transactions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'No transactions yet.',
                            style: TextStyle(color: Colors.white38),
                          ),
                        ),
                      )
                    else if (filteredTxs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off,
                                color: AppTheme.textMuted,
                                size: 40,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'No transactions match\nyour filters.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: () => setState(
                                  () => _filter = const TransactionFilter(),
                                ),
                                icon: const Icon(
                                  Icons.clear,
                                  color: AppTheme.primaryLight,
                                  size: 16,
                                ),
                                label: const Text(
                                  'Clear Filters',
                                  style: TextStyle(
                                    color: AppTheme.primaryLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...filteredTxs.map(
                        (tx) => TransactionTile(
                          item: tx,
                          onDelete: () {
                            ref
                                .read(transactionsProvider.notifier)
                                .deleteTransaction(tx.id);
                            SnackbarService.show(
                              context,
                              'Transaction deleted.',
                              type: SnackType.info,
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          //Refresh button
          FloatingActionButton.small(
            heroTag: 'refresh',
            onPressed: _isLoadingData ? null : _loadData,
            backgroundColor: const Color(0xFF2A2A2A),
            tooltip: 'Refresh data',
            child: _isLoadingData
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryLight,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.refresh,
                    color: AppTheme.primaryLight,
                    size: 20,
                  ),
          ),
          const SizedBox(height: 10),
          //Add Expense button
          FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AddTransactionDialog(monthKey: _monthKey),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Add Expense',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }
}
