import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../shared_widgets/app_button.dart';
import '../../shared_widgets/app_text_field.dart';
import '../domain/room_model.dart';
import 'room_controller.dart';

class RoomCrudDialog extends ConsumerStatefulWidget {
  final RoomModel? roomToEdit;

  const RoomCrudDialog({super.key, this.roomToEdit});

  @override
  ConsumerState<RoomCrudDialog> createState() => _RoomCrudDialogState();
}

class _RoomCrudDialogState extends ConsumerState<RoomCrudDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _roomNumberController;
  late TextEditingController _basePriceController;

  late String _selectedType;
  late int _selectedFloor;
  final Set<String> _selectedFacilities = {'AC', 'WiFi Cepat', 'Smart TV 43"', 'Shower Air Hangat'};

  final List<String> _availableFacilities = [
    'AC',
    'Smart TV 43"',
    'Smart TV 50"',
    'WiFi Cepat',
    'Shower Air Hangat',
    'Bathtub',
    'Kulkas Mini',
    'Balkon View',
    'King Bed',
    '2 Queen Beds',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.roomToEdit != null) {
      final r = widget.roomToEdit!;
      _roomNumberController = TextEditingController(text: r.roomNumber);
      _basePriceController = TextEditingController(text: r.basePricePerNight.toInt().toString());
      _selectedType = r.roomType;
      _selectedFloor = r.floor;
      _selectedFacilities.clear();
      _selectedFacilities.addAll(r.facilities);
    } else {
      _roomNumberController = TextEditingController();
      _basePriceController = TextEditingController(text: '300000');
      _selectedType = 'Superior';
      _selectedFloor = 2;
    }
  }

  @override
  void dispose() {
    _roomNumberController.dispose();
    _basePriceController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final rawPrice = _basePriceController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final price = double.tryParse(rawPrice) ?? 0;

    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.statusOccupied,
          content: Text('Tarif per malam harus lebih dari Rp 0!'),
        ),
      );
      return;
    }

    try {
      if (widget.roomToEdit != null) {
        await ref.read(roomListProvider.notifier).editRoom(
              roomId: widget.roomToEdit!.id,
              roomNumber: _roomNumberController.text.trim(),
              roomType: _selectedType,
              floor: _selectedFloor,
              basePrice: price,
              facilities: _selectedFacilities.toList(),
            );
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.statusAvailable,
              content: Text('Data kamar ${_roomNumberController.text.trim()} berhasil diperbarui!'),
            ),
          );
        }
      } else {
        await ref.read(roomListProvider.notifier).addRoom(
              roomNumber: _roomNumberController.text.trim(),
              roomType: _selectedType,
              floor: _selectedFloor,
              basePrice: price,
              facilities: _selectedFacilities.toList(),
            );

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.statusAvailable,
              content: Text('Unit kamar ${_roomNumberController.text.trim()} berhasil ditambahkan ke inventaris!'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.statusOccupied,
            content: Text(e.toString().replaceAll('Exception: ', '')),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 640;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 16 : 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLg),
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: math.min(620.0, mediaQuery.size.width - 24),
          maxHeight: math.min(720.0, mediaQuery.size.height * 0.92),
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.roomToEdit != null
                            ? 'Ubah Data Kamar ${widget.roomToEdit!.roomNumber}'
                            : 'Tambah Unit Kamar Baru',
                        style: (isMobile ? AppTypography.bodyLg : AppTypography.h2).copyWith(
                          color: AppColors.navy900,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 24),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Nomor Kamar',
                                hint: 'Contoh: 305',
                                controller: _roomNumberController,
                                prefixIcon: Icons.meeting_room_outlined,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty) ? 'Nomor kamar wajib diisi' : null,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Lantai',
                                    style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  DropdownButtonFormField<int>(
                                    initialValue: _selectedFloor,
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 1, child: Text('Lantai 1')),
                                      DropdownMenuItem(value: 2, child: Text('Lantai 2')),
                                      DropdownMenuItem(value: 3, child: Text('Lantai 3')),
                                    ],
                                    onChanged: (v) => setState(() => _selectedFloor = v ?? 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.md),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tipe Kamar',
                                    style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedType,
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'Standard', child: Text('Standard')),
                                      DropdownMenuItem(value: 'Superior', child: Text('Superior')),
                                      DropdownMenuItem(value: 'Deluxe', child: Text('Deluxe')),
                                      DropdownMenuItem(value: 'Family', child: Text('Family')),
                                    ],
                                    onChanged: (v) => setState(() => _selectedType = v ?? 'Superior'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: AppTextField(
                                label: 'Tarif Dasar / Malam (Rp)',
                                controller: _basePriceController,
                                keyboardType: TextInputType.number,
                                prefixIcon: Icons.payments_outlined,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty) ? 'Tarif wajib diisi' : null,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        Text(
                          'Fasilitas Unit Kamar',
                          style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSpacing.xs),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableFacilities.map((facility) {
                            final isChecked = _selectedFacilities.contains(facility);
                            return FilterChip(
                              label: Text(facility),
                              selected: isChecked,
                              selectedColor: AppColors.navy100,
                              checkmarkColor: AppColors.navy700,
                              labelStyle: AppTypography.caption.copyWith(
                                color: isChecked ? AppColors.navy700 : AppColors.textPrimary,
                                fontWeight: isChecked ? FontWeight.w600 : FontWeight.w500,
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedFacilities.add(facility);
                                  } else {
                                    _selectedFacilities.remove(facility);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(
                      label: 'Batal',
                      variant: AppButtonVariant.outline,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    AppButton(
                      label: widget.roomToEdit != null ? 'Simpan Perubahan' : 'Simpan Unit Kamar',
                      variant: AppButtonVariant.primary,
                      icon: Icons.check,
                      onPressed: _handleSave,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
