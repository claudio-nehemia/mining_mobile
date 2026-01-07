import 'package:flutter/material.dart';
import '../config/theme_config.dart';
import '../services/saldo_service.dart';
import 'package:intl/intl.dart';

class SaldoHistoryScreen extends StatefulWidget {
  const SaldoHistoryScreen({super.key});

  @override
  State<SaldoHistoryScreen> createState() => _SaldoHistoryScreenState();
}

class _SaldoHistoryScreenState extends State<SaldoHistoryScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('📋 Loading saldo requests...');
      final requests = await SaldoService.getMyRequests();
      debugPrint('📋 Loaded ${requests.length} requests');
      debugPrint('📋 Requests data: $requests');
      
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading requests: $e');
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'top_up':
        return Colors.green.shade400;
      case 'pemotongan':
        return Colors.red.shade400;
      default:
        return ThemeConfig.textSecondary;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'top_up':
        return Icons.add_circle_outline;
      case 'pemotongan':
        return Icons.remove_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'top_up':
        return 'Top Up';
      case 'pemotongan':
        return 'Pemotongan';
      default:
        return type;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green.shade400;
      case 'rejected':
        return Colors.red.shade400;
      case 'pending':
      default:
        return ThemeConfig.goldPrimary;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'DISETUJUI';
      case 'rejected':
        return 'DITOLAK';
      case 'pending':
      default:
        return 'PENDING';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.bgPrimary,
      appBar: AppBar(
        backgroundColor: ThemeConfig.bgSecondary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Riwayat Transaksi Saldo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadRequests,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: ThemeConfig.goldPrimary,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: ThemeConfig.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat data',
              style: TextStyle(
                color: ThemeConfig.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: ThemeConfig.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadRequests,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConfig.goldPrimary,
                foregroundColor: ThemeConfig.bgPrimary,
              ),
            ),
          ],
        ),
      );
    }

    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: ThemeConfig.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada riwayat transaksi',
              style: TextStyle(
                color: ThemeConfig.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: ThemeConfig.goldPrimary,
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final request = _requests[index];
          return _buildRequestCard(request);
        },
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final type = request['request_type'] ?? '';
    final amount = (request['amount'] as num?)?.toDouble() ?? 0.0;
    final createdAt = request['created_at'] ?? '';
    final status = request['status'] ?? 'pending';
    final notes = request['notes'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeConfig.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ThemeConfig.borderPrimary,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Type and Status
          Row(
            children: [
              Icon(
                _getTypeIcon(type),
                color: _getTypeColor(type),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                _getTypeLabel(type),
                style: TextStyle(
                  color: _getTypeColor(type),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStatusColor(status),
                    width: 1,
                  ),
                ),
                child: Text(
                  _getStatusLabel(status),
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Amount
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              color: ThemeConfig.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Date
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: ThemeConfig.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(createdAt),
                style: TextStyle(
                  color: ThemeConfig.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          // Notes (if rejected or have notes, but not for pemotongan)
          if (notes != null && notes.isNotEmpty && type != 'pemotongan') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ThemeConfig.bgSecondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ThemeConfig.borderSecondary.withOpacity(0.5),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: ThemeConfig.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      notes,
                      style: TextStyle(
                        color: ThemeConfig.textSecondary,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
