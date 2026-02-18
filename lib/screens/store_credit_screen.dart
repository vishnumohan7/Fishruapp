import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_providers.dart';
import '../providers/store_credit_provider.dart';
import '../models/store_credit.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';

class StoreCreditScreen extends StatefulWidget {
  const StoreCreditScreen({super.key});

  @override
  State<StoreCreditScreen> createState() => _StoreCreditScreenState();
}

class _StoreCreditScreenState extends State<StoreCreditScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final storeCreditProvider = Provider.of<StoreCreditProvider>(context, listen: false);
      
      if (userProvider.user != null) {
        storeCreditProvider.fetchStoreCredit(
          userProvider.user!.id,
          customerEmail: userProvider.user!.email,
        );
        storeCreditProvider.fetchTransactions(userProvider.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isDesktop = size.width > 900;
    final padding = isTablet ? 24.0 : 16.0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Store Credit',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: isTablet ? 22 : 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Consumer2<UserProvider, StoreCreditProvider>(
        builder: (context, userProvider, storeCreditProvider, child) {
          if (userProvider.user == null) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: isTablet ? 64 : 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Please log in to view your store credit',
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await storeCreditProvider.fetchStoreCredit(
                userProvider.user!.id,
                customerEmail: userProvider.user!.email,
              );
              await storeCreditProvider.fetchTransactions(userProvider.user!.id);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isTablet ? 800 : double.infinity,
                  ),
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBalanceCard(context, storeCreditProvider, isTablet, isDesktop),
                      SizedBox(height: isTablet ? 32 : 24),
                      _buildTransactionsSection(context, storeCreditProvider, isTablet, isDesktop, padding),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, StoreCreditProvider provider, bool isTablet, bool isDesktop) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withOpacity(0.1),
              AppTheme.primaryColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        ),
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 16 : 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    size: isTablet ? 40 : 32,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 20 : 16),
            Text(
              'Available Balance',
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: isTablet ? 12 : 8),
            if (provider.isLoading)
              const CircularProgressIndicator()
            else
              Text(
                '₹${provider.balance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: isTablet ? 48 : 40,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            if (provider.storeCredit != null) ...[
              SizedBox(height: isTablet ? 12 : 8),
              Text(
                'Last updated: ${_formatDate(provider.storeCredit!.lastUpdated)}',
                style: TextStyle(
                  fontSize: isTablet ? 13 : 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsSection(BuildContext context, StoreCreditProvider provider, bool isTablet, bool isDesktop, double padding) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction History',
                  style: TextStyle(
                    fontSize: isTablet ? 22 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (provider.isLoadingTransactions)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            SizedBox(height: isTablet ? 20 : 16),
            if (provider.isLoadingTransactions && provider.transactions.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(isTablet ? 36 : 28),
                  child: const CircularProgressIndicator(),
                ),
              )
            else if (provider.transactions.isEmpty)
              Container(
                padding: EdgeInsets.all(isTablet ? 36 : 28),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: isTablet ? 56 : 48,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: isTablet ? 16 : 12),
                      Text(
                        'No transactions yet',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                          fontSize: isTablet ? 18 : 16,
                        ),
                      ),
                      SizedBox(height: isTablet ? 6 : 4),
                      Text(
                        'Your store credit transactions will appear here',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: isTablet ? 15 : 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: provider.transactions.map((transaction) {
                  return _buildTransactionItem(context, transaction, isTablet);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, StoreCreditTransaction transaction, bool isTablet) {
    final isCredit = transaction.isCredit;
    final color = isCredit ? Colors.green : Colors.red;
    final icon = isCredit ? Icons.add_circle : Icons.remove_circle;

    return Padding(
      padding: EdgeInsets.only(bottom: isTablet ? 16 : 12),
      child: Container(
        padding: EdgeInsets.all(isTablet ? 18 : 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 12 : 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: isTablet ? 24 : 20,
              ),
            ),
            SizedBox(width: isTablet ? 16 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description ?? (isCredit ? 'Credit Added' : 'Credit Used'),
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: isTablet ? 4 : 2),
                  Row(
                    children: [
                      Text(
                        _formatDate(transaction.createdAt),
                        style: TextStyle(
                          fontSize: isTablet ? 13 : 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (transaction.orderId != null) ...[
                        SizedBox(width: isTablet ? 8 : 6),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 6 : 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Order: ${transaction.orderId}',
                            style: TextStyle(
                              fontSize: isTablet ? 11 : 10,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '${isCredit ? '+' : '-'}₹${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
