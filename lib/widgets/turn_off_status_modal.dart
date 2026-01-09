import 'package:flutter/material.dart';
import '../config/theme_config.dart';

class TurnOffStatusModal extends StatefulWidget {
  const TurnOffStatusModal({super.key});

  @override
  State<TurnOffStatusModal> createState() => _TurnOffStatusModalState();
}

class _TurnOffStatusModalState extends State<TurnOffStatusModal> {
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedReason;
  final TextEditingController _detailController = TextEditingController();
  
  final List<String> _reasons = [
    'Rusak Mesin',
    'Pecah Ban',
    'Perawatan Rutin',
    'Kendala Lalu Lintas',
    'Lainnya',
  ];

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Return data ke screen
      Navigator.of(context).pop({
        'reason_type': _selectedReason,
        'reason_detail': _selectedReason == 'Lainnya' ? _detailController.text : null,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ThemeConfig.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.warning_rounded,
                      color: Colors.orange,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Matikan Status',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: ThemeConfig.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Pilih alasan menonaktifkan status',
                          style: TextStyle(
                            fontSize: 12,
                            color: ThemeConfig.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Dropdown Alasan
              const Text(
                'Alasan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ThemeConfig.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedReason,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: ThemeConfig.bgPrimary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  hintText: 'Pilih alasan',
                  hintStyle: const TextStyle(
                    color: ThemeConfig.textSecondary,
                    fontSize: 14,
                  ),
                ),
                dropdownColor: ThemeConfig.bgCard,
                style: const TextStyle(
                  color: ThemeConfig.textPrimary,
                  fontSize: 14,
                ),
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: ThemeConfig.goldPrimary,
                ),
                items: _reasons.map((String reason) {
                  return DropdownMenuItem<String>(
                    value: reason,
                    child: Text(reason),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    _selectedReason = value;
                    // Clear detail if not "Lainnya"
                    if (value != 'Lainnya') {
                      _detailController.clear();
                    }
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Pilih alasan terlebih dahulu';
                  }
                  return null;
                },
              ),
              
              // Conditional Text Field untuk "Lainnya"
              if (_selectedReason == 'Lainnya') ...[
                const SizedBox(height: 16),
                const Text(
                  'Detail Alasan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ThemeConfig.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _detailController,
                  maxLines: 3,
                  maxLength: 255,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: ThemeConfig.bgPrimary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    hintText: 'Jelaskan alasan Anda...',
                    hintStyle: const TextStyle(
                      color: ThemeConfig.textSecondary,
                      fontSize: 14,
                    ),
                    counterStyle: const TextStyle(
                      color: ThemeConfig.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  style: const TextStyle(
                    color: ThemeConfig.textPrimary,
                    fontSize: 14,
                  ),
                  validator: (value) {
                    if (_selectedReason == 'Lainnya' && 
                        (value == null || value.trim().isEmpty)) {
                      return 'Detail alasan wajib diisi';
                    }
                    return null;
                  },
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                          color: ThemeConfig.goldPrimary,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          color: ThemeConfig.goldPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Konfirmasi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
