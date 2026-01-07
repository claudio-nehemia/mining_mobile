import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../config/theme_config.dart';
import '../services/checkout_service.dart';
import '../services/location_service.dart';

class CheckoutModal extends StatefulWidget {
  const CheckoutModal({super.key});

  @override
  State<CheckoutModal> createState() => _CheckoutModalState();
}

class _CheckoutModalState extends State<CheckoutModal> {
  final _formKey = GlobalKey<FormState>();
  final _materialController = TextEditingController();
  final _kubikasiController = TextEditingController();
  final _kernetController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLoadingCheckpoints = true;
  List<Map<String, dynamic>> _checkpoints = [];
  Map<String, dynamic>? _selectedCheckpoint;
  Map<String, dynamic>? _activeCheckIn;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _materialController.dispose();
    _kubikasiController.dispose();
    _kernetController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Get active check-in
      final activeCheckIn = await CheckoutService.getActiveCheckIn();
      
      // Get GPS location
      Position? position = await LocationService.getCurrentLocation();
      position ??= await LocationService.getLastKnownLocation();
      
      if (position == null) {
        throw Exception('Tidak dapat mengambil lokasi GPS');
      }
      
      // Get checkout checkpoints
      final checkpoints = await CheckoutService.getCheckoutCheckpoints(
        position.latitude,
        position.longitude,
      );
      
      if (mounted) {
        setState(() {
          _activeCheckIn = activeCheckIn;
          _checkpoints = checkpoints;
          _isLoadingCheckpoints = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCheckpoints = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
        
        Navigator.pop(context);
      }
    }
  }

  Future<void> _submitCheckout() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCheckpoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih checkpoint tujuan terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final result = await CheckoutService.requestCheckout(
        checkoutCheckpointId: _selectedCheckpoint!['id'],
        namaMaterial: _materialController.text,
        jumlahKubikasi: double.parse(_kubikasiController.text),
        namaKernet: _kernetController.text.isEmpty ? null : _kernetController.text,
      );
      
      if (mounted) {
        Navigator.pop(context, true);
        
        // Parse biaya sebagai double dari string atau number
        final biayaRaw = result['biaya_pemotongan'] ?? result['biaya'] ?? 0;
        final biaya = biayaRaw is String ? double.tryParse(biayaRaw) ?? 0 : (biayaRaw as num).toDouble();
        
        final formatter = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Request checkout berhasil!\n'
              'Biaya: ${formatter.format(biaya)}\n'
              'Menunggu approval admin.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ThemeConfig.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ThemeConfig.goldPrimary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ThemeConfig.goldPrimary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.logout,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Check-Out',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: ThemeConfig.textPrimary,
                          ),
                        ),
                        if (_activeCheckIn != null)
                          Text(
                            'Dari: ${_activeCheckIn!['checkpoint_name']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: ThemeConfig.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: ThemeConfig.textSecondary,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: _isLoadingCheckpoints
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: ThemeConfig.goldPrimary,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Checkpoint Dropdown
                            const Text(
                              'Checkpoint Tujuan *',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: ThemeConfig.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<Map<String, dynamic>>(
                              value: _selectedCheckpoint,
                              decoration: InputDecoration(
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
                                  borderSide: const BorderSide(
                                    color: ThemeConfig.goldPrimary,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              dropdownColor: ThemeConfig.bgCard,
                              style: const TextStyle(
                                color: ThemeConfig.textPrimary,
                              ),
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: ThemeConfig.goldPrimary,
                              ),
                              hint: const Text(
                                'Pilih checkpoint tujuan',
                                style: TextStyle(
                                  color: ThemeConfig.textSecondary,
                                ),
                              ),
                              items: _checkpoints.map((checkpoint) {
                                return DropdownMenuItem<Map<String, dynamic>>(
                                  value: checkpoint,
                                  child: Text(
                                    '${checkpoint['name']} (${checkpoint['distance_text']})',
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCheckpoint = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Checkpoint harus dipilih';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Material Name
                            const Text(
                              'Nama Material *',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: ThemeConfig.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _materialController,
                              style: const TextStyle(color: ThemeConfig.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Contoh: Pasir, Batu, dll',
                                hintStyle: TextStyle(
                                  color: ThemeConfig.textSecondary.withOpacity(0.5),
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
                                  borderSide: const BorderSide(
                                    color: ThemeConfig.goldPrimary,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Nama material harus diisi';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Kubikasi
                            const Text(
                              'Jumlah Kubikasi (m³) *',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: ThemeConfig.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _kubikasiController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                              style: const TextStyle(color: ThemeConfig.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Contoh: 5.5',
                                hintStyle: TextStyle(
                                  color: ThemeConfig.textSecondary.withOpacity(0.5),
                                ),
                                suffixText: 'm³',
                                suffixStyle: const TextStyle(
                                  color: ThemeConfig.goldPrimary,
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
                                  borderSide: const BorderSide(
                                    color: ThemeConfig.goldPrimary,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Jumlah kubikasi harus diisi';
                                }
                                final kubikasi = double.tryParse(value);
                                if (kubikasi == null || kubikasi <= 0) {
                                  return 'Jumlah kubikasi harus lebih dari 0';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Kernet Name (Optional)
                            const Text(
                              'Nama Kernet (Opsional)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: ThemeConfig.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _kernetController,
                              style: const TextStyle(color: ThemeConfig.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Nama kernet (jika ada)',
                                hintStyle: TextStyle(
                                  color: ThemeConfig.textSecondary.withOpacity(0.5),
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
                                  borderSide: const BorderSide(
                                    color: ThemeConfig.goldPrimary,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Info Box
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: ThemeConfig.goldPrimary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: ThemeConfig.goldPrimary.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons.info_outline,
                                    color: ThemeConfig.goldPrimary,
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Request checkout akan dikirim ke admin untuk approval. Biaya rute akan dipotong dari saldo.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: ThemeConfig.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            
            // Footer Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: ThemeConfig.textSecondary.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ThemeConfig.textPrimary,
                        side: BorderSide(
                          color: ThemeConfig.textSecondary.withOpacity(0.3),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading || _isLoadingCheckpoints ? null : _submitCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeConfig.goldPrimary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            )
                          : const Text(
                              'Kirim Request',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
