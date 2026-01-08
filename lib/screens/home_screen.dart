import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/theme_config.dart';
import '../providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../services/saldo_service.dart';
import '../widgets/checkout_modal.dart';
import 'profile_screen.dart';
import 'saldo_history_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _isTogglingStatus = false;
  bool _isCheckingIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<HomeProvider>(context, listen: false);
      provider.loadHomeData();
      provider.loadCheckInStatus();
      // Start auto-refresh setelah load initial data
      provider.startAutoRefresh();
    });
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Stop auto-refresh saat screen di-dispose
    final provider = Provider.of<HomeProvider>(context, listen: false);
    provider.stopAutoRefresh();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final provider = Provider.of<HomeProvider>(context, listen: false);
    
    // Pause auto-refresh saat app di background, resume saat kembali foreground
    if (state == AppLifecycleState.resumed) {
      provider.startAutoRefresh();
    } else if (state == AppLifecycleState.paused) {
      provider.stopAutoRefresh();
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

  Future<void> _performCheckIn() async {
    if (_isCheckingIn) return;
    
    setState(() {
      _isCheckingIn = true;
    });

    try {
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      final result = await homeProvider.checkIn();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Check-in berhasil di ${result?['checkpoint_name'] ?? 'checkpoint'}\n'
              'Jarak: ${result?['distance']?.toStringAsFixed(2) ?? '0'} km',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        
        // Jika error panjang, tampilkan di dialog
        if (errorMessage.length > 80) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: ThemeConfig.bgCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: const [
                  Icon(Icons.error_outline, color: Colors.red, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Check-in Gagal',
                    style: TextStyle(
                      color: ThemeConfig.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Text(
                errorMessage,
                style: const TextStyle(
                  color: ThemeConfig.textSecondary,
                  fontSize: 14,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: ThemeConfig.goldPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingIn = false;
        });
      }
    }
  }

  void _showCheckoutModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: const CheckoutModal(),
        ),
      ),
    );
  }

  void _showTopUpDialog(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ThemeConfig.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Request Top Up Saldo',
            style: TextStyle(
              color: ThemeConfig.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Masukkan jumlah top up:',
                  style: TextStyle(
                    color: ThemeConfig.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: TextStyle(color: ThemeConfig.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Contoh: 100000',
                    hintStyle: TextStyle(color: ThemeConfig.textSecondary.withOpacity(0.5)),
                    prefixText: 'Rp ',
                    prefixStyle: TextStyle(
                      color: ThemeConfig.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    filled: true,
                    fillColor: ThemeConfig.bgSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: ThemeConfig.textSecondary.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: ThemeConfig.goldPrimary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.red,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Jumlah harus diisi';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null) {
                      return 'Format jumlah tidak valid';
                    }
                    if (amount < 10000) {
                      return 'Minimal top up Rp 10.000';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '* Minimal top up Rp 10.000',
                  style: TextStyle(
                    color: ThemeConfig.textSecondary.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Batal',
                style: TextStyle(
                  color: ThemeConfig.textSecondary,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final amount = double.parse(amountController.text);
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  
                  // Close input dialog first
                  navigator.pop();

                  // Show loading
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (loadingContext) => Center(
                      child: CircularProgressIndicator(
                        color: ThemeConfig.goldPrimary,
                      ),
                    ),
                  );

                  try {
                    await SaldoService.requestTopUp(amount);

                    // Hide loading
                    navigator.pop();

                    // Show success message
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Request top up berhasil dikirim!',
                          style: TextStyle(color: ThemeConfig.textPrimary),
                        ),
                        backgroundColor: Colors.green.shade700,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  } catch (e) {
                    // Hide loading
                    navigator.pop();

                    // Show error message
                    final errorMessage = e.toString().replaceAll('Exception: ', '');
                    
                    // Jika error panjang, tampilkan di dialog
                    if (errorMessage.length > 80) {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          backgroundColor: ThemeConfig.bgCard,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Row(
                            children: const [
                              Icon(Icons.error_outline, color: Colors.red, size: 28),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Request Gagal',
                                  style: TextStyle(
                                    color: ThemeConfig.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          content: Text(
                            errorMessage,
                            style: const TextStyle(
                              color: ThemeConfig.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text(
                                'OK',
                                style: TextStyle(
                                  color: ThemeConfig.goldPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            errorMessage,
                            style: TextStyle(color: ThemeConfig.textPrimary),
                          ),
                          backgroundColor: Colors.red.shade700,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConfig.goldPrimary,
                foregroundColor: ThemeConfig.bgPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Kirim Request',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ThemeConfig.bgPrimary,
              ThemeConfig.bgSecondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer2<AuthProvider, HomeProvider>(
            builder: (context, authProvider, homeProvider, child) {
              final driver = authProvider.driver;

              return CustomScrollView(
                slivers: [
                  // App Bar
                  SliverAppBar(
                    floating: true,
                    backgroundColor: ThemeConfig.bgSecondary,
                    elevation: 0,
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.local_shipping,
                              color: ThemeConfig.goldPrimary,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'CHECKPOINT',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const Text(
                          'Driver App',
                          style: TextStyle(
                            fontSize: 10,
                            color: ThemeConfig.textSecondary,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      // Auto-refresh indicator
                      Consumer<HomeProvider>(
                        builder: (context, homeProvider, _) {
                          return IconButton(
                            icon: Icon(
                              homeProvider.isAutoRefreshEnabled 
                                ? Icons.sync 
                                : Icons.sync_disabled,
                              color: homeProvider.isAutoRefreshEnabled 
                                ? ThemeConfig.goldPrimary 
                                : ThemeConfig.textSecondary,
                            ),
                            onPressed: () {
                              final enabled = !homeProvider.isAutoRefreshEnabled;
                              homeProvider.toggleAutoRefresh(enabled);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    enabled 
                                      ? 'Auto-refresh diaktifkan (setiap 10 detik)' 
                                      : 'Auto-refresh dinonaktifkan',
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            tooltip: homeProvider.isAutoRefreshEnabled 
                              ? 'Nonaktifkan auto-refresh' 
                              : 'Aktifkan auto-refresh',
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          Provider.of<HomeProvider>(context, listen: false).loadHomeData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Memuat ulang data...'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        tooltip: 'Refresh',
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_outline),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileScreen(),
                            ),
                          );
                        },
                        tooltip: 'Profile',
                      ),
                    ],
                  ),

                  // Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Driver Info Card
                          _buildDriverInfoCard(driver, homeProvider),
                          const SizedBox(height: 16),

                          // Saldo Card
                          _buildSaldoCard(homeProvider),
                          const SizedBox(height: 16),

                          // Status Toggle Card
                          _buildStatusCard(driver, authProvider, homeProvider),
                          const SizedBox(height: 16),

                          // Check-In Status or GPS Location
                          if (homeProvider.isCheckedIn)
                            _buildCheckedInCard(homeProvider)
                          else
                            _buildGPSCard(),
                          const SizedBox(height: 16),

                          // Check-In/Out Button
                          _buildCheckInButton(homeProvider),
                          const SizedBox(height: 16),

                          // Checkpoint Terdekat
                          _buildNearbyCheckpoints(homeProvider),
                          const SizedBox(height: 16),

                          // Riwayat Hari Ini
                          _buildTodayHistory(homeProvider),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDriverInfoCard(driver, HomeProvider homeProvider) {
    final homeData = homeProvider.homeData;
    final truck = homeData?.truck;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: ThemeConfig.goldPrimary,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.person,
                size: 28,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver?.name ?? 'Driver',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ThemeConfig.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    truck != null
                        ? '${truck.noUnit} • ${truck.plateNumber}'
                        : 'No Truck Assigned',
                    style: const TextStyle(
                      fontSize: 12,
                      color: ThemeConfig.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: homeProvider.isCheckedIn
                    ? ThemeConfig.successColor.withOpacity(0.15)
                    : ThemeConfig.textSecondary.withOpacity(0.15),
                border: Border.all(
                  color: homeProvider.isCheckedIn
                      ? ThemeConfig.successColor
                      : ThemeConfig.textSecondary,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                homeProvider.isCheckedIn ? 'On Location' : 'Off Duty',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: homeProvider.isCheckedIn
                      ? ThemeConfig.successColor
                      : ThemeConfig.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaldoCard(HomeProvider homeProvider) {
    final saldo = homeProvider.homeData?.saldo;
    final amount = saldo?.amount ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: ThemeConfig.goldPrimary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: ThemeConfig.goldPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saldo Uang Jalan',
                        style: TextStyle(
                          fontSize: 10,
                          color: ThemeConfig.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(amount),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: ThemeConfig.goldPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showTopUpDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Top Up'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeConfig.goldPrimary.withOpacity(0.15),
                      foregroundColor: ThemeConfig.goldPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: ThemeConfig.goldPrimary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SaldoHistoryScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history, size: 18),
                    label: const Text('Riwayat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeConfig.bgSecondary,
                      foregroundColor: ThemeConfig.textPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: ThemeConfig.borderSecondary,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(driver, AuthProvider authProvider, HomeProvider homeProvider) {
    final isActive = driver?.status == 'active';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isActive
                    ? ThemeConfig.successColor.withOpacity(0.15)
                    : ThemeConfig.errorColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.power_settings_new,
                color: isActive ? ThemeConfig.successColor : ThemeConfig.errorColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status: ${isActive ? "ON" : "OFF"}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ThemeConfig.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isActive ? 'Siap bertugas' : 'Tidak bertugas',
                    style: const TextStyle(
                      fontSize: 11,
                      color: ThemeConfig.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            _isTogglingStatus
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ThemeConfig.goldPrimary,
                      ),
                    ),
                  )
                : Switch(
                    value: isActive,
                    onChanged: (value) async {
                      setState(() {
                        _isTogglingStatus = true;
                      });
                      
                      try {
                        final homeProvider = Provider.of<HomeProvider>(context, listen: false);
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        
                        bool success;
                        if (value) {
                          success = await homeProvider.turnOnStatus();
                        } else {
                          success = await homeProvider.turnOffStatus();
                        }
                        
                        if (success) {
                          // Reload driver data
                          await authProvider.loadProfile();
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Status berhasil diubah menjadi ${value ? "ON" : "OFF"}',
                                ),
                                backgroundColor: ThemeConfig.successColor,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        } else {
                          if (mounted) {
                            final errorMessage = homeProvider.errorMessage ?? 'Gagal mengubah status';
                            
                            // Tampilkan error di dialog jika panjang
                            if (errorMessage.length > 80) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: ThemeConfig.bgCard,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: Row(
                                    children: const [
                                      Icon(Icons.error_outline, color: Colors.red, size: 28),
                                      SizedBox(width: 12),
                                      Text(
                                        'Error',
                                        style: TextStyle(
                                          color: ThemeConfig.textPrimary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Text(
                                    errorMessage,
                                    style: const TextStyle(
                                      color: ThemeConfig.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text(
                                        'OK',
                                        style: TextStyle(
                                          color: ThemeConfig.goldPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMessage),
                                  backgroundColor: ThemeConfig.errorColor,
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          final errorMessage = e.toString().replaceAll('Exception: ', '');
                          
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: ThemeConfig.bgCard,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: Row(
                                children: const [
                                  Icon(Icons.error_outline, color: Colors.red, size: 28),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Error',
                                      style: TextStyle(
                                        color: ThemeConfig.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              content: Text(
                                errorMessage,
                                style: const TextStyle(
                                  color: ThemeConfig.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    'OK',
                                    style: TextStyle(
                                      color: ThemeConfig.goldPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isTogglingStatus = false;
                          });
                        }
                      }
                    },
                    activeColor: ThemeConfig.goldPrimary,
                    activeTrackColor: ThemeConfig.goldPrimary.withOpacity(0.5),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckedInCard(HomeProvider homeProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Checked-In at',
              style: TextStyle(
                fontSize: 10,
                color: ThemeConfig.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: ThemeConfig.successColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        homeProvider.currentCheckpoint ?? 'Checkpoint',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ThemeConfig.textPrimary,
                        ),
                      ),
                      Text(
                        'Sejak ${homeProvider.checkInTime ?? '-'}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: ThemeConfig.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGPSCard() {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        final position = homeProvider.currentPosition;
        final isRealGPS = position != null;
        final lat = position?.latitude ?? -6.2088;
        final lng = position?.longitude ?? 106.8456;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isRealGPS 
                        ? ThemeConfig.successColor.withOpacity(0.15)
                        : const Color(0xFFFF9800).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.gps_fixed,
                    color: isRealGPS 
                        ? ThemeConfig.successColor 
                        : const Color(0xFFFF9800),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRealGPS ? 'Lokasi GPS Real' : 'Lokasi GPS (Dummy - Jakarta)',
                        style: const TextStyle(
                          fontSize: 10,
                          color: ThemeConfig.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: ThemeConfig.textPrimary,
                        ),
                      ),
                      if (!isRealGPS) ...[
                        const SizedBox(height: 2),
                        const Text(
                          'GPS tidak tersedia, menggunakan koordinat default',
                          style: TextStyle(
                            fontSize: 9,
                            color: Color(0xFFFF9800),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isRealGPS
                        ? ThemeConfig.successColor.withOpacity(0.15)
                        : const Color(0xFFFF9800).withOpacity(0.15),
                    border: Border.all(
                      color: isRealGPS 
                          ? ThemeConfig.successColor 
                          : const Color(0xFFFF9800),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isRealGPS ? 'Aktif' : 'Dummy',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isRealGPS 
                          ? ThemeConfig.successColor 
                          : const Color(0xFFFF9800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCheckInButton(HomeProvider homeProvider) {
    // Show status jika ada pending/rejected request
    if (homeProvider.isCheckedIn && homeProvider.checkoutRequestStatus != null) {
      final status = homeProvider.checkoutRequestStatus;
      
      if (status == 'pending') {
        return Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            border: Border.all(color: Colors.orange),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Menunggu Persetujuan Checkout',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (status == 'rejected') {
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _showCheckoutModal,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh, size: 20),
                SizedBox(width: 12),
                Text(
                  'Request Checkout Ditolak - Coba Lagi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: homeProvider.isCheckedIn 
            ? _showCheckoutModal 
            : (_isCheckingIn ? null : _performCheckIn),
        style: ElevatedButton.styleFrom(
          backgroundColor: homeProvider.isCheckedIn 
              ? Colors.orange 
              : ThemeConfig.goldPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: ThemeConfig.textSecondary,
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: _isCheckingIn
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    homeProvider.isCheckedIn ? Icons.logout : Icons.login,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    homeProvider.isCheckedIn ? 'REQUEST CHECK-OUT' : 'CHECK-IN',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildNearbyCheckpoints(HomeProvider homeProvider) {
    final checkpoints = homeProvider.nearbyCheckpoints;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(
              Icons.location_on_outlined,
              color: ThemeConfig.goldPrimary,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'CHECKPOINT TERDEKAT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ThemeConfig.goldPrimary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (checkpoints.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Tidak ada checkpoint terdekat',
                  style: TextStyle(
                    fontSize: 12,
                    color: ThemeConfig.textSecondary,
                  ),
                ),
              ),
            ),
          )
        else
          ...checkpoints.take(3).map((checkpoint) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    leading: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: checkpoint.distance < 0.1
                            ? ThemeConfig.successColor
                            : ThemeConfig.goldPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      checkpoint.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: ThemeConfig.textPrimary,
                      ),
                    ),
                    trailing: Text(
                      checkpoint.distanceText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ThemeConfig.textSecondary,
                      ),
                    ),
                  ),
                ),
              )),
      ],
    );
  }

  Widget _buildTodayHistory(HomeProvider homeProvider) {
    final history = homeProvider.todayHistory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(
              Icons.history,
              color: ThemeConfig.goldPrimary,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'RIWAYAT HARI INI',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ThemeConfig.goldPrimary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (history.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Belum ada aktivitas hari ini',
                  style: TextStyle(
                    fontSize: 12,
                    color: ThemeConfig.textSecondary,
                  ),
                ),
              ),
            ),
          )
        else
          ...history.map((activity) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: activity.lastActivity == 'check_out'
                            ? ThemeConfig.goldPrimary.withOpacity(0.15)
                            : ThemeConfig.successColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        activity.lastActivity == 'check_out'
                            ? Icons.logout
                            : Icons.login,
                        color: activity.lastActivity == 'check_out'
                            ? ThemeConfig.goldPrimary
                            : ThemeConfig.successColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      activity.checkpointName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: ThemeConfig.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '${activity.lastActivity == "check_out" ? "Check-Out" : "Check-In"}${activity.duration != null ? " • ${activity.duration}" : ""}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: ThemeConfig.textSecondary,
                      ),
                    ),
                    trailing: Text(
                      activity.time,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: ThemeConfig.textPrimary,
                      ),
                    ),
                  ),
                ),
              )),
      ],
    );
  }
}
