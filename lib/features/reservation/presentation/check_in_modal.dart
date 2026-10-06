import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../checkout/domain/invoice_pdf_service.dart';
import '../../checkout/domain/invoice_sequence_service.dart';
import '../../checkout/presentation/invoice_preview_dialog.dart';
import '../../reporting/data/reporting_repository.dart';
import '../../room_management/data/room_repository.dart';
import '../../room_management/domain/room_model.dart';
import '../../room_management/presentation/room_controller.dart';
import '../../shared_widgets/app_button.dart';
import '../../shared_widgets/app_text_field.dart';

class CheckInModal extends ConsumerStatefulWidget {
  final RoomModel room;

  const CheckInModal({super.key, required this.room});

  @override
  ConsumerState<CheckInModal> createState() => _CheckInModalState();
}

class _CheckInModalState extends ConsumerState<CheckInModal> {
  final _formKey = GlobalKey<FormState>();

  String _bookingSource = 'WALK_IN'; // 'WALK_IN' or 'REDDOORZ'
  String _idType = 'KTP'; // 'KTP' | 'PASSPORT' | 'SIM' | 'OTHER'
  final _bookingCodeController = TextEditingController();
  final _nikController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  late TextEditingController _priceController;

  int _totalNights = 1;
  bool _isCustomNights = false;
  late TextEditingController _customNightsController;
  bool _isManualPrice = false;
  String _paymentMethod = 'CASH'; // CASH, QRIS, TRANSFER, REDDOORZ_PREPAID

  bool _isOcrLoading = false;
  bool _isOcrExtracted = false;
  double _ocrConfidence = 0.0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _customNightsController = TextEditingController(
      text: _totalNights.toString(),
    );
    _priceController = TextEditingController(
      text: (widget.room.basePricePerNight * _totalNights).toInt().toString(),
    );
    if (_bookingSource == 'REDDOORZ') {
      _paymentMethod = 'REDDOORZ_PREPAID';
    }
  }

  @override
  void dispose() {
    _bookingCodeController.dispose();
    _nikController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _priceController.dispose();
    _customNightsController.dispose();
    super.dispose();
  }

  void _setNights(int nights) {
    if (nights < 1) return;
    setState(() {
      _totalNights = nights;
      if (_customNightsController.text != nights.toString()) {
        _customNightsController.text = nights.toString();
      }
      if (!_isManualPrice) {
        _priceController.text = (widget.room.basePricePerNight * _totalNights)
            .toInt()
            .toString();
      }
    });
  }

  void _resetPriceToStandard() {
    setState(() {
      _isManualPrice = false;
      _priceController.text = (widget.room.basePricePerNight * _totalNights)
          .toInt()
          .toString();
    });
  }

  double get _currentEffectiveTotal {
    final parsed = double.tryParse(
      _priceController.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    if (parsed != null && parsed > 0) {
      return parsed;
    }
    return widget.room.basePricePerNight * _totalNights;
  }

  // Capture image dari kamera atau galeri untuk OCR
  // image_picker menangani permissions secara otomatis
  Future<void> _requestCameraPermissionAndScan() async {
    // Show option to take photo or pick from gallery
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ambil Foto KTP',
              style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Buka Kamera'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _captureOcrImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Pilih Galeri'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _captureOcrImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Capture image dan kirim ke OCR backend
  Future<void> _captureOcrImage(ImageSource source) async {
    setState(() {
      _isOcrLoading = true;
      _errorMessage = null;
    });

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        setState(() => _isOcrLoading = false);
        return;
      }

      // Baca file bytes
      final imageBytes = await pickedFile.readAsBytes();

      // Mock mode untuk testing
      if (AppConfig.useMock) {
        await Future.delayed(const Duration(milliseconds: 600));
        final sampleGuests = [
          {
            'idType': 'KTP',
            'idNumber': '3578012409890002',
            'namaLengkap': 'BAMBANG PRASETYO',
            'alamat': 'JL. DIPONEGORO NO. 45, SURABAYA',
            'phoneWhatsapp': '081298765432',
            'confidence': 0.94,
          },
          {
            'idType': 'PASSPORT',
            'idNumber': 'C1234567',
            'namaLengkap': 'JOHN SMITH',
            'alamat': '',
            'phoneWhatsapp': '085612349876',
            'confidence': 1.0,
          },
        ];
        final picked =
            sampleGuests[DateTime.now().second % sampleGuests.length];
        setState(() {
          _isOcrLoading = false;
          _isOcrExtracted = true;
          _idType = picked['idType'] as String;
          _nikController.text = picked['idNumber'] as String;
          _nameController.text = picked['namaLengkap'] as String;
          _addressController.text = (picked['alamat'] as String?) ?? '';
          if (_phoneController.text.isEmpty) {
            _phoneController.text = picked['phoneWhatsapp'] as String;
          }
          _ocrConfidence = picked['confidence'] as double;
        });
        return;
      }

      // Call backend OCR API dengan image bytes asli
      final repo = ReportingRepository();
      final ocrResult = await repo.extractIdentity(
        imageBytes: imageBytes,
        filename: 'ktp_${_idType.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        documentType: _idType,
      );

      setState(() {
        _isOcrLoading = false;
        _isOcrExtracted = true;
        if (ocrResult['idNumber'] != null) {
          _nikController.text = ocrResult['idNumber'].toString();
        }
        if (ocrResult['namaLengkap'] != null) {
          _nameController.text = ocrResult['namaLengkap'].toString();
        }
        if (ocrResult['alamat'] != null) {
          _addressController.text = ocrResult['alamat'].toString();
        }
        _ocrConfidence = (ocrResult['confidence'] as num?)?.toDouble() ?? 0.9;
      });
    } on ApiException catch (e) {
      setState(() {
        _isOcrLoading = false;
        _errorMessage =
            'OCR Gagal (${e.message}). Silakan isi form secara manual.';
      });
    } catch (e) {
      setState(() {
        _isOcrLoading = false;
        _errorMessage = 'Gagal memproses gambar: ${e.toString()}';
      });
    }
  }

  void _handleReviewInvoice() {
    if (!_formKey.currentState!.validate()) return;

    // Validasi format nomor WhatsApp sesuai regex backend
    final waError = FlutterValidation.validateWa(_phoneController.text);
    if (waError != null) {
      setState(() => _errorMessage = waError);
      return;
    }

    // Validasi nomor identitas sesuai jenis dokumen
    final idError = FlutterValidation.validateIdNumber(
      _nikController.text,
      _idType,
    );
    if (idError != null) {
      setState(() => _errorMessage = idError);
      return;
    }

    // Validate anti-duplicate NIK in active rooms (FR-RES-07)
    final allRooms = ref.read(roomListProvider).value ?? [];
    final cleanNik = _nikController.text.trim();
    final duplicate = allRooms.any(
      (r) =>
          r.isOccupied &&
          r.id != widget.room.id &&
          (r.guestNik != null && r.guestNik == cleanNik),
    );

    if (duplicate) {
      setState(() {
        _errorMessage =
            'Tamu dengan Nomor Identitas $cleanNik sedang aktif menginap di kamar lain!';
      });
      return;
    }

    final effectiveTotal = _currentEffectiveTotal;
    final calculatedBasePrice = effectiveTotal / _totalNights;
    final authState = ref.read(authStateProvider);
    final receptionistName = authState.user?.fullName ?? 'Siti Rahmawati';

    final previewInvoiceNumber = InvoiceSequenceService.instance
        .generateNextInvoiceNumber(transactionDate: DateTime.now());

    final dummyRoomForPreview = widget.room.copyWith(
      activeGuestName: _nameController.text.trim(),
      guestNik: cleanNik,
      activeGuestPhone: _phoneController.text.trim(),
      bookingSource: _bookingSource,
      reddoorzBookingCode: _bookingSource == 'REDDOORZ'
          ? _bookingCodeController.text.trim()
          : null,
      checkInTime: DateTime.now(),
      expectedCheckOutTime: DateTime.now().add(Duration(days: _totalNights)),
      invoiceNumber: previewInvoiceNumber,
    );

    // Tampilkan Dialog Pratinjau Invoice Check-In
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => InvoicePreviewDialog(
        room: dummyRoomForPreview,
        roomTotal: effectiveTotal,
        grandTotal: effectiveTotal,
        receptionistName: receptionistName,
        customTitle: 'Pratinjau Faktur Pembayaran (Check-In)',
        onConfirmCheckIn: () =>
            _executeFinalCheckIn(previewInvoiceNumber, calculatedBasePrice),
      ),
    );
  }

  void _executeFinalCheckIn(
    String invoiceNumber,
    double calculatedBasePrice,
  ) async {
    final cleanNik = _nikController.text.trim();
    setState(() => _errorMessage = null);

    try {
      // Panggil checkIn yang mengirim ke POST /reservations di backend
      // Backend akan menolak (409) jika kamar sudah occupied atau NIK aktif
      final result = await ref
          .read(roomListProvider.notifier)
          .checkIn(
            roomId: widget.room.id,
            guestFullName: _nameController.text.trim(),
            idType: _idType,
            idNumber: cleanNik,
            guestAddress: _addressController.text.trim(),
            guestPhone: _phoneController.text.trim(),
            bookingSource: _bookingSource,
            reddoorzBookingCode: _bookingSource == 'REDDOORZ'
                ? _bookingCodeController.text.trim()
                : null,
            totalNights: _totalNights,
            roomRate: calculatedBasePrice,
            paymentMethod: _paymentMethod,
          );

      final returnedInvoice =
          result['invoiceNumber']?.toString() ?? invoiceNumber;

      if (mounted) {
        Navigator.of(context).pop(); // Tutup CheckInModal
        final targetRoom = widget.room.copyWith(
          activeGuestName: _nameController.text.trim(),
          guestNik: cleanNik,
          activeGuestPhone: _phoneController.text.trim(),
          bookingSource: _bookingSource,
          reddoorzBookingCode: _bookingSource == 'REDDOORZ'
              ? _bookingCodeController.text.trim()
              : null,
          invoiceNumber: returnedInvoice,
          checkInTime: DateTime.now(),
        );
        final authState = ref.read(authStateProvider);
        final receptionistName = authState.user?.fullName ?? 'Siti Rahmawati';
        final totalBayar = calculatedBasePrice * _totalNights;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.statusAvailable,
            duration: const Duration(seconds: 7),
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Check-in Kamar ${widget.room.roomNumber} berhasil & Lunas! Invoice $returnedInvoice telah diterbitkan.',
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'UNDUH PDF',
              textColor: Colors.white,
              onPressed: () {
                InvoicePdfService.saveInvoicePdf(
                  room: targetRoom,
                  roomTotal: totalBayar,
                  grandTotal: totalBayar,
                  receptionistName: receptionistName,
                  invoiceNumber: returnedInvoice,
                );
              },
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      // Backend error (mis. 409 CONFLICT atau 400 VALIDATION) ditampilkan persis
      setState(() {
        _errorMessage = e.message;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.statusOccupied,
            content: Text(e.message),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _handleSubmit() async {
    _handleReviewInvoice();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 600;
    final dialogWidth = math.min(
      720.0,
      mediaQuery.size.width - (isMobile ? 20 : 48),
    );
    final dialogHeight = math.min(
      780.0,
      mediaQuery.size.height * (isMobile ? 0.95 : 0.90),
    );

    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 24,
        vertical: isMobile ? 12 : 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLg),
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Modal Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.navy100,
                              borderRadius: AppRadius.roundedSm,
                            ),
                            child: Text(
                              'Kamar ${widget.room.roomNumber}',
                              style: AppTypography.h3.copyWith(
                                color: AppColors.navy900,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Formulir Check-In Tamu',
                              style:
                                  (isMobile
                                          ? AppTypography.h3
                                          : AppTypography.h2)
                                      .copyWith(color: AppColors.navy900),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),

                const Divider(height: 16),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.statusErrorBg,
                              borderRadius: AppRadius.roundedMd,
                            ),
                            child: Text(
                              _errorMessage!,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.statusOccupied,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // 1. Channel Selector
                        Text(
                          'Kanal Reservasi Pemesanan',
                          style: AppTypography.bodySm.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Builder(
                          builder: (context) {
                            final walkInCard = InkWell(
                              onTap: () {
                                setState(() {
                                  _bookingSource = 'WALK_IN';
                                  if (_paymentMethod == 'REDDOORZ_PREPAID') {
                                    _paymentMethod = 'CASH';
                                  }
                                });
                              },
                              borderRadius: AppRadius.roundedMd,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _bookingSource == 'WALK_IN'
                                      ? AppColors.navy100
                                      : AppColors.surface,
                                  border: Border.all(
                                    color: _bookingSource == 'WALK_IN'
                                        ? AppColors.navy700
                                        : AppColors.border,
                                    width: _bookingSource == 'WALK_IN' ? 2 : 1,
                                  ),
                                  borderRadius: AppRadius.roundedMd,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.person_pin_circle_outlined,
                                      color: _bookingSource == 'WALK_IN'
                                          ? AppColors.navy700
                                          : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Walk-in (Offline)',
                                            style: AppTypography.bodySm
                                                .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      _bookingSource ==
                                                          'WALK_IN'
                                                      ? AppColors.navy900
                                                      : AppColors.textPrimary,
                                                ),
                                          ),
                                          Text(
                                            'Tarif Standar Hotel',
                                            style: AppTypography.caption,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );

                            final redDoorzCard = InkWell(
                              onTap: () {
                                setState(() {
                                  _bookingSource = 'REDDOORZ';
                                  _paymentMethod = 'REDDOORZ_PREPAID';
                                });
                              },
                              borderRadius: AppRadius.roundedMd,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _bookingSource == 'REDDOORZ'
                                      ? Colors.red.shade50
                                      : AppColors.surface,
                                  border: Border.all(
                                    color: _bookingSource == 'REDDOORZ'
                                        ? Colors.red.shade700
                                        : AppColors.border,
                                    width: _bookingSource == 'REDDOORZ' ? 2 : 1,
                                  ),
                                  borderRadius: AppRadius.roundedMd,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.hotel_class_rounded,
                                      color: _bookingSource == 'REDDOORZ'
                                          ? Colors.red.shade700
                                          : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'RedDoorz (Online)',
                                            style: AppTypography.bodySm
                                                .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      _bookingSource ==
                                                          'REDDOORZ'
                                                      ? Colors.red.shade900
                                                      : AppColors.textPrimary,
                                                ),
                                          ),
                                          Text(
                                            'Wajib Booking Code OTA',
                                            style: AppTypography.caption,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );

                            if (isMobile) {
                              return Column(
                                children: [
                                  walkInCard,
                                  const SizedBox(height: AppSpacing.sm),
                                  redDoorzCard,
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: walkInCard),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(child: redDoorzCard),
                              ],
                            );
                          },
                        ),

                        if (_bookingSource == 'REDDOORZ') ...[
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            label: 'Kode Booking RedDoorz',
                            hint: 'Contoh: RD-89421',
                            controller: _bookingCodeController,
                            prefixIcon: Icons.confirmation_number_outlined,
                            validator: (v) =>
                                (_bookingSource == 'REDDOORZ' &&
                                    (v == null || v.trim().isEmpty))
                                ? 'Kode Booking RedDoorz wajib diisi'
                                : null,
                          ),
                        ],

                        const SizedBox(height: AppSpacing.lg),

                        // 2. OCR Section
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            borderRadius: AppRadius.roundedMd,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.document_scanner_rounded,
                                        color: AppColors.navy700,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Ekstraksi Kamera / OCR KTP Tamu',
                                        style: AppTypography.bodySm.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.navy900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_isOcrExtracted)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.statusSuccessBg,
                                        borderRadius: AppRadius.roundedSm,
                                      ),
                                      child: Text(
                                        'Akurasi: ${(_ocrConfidence * 100).toInt()}% (Tinggi)',
                                        style: AppTypography.overline.copyWith(
                                          color: const Color(0xFF16A34A),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Pindai KTP untuk mengisi NIK, Nama, dan Alamat secara otomatis (< 2 detik) guna mempercepat antrean.',
                                style: AppTypography.caption,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: AppSpacing.md,
                                runSpacing: AppSpacing.xs,
                                children: [
                                  AppButton(
                                    label: _isOcrExtracted
                                        ? 'Scan Ulang KTP'
                                        : 'Scan KTP Sekarang',
                                    variant: AppButtonVariant.secondary,
                                    icon: Icons.camera_alt_outlined,
                                    isLoading: _isOcrLoading,
                                    onPressed: _requestCameraPermissionAndScan,
                                  ),
                                  Text(
                                    'Atau ketik langsung formulir di bawah',
                                    style: AppTypography.caption,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Document Type Selection (KTP / PASSPORT / SIM)
                        Text(
                          'Jenis Dokumen Identitas Tamu',
                          style: AppTypography.bodySm.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: ['KTP', 'PASSPORT', 'SIM', 'OTHER'].map((
                            type,
                          ) {
                            final isSelected = _idType == type;
                            return ChoiceChip(
                              label: Text(type == 'OTHER' ? 'Lainnya' : type),
                              selected: isSelected,
                              selectedColor: AppColors.navy100,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppColors.navy900
                                    : AppColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                              onSelected: (selected) {
                                if (selected) setState(() => _idType = type);
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Guest Data Fields - Responsive layout
                        if (isMobile) ...[
                          AppTextField(
                            label: 'Nomor Identitas ($_idType)',
                            hint: _idType == 'KTP'
                                ? '16 digit NIK'
                                : (_idType == 'PASSPORT'
                                      ? 'Nomor Paspor'
                                      : 'Nomor SIM'),
                            controller: _nikController,
                            isAutoFilled: _isOcrExtracted,
                            prefixIcon: Icons.badge_outlined,
                            keyboardType: _idType == 'KTP' || _idType == 'SIM'
                                ? TextInputType.number
                                : TextInputType.text,
                            validator: (v) =>
                                FlutterValidation.validateIdNumber(v, _idType),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppTextField(
                            label: 'Nama Lengkap Tamu',
                            hint: 'Sesuai kartu identitas',
                            controller: _nameController,
                            isAutoFilled: _isOcrExtracted,
                            prefixIcon: Icons.person_outline,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Nama wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppTextField(
                            label: 'Nomor WhatsApp Tamu',
                            hint:
                                '08... atau +62... (untuk pengingat check-out)',
                            controller: _phoneController,
                            prefixIcon: Icons.chat_bubble_outline,
                            keyboardType: TextInputType.phone,
                            validator: (v) => FlutterValidation.validateWa(v),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppTextField(
                            label: 'Alamat Domisili',
                            hint: 'Kota / Alamat lengkap (opsional)',
                            controller: _addressController,
                            isAutoFilled: _isOcrExtracted,
                            prefixIcon: Icons.location_on_outlined,
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  label: 'Nomor Identitas ($_idType)',
                                  hint: _idType == 'KTP'
                                      ? '16 digit NIK'
                                      : (_idType == 'PASSPORT'
                                            ? 'Nomor Paspor'
                                            : 'Nomor SIM'),
                                  controller: _nikController,
                                  isAutoFilled: _isOcrExtracted,
                                  prefixIcon: Icons.badge_outlined,
                                  keyboardType:
                                      _idType == 'KTP' || _idType == 'SIM'
                                      ? TextInputType.number
                                      : TextInputType.text,
                                  validator: (v) =>
                                      FlutterValidation.validateIdNumber(
                                        v,
                                        _idType,
                                      ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: AppTextField(
                                  label: 'Nama Lengkap Tamu',
                                  hint: 'Sesuai kartu identitas',
                                  controller: _nameController,
                                  isAutoFilled: _isOcrExtracted,
                                  prefixIcon: Icons.person_outline,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Nama wajib diisi'
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  label: 'Nomor WhatsApp Tamu',
                                  hint:
                                      '08... atau +62... (pengingat check-out)',
                                  controller: _phoneController,
                                  prefixIcon: Icons.chat_bubble_outline,
                                  keyboardType: TextInputType.phone,
                                  validator: (v) =>
                                      FlutterValidation.validateWa(v),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: AppTextField(
                                  label: 'Alamat Domisili',
                                  hint: 'Kota / Alamat lengkap (opsional)',
                                  controller: _addressController,
                                  isAutoFilled: _isOcrExtracted,
                                  prefixIcon: Icons.location_on_outlined,
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: AppSpacing.lg),

                        // Stay Duration & Payment Method - Simplified Clean Dropdown Section
                        if (isMobile) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Durasi Menginap',
                                    style: AppTypography.bodySm.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  _buildCheckOutBadge(),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              _buildDurationSection(),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Metode Pembayaran',
                                style: AppTypography.bodySm.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              _buildPaymentDropdown(),
                            ],
                          ),
                        ] else ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Durasi Menginap',
                                          style: AppTypography.bodySm.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        _buildCheckOutBadge(),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    _buildDurationSection(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Metode Pembayaran',
                                      style: AppTypography.bodySm.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    _buildPaymentDropdown(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: AppSpacing.lg),

                        // Interactive Manual / Dynamic Price Editor Card
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: _isManualPrice
                                ? const Color(0xFFFFFBEB)
                                : AppColors.navy50,
                            borderRadius: AppRadius.roundedMd,
                            border: Border.all(
                              color: _isManualPrice
                                  ? const Color(0xFFF59E0B)
                                  : AppColors.border,
                              width: _isManualPrice ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            'Total Biaya Menginap',
                                            style: AppTypography.bodySm
                                                .copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.navy900,
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (_isManualPrice)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFDE68A),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Tarif Manual / Khusus',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFB45309),
                                              ),
                                            ),
                                          )
                                        else
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.navy100,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Standar Otomatis',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.navy700,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (_isManualPrice)
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      icon: const Icon(
                                        Icons.restart_alt_rounded,
                                        size: 14,
                                      ),
                                      label: const Text(
                                        'Reset ke Standar',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                      onPressed: _resetPriceToStandard,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (isMobile) ...[
                                TextField(
                                  controller: _priceController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  style: AppTypography.h2.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: _isManualPrice
                                        ? const Color(0xFFB45309)
                                        : AppColors.navy900,
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      _isManualPrice = true;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    prefixText: 'Rp ',
                                    prefixStyle: AppTypography.h2.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: _isManualPrice
                                          ? const Color(0xFFB45309)
                                          : AppColors.navy900,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: _isManualPrice
                                            ? const Color(0xFFF59E0B)
                                            : AppColors.border,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: AppColors.navy900,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Standar: ${currencyFormatter.format(widget.room.basePricePerNight)}/malam',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      'Total: ${currencyFormatter.format(widget.room.basePricePerNight * _totalNights)}',
                                      style: AppTypography.caption.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.navy700,
                                      ),
                                    ),
                                  ],
                                ),
                              ] else
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: TextField(
                                        controller: _priceController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        style: AppTypography.h2.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: _isManualPrice
                                              ? const Color(0xFFB45309)
                                              : AppColors.navy900,
                                        ),
                                        onChanged: (val) {
                                          setState(() {
                                            _isManualPrice = true;
                                          });
                                        },
                                        decoration: InputDecoration(
                                          prefixText: 'Rp ',
                                          prefixStyle: AppTypography.h2
                                              .copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: _isManualPrice
                                                    ? const Color(0xFFB45309)
                                                    : AppColors.navy900,
                                              ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 10,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: BorderSide(
                                              color: AppColors.border,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: BorderSide(
                                              color: _isManualPrice
                                                  ? const Color(0xFFF59E0B)
                                                  : AppColors.border,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: const BorderSide(
                                              color: AppColors.navy900,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Tarif Standar Unit:',
                                            style: AppTypography.caption
                                                .copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                          ),
                                          Text(
                                            '${currencyFormatter.format(widget.room.basePricePerNight)} / malam',
                                            style: AppTypography.bodySm
                                                .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          Text(
                                            'Total Standar: ${currencyFormatter.format(widget.room.basePricePerNight * _totalNights)}',
                                            style: AppTypography.caption
                                                .copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 4),
                              Text(
                                '💡 Nominal di atas dapat diubah manual secara bebas untuk diskon khusus, promo offline, atau negosiasi harga kamar.',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: _isManualPrice
                                      ? const Color(0xFF92400E)
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 16),

                // Modal Footer - Responsive Wrap
                Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    AppButton(
                      label: 'Batal',
                      variant: AppButtonVariant.outline,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    // Exactly ONE primary orange CTA per design.md rules
                    AppButton(
                      label: 'Pratinjau Invoice & Selesaikan',
                      variant: AppButtonVariant.primary,
                      icon: Icons.receipt_long_rounded,
                      onPressed: _handleSubmit,
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

  Widget _buildCheckOutBadge() {
    final checkoutDate = DateTime.now().add(Duration(days: _totalNights));
    final formattedDate = DateFormat('d MMM', 'id').format(checkoutDate);
    final dayName = DateFormat('EEE', 'id').format(checkoutDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.navy50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.event_available_rounded,
            size: 12,
            color: AppColors.navy700,
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              '$dayName, $formattedDate',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.navy900,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDurationDropdown(),
        if (_isCustomNights) ...[
          const SizedBox(height: 8),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.navy700, width: 1.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.edit_calendar_outlined,
                  size: 16,
                  color: AppColors.navy700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _customNightsController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      hintText: 'Ketik jumlah hari...',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: AppTypography.bodySm.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy900,
                    ),
                    onChanged: (val) {
                      final n = int.tryParse(val);
                      if (n != null && n > 0) {
                        _setNights(n);
                      }
                    },
                  ),
                ),
                Text(
                  'Hari',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy700,
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    size: 16,
                    color: AppColors.navy700,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  onPressed: _totalNights > 1
                      ? () {
                          final newN = _totalNights - 1;
                          _customNightsController.text = newN.toString();
                          _setNights(newN);
                        }
                      : null,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    size: 16,
                    color: AppColors.navy700,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  onPressed: () {
                    final newN = _totalNights + 1;
                    _customNightsController.text = newN.toString();
                    _setNights(newN);
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDurationDropdown() {
    final int selectedValue = _isCustomNights
        ? -1
        : (_totalNights == 1 || _totalNights == 3 || _totalNights == 5
              ? _totalNights
              : -1);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isCustomNights ? AppColors.navy700 : AppColors.border,
          width: _isCustomNights ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedValue,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.navy700,
            size: 20,
          ),
          dropdownColor: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          items: [
            DropdownMenuItem<int>(
              value: 1,
              child: Row(
                children: [
                  const Icon(
                    Icons.bed_outlined,
                    size: 18,
                    color: AppColors.navy700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '1 Hari (1 Malam)',
                    style: AppTypography.bodySm.copyWith(
                      fontWeight: selectedValue == 1
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: AppColors.navy900,
                    ),
                  ),
                ],
              ),
            ),
            DropdownMenuItem<int>(
              value: 3,
              child: Row(
                children: [
                  const Icon(
                    Icons.bed_outlined,
                    size: 18,
                    color: AppColors.navy700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '3 Hari (3 Malam)',
                    style: AppTypography.bodySm.copyWith(
                      fontWeight: selectedValue == 3
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: AppColors.navy900,
                    ),
                  ),
                ],
              ),
            ),
            DropdownMenuItem<int>(
              value: 5,
              child: Row(
                children: [
                  const Icon(
                    Icons.bed_outlined,
                    size: 18,
                    color: AppColors.navy700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '5 Hari (5 Malam)',
                    style: AppTypography.bodySm.copyWith(
                      fontWeight: selectedValue == 5
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: AppColors.navy900,
                    ),
                  ),
                ],
              ),
            ),
            DropdownMenuItem<int>(
              value: -1,
              child: Row(
                children: [
                  const Icon(
                    Icons.edit_calendar_outlined,
                    size: 18,
                    color: AppColors.orange600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isCustomNights
                        ? 'Isi Sendiri ($_totalNights Hari)'
                        : 'Isi Sendiri (Manual)...',
                    style: AppTypography.bodySm.copyWith(
                      fontWeight: selectedValue == -1
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: _isCustomNights
                          ? AppColors.navy900
                          : AppColors.orange600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          onChanged: (val) {
            if (val == null) return;
            if (val == -1) {
              setState(() {
                _isCustomNights = true;
                _customNightsController.text = _totalNights.toString();
              });
            } else {
              setState(() {
                _isCustomNights = false;
                _setNights(val);
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildPaymentDropdown() {
    final List<Map<String, dynamic>> options = [
      if (_bookingSource == 'REDDOORZ')
        {
          'id': 'REDDOORZ_PREPAID',
          'label': 'Lunas via RedDoorz App',
          'icon': Icons.hotel_class_rounded,
          'color': const Color(0xFFDC2626),
        },
      {
        'id': 'CASH',
        'label': 'Tunai (Cash)',
        'icon': Icons.payments_outlined,
        'color': AppColors.navy900,
      },
      {
        'id': 'QRIS',
        'label': 'QRIS Dinamis',
        'icon': Icons.qr_code_rounded,
        'color': const Color(0xFF047857),
      },
      {
        'id': 'TRANSFER',
        'label': 'Transfer Bank (BCA/Mandiri)',
        'icon': Icons.account_balance_outlined,
        'color': const Color(0xFF1D4ED8),
      },
    ];

    final validIds = options.map((e) => e['id'] as String).toList();
    final effectiveValue = validIds.contains(_paymentMethod)
        ? _paymentMethod
        : 'CASH';

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveValue,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.navy700,
            size: 20,
          ),
          dropdownColor: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          items: options.map((opt) {
            final isSelected = opt['id'] == effectiveValue;
            final color = opt['color'] as Color;
            return DropdownMenuItem<String>(
              value: opt['id'] as String,
              child: Row(
                children: [
                  Icon(opt['icon'] as IconData, size: 18, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      opt['label'] as String,
                      style: AppTypography.bodySm.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: AppColors.navy900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _paymentMethod = val);
            }
          },
        ),
      ),
    );
  }
}
