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

  void _showAddFacilityDialog() {
    final customController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final remainingPresets = _availableFacilities
                .where((f) => !_selectedFacilities.contains(f))
                .toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.orange50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.hotel_class_outlined, color: AppColors.orange600, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Tambah Fasilitas Kamar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy900,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (remainingPresets.isNotEmpty) ...[
                        const Text(
                          'PILIH DARI FASILITAS STANDAR',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: remainingPresets.map((facility) {
                            return ActionChip(
                              avatar: const Icon(Icons.add_circle_outline, size: 15, color: AppColors.navy700),
                              label: Text(facility),
                              labelStyle: AppTypography.caption.copyWith(
                                color: AppColors.navy900,
                                fontWeight: FontWeight.w600,
                              ),
                              backgroundColor: AppColors.navy50,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              onPressed: () {
                                setState(() {
                                  _selectedFacilities.add(facility);
                                });
                                setDialogState(() {});
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                      ],

                      const Text(
                        'TAMBAH FASILITAS KUSTOM',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: customController,
                              decoration: InputDecoration(
                                hintText: 'Contoh: Hair Dryer, Mesin Kopi...',
                                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textDisabled),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: AppColors.navy700, width: 1.5),
                                ),
                              ),
                              style: const TextStyle(fontSize: 13),
                              onSubmitted: (value) {
                                final text = value.trim();
                                if (text.isNotEmpty) {
                                  setState(() {
                                    _selectedFacilities.add(text);
                                    if (!_availableFacilities.contains(text)) {
                                      _availableFacilities.add(text);
                                    }
                                  });
                                  customController.clear();
                                  setDialogState(() {});
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.navy900,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Tambah', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              final text = customController.text.trim();
                              if (text.isNotEmpty) {
                                setState(() {
                                  _selectedFacilities.add(text);
                                  if (!_availableFacilities.contains(text)) {
                                    _availableFacilities.add(text);
                                  }
                                });
                                customController.clear();
                                setDialogState(() {});
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy900,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Selesai'),
                ),
              ],
            );
          },
        );
      },
    );
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
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ..._selectedFacilities.map((facility) {
                              return InputChip(
                                label: Text(facility),
                                labelStyle: AppTypography.caption.copyWith(
                                  color: AppColors.navy900,
                                  fontWeight: FontWeight.w600,
                                ),
                                backgroundColor: AppColors.navy50,
                                side: const BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                deleteIcon: const Icon(Icons.close, size: 15, color: AppColors.navy700),
                                deleteButtonTooltipMessage: 'Hapus $facility',
                                onDeleted: () {
                                  setState(() {
                                    _selectedFacilities.remove(facility);
                                  });
                                },
                              );
                            }),

                            // Tombol Tambah Fasilitas
                            ActionChip(
                              avatar: const Icon(Icons.add_circle, size: 16, color: AppColors.orange600),
                              label: const Text('Tambah Fasilitas'),
                              labelStyle: AppTypography.caption.copyWith(
                                color: AppColors.orange600,
                                fontWeight: FontWeight.w700,
                              ),
                              backgroundColor: AppColors.orange50,
                              side: const BorderSide(color: AppColors.orange500, width: 1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              onPressed: _showAddFacilityDialog,
                            ),
                          ],
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
