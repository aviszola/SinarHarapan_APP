import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service penyedia nomor faktur unik terpusat sesuai Arsitektur §4.3 dan PRD FR-OUT-03.
/// Format standar resmi: INV/SH/YYYYMMDD/XXXX
/// Di mana:
/// - YYYYMMDD: Tanggal kalender saat transaksi check-out dilakukan
/// - XXXX: Counter 4 digit yang otomatis reset ke 0001 di awal setiap hari baru
class InvoiceSequenceService {
  InvoiceSequenceService._internal();
  static final InvoiceSequenceService instance = InvoiceSequenceService._internal();

  /// Penyimpanan sequence counter per tanggal kalender (Key: YYYYMMDD, Value: counter integer terakhir)
  final Map<String, int> _dailyCounters = {};

  /// Menghasilkan nomor invoice unik berikutnya berdasarkan tanggal transaksi check-out
  String generateNextInvoiceNumber({DateTime? transactionDate}) {
    final date = transactionDate ?? DateTime.now();
    final dateKey = _formatDateKey(date);

    final currentCounter = _dailyCounters[dateKey] ?? 0;
    final nextCounter = currentCounter + 1;
    _dailyCounters[dateKey] = nextCounter;

    final seqStr = nextCounter.toString().padLeft(4, '0');
    return 'INV/SH/$dateKey/$seqStr';
  }

  /// Membaca nomor invoice yang sudah ada di database/repository untuk menginisialisasi counter
  /// agar tidak terjadi duplikasi nomor faktur saat aplikasi dimulai ulang
  void seedFromInvoices(Iterable<String?> existingInvoices) {
    for (final inv in existingInvoices) {
      if (inv == null || inv.isEmpty) continue;
      final parts = inv.split('/');
      if (parts.length == 4 && parts[0] == 'INV' && parts[1] == 'SH') {
        final dateKey = parts[2];
        final seq = int.tryParse(parts[3]);
        if (seq != null) {
          final current = _dailyCounters[dateKey] ?? 0;
          if (seq > current) {
            _dailyCounters[dateKey] = seq;
          }
        }
      }
    }
  }

  /// Format helper tanggal ke string 8 digit YYYYMMDD
  String _formatDateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  /// Mengambil counter terakhir untuk tanggal tertentu (berguna untuk audit/verifikasi test)
  int getCounterForDate(DateTime dt) {
    return _dailyCounters[_formatDateKey(dt)] ?? 0;
  }

  /// Reset internal counter (hanya untuk keperluan automated testing)
  void resetForTesting() {
    _dailyCounters.clear();
  }
}

/// Provider Riverpod untuk dependency injection
final invoiceSequenceServiceProvider = Provider<InvoiceSequenceService>((ref) {
  return InvoiceSequenceService.instance;
});
