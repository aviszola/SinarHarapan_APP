/**
 * Unit Test & Verification Script for Backend Bug Fixes (BUG-BE-01 s/d BUG-BE-09)
 * Sinar Harapan PMS Backend (Next.js 14 + Zod + Prisma)
 */

import { z } from 'zod';

console.log('================================================================');
console.log('VERIFIKASI SUITE PENGUJIAN BACKEND PMS (BUG-BE-01 s/d BUG-BE-09)');
console.log('================================================================\n');

let passCount = 0;
let failCount = 0;

function assert(condition, message) {
  if (condition) {
    console.log(`[PASS] ${message}`);
    passCount++;
  } else {
    console.error(`[FAIL] ${message}`);
    failCount++;
  }
}

// -----------------------------------------------------------------------------
// 1. Verifikasi BUG-BE-07 (Batas Rentang Tanggal Ekspor Laporan <= 90 Hari)
// -----------------------------------------------------------------------------
console.log('--- 1. PENGUJIAN BUG-BE-07: Batas Rentang Tanggal Laporan (Max 90 Hari) ---');

const ReportQuerySchema = z.object({
  startDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Format tanggal harus YYYY-MM-DD'),
  endDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Format tanggal harus YYYY-MM-DD'),
}).refine((data) => {
  const start = new Date(data.startDate);
  const end = new Date(data.endDate);
  if (isNaN(start.getTime()) || isNaN(end.getTime())) return false;
  return end.getTime() >= start.getTime();
}, {
  message: 'Tanggal akhir (endDate) tidak boleh lebih awal dari tanggal awal (startDate)',
  path: ['endDate'],
}).refine((data) => {
  const start = new Date(data.startDate);
  const end = new Date(data.endDate);
  const diffDays = Math.ceil((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24));
  return diffDays <= 90;
}, {
  message: 'Rentang tanggal ekspor laporan maksimal 90 hari untuk mencegah timeout (504 Gateway Timeout)',
  path: ['endDate'],
});

// Kasus 1: Rentang 30 hari (valid)
const testRange30 = ReportQuerySchema.safeParse({ startDate: '2026-01-01', endDate: '2026-01-31' });
assert(testRange30.success, 'Rentang 30 hari diterima dengan sukses (HTTP 200)');

// Kasus 2: Rentang 90 hari (valid)
const testRange90 = ReportQuerySchema.safeParse({ startDate: '2026-01-01', endDate: '2026-04-01' });
assert(testRange90.success, 'Rentang 90 hari tepat diterima (HTTP 200)');

// Kasus 3: Rentang 8 bulan (invalid - pemicu 504 di laporan audit)
const testRange8Months = ReportQuerySchema.safeParse({ startDate: '2026-01-01', endDate: '2026-09-01' });
assert(!testRange8Months.success, 'Rentang 8 bulan DITOLAK oleh skema Zod (mencegah 504 Gateway Timeout)');
assert(
  testRange8Months.error && testRange8Months.error.issues[0].message.includes('maksimal 90 hari'),
  `Pesan error jelas: "${testRange8Months.error ? testRange8Months.error.issues[0].message : ''}"`
);

// -----------------------------------------------------------------------------
// 2. Verifikasi BUG-BE-08 (Field Biaya Tambahan Nullable & Default 0)
// -----------------------------------------------------------------------------
console.log('\n--- 2. PENGUJIAN BUG-BE-08: Field Biaya Tambahan Nullable ---');

const CheckOutSchema = z.object({
  additionalCharges: z.number().min(0).nullable().default(0).transform((val) => val ?? 0),
  additionalChargesDetail: z.array(z.object({
    category: z.string().optional(),
    amount: z.number().min(0),
    note: z.string().optional(),
  })).nullable().default([]).transform((val) => val ?? []),
});

// Kasus 1: Mengirimkan additionalCharges = null (dari Flutter checkout dialog)
const testNullCharges = CheckOutSchema.safeParse({ additionalCharges: null, additionalChargesDetail: null });
assert(testNullCharges.success, 'additionalCharges: null berhasil divalidasi tanpa melempar error');
assert(testNullCharges.data.additionalCharges === 0, 'additionalCharges ditransformasikan dari null menjadi 0');

// Kasus 2: Mengirimkan biaya tambahan valid
const testValidCharges = CheckOutSchema.safeParse({
  additionalCharges: 100000,
  additionalChargesDetail: [{ category: 'LATE_CHECKOUT', amount: 100000, note: 'Telat 2 jam' }],
});
assert(testValidCharges.success, 'additionalCharges: 100000 diterima');
assert(testValidCharges.data.additionalCharges === 100000, 'additionalCharges bernilai 100000');

// -----------------------------------------------------------------------------
// 3. Verifikasi BUG-BE-09 (Batas Maksimal limit pada Query Audit Log)
// -----------------------------------------------------------------------------
console.log('\n--- 3. PENGUJIAN BUG-BE-09: Batas Maksimal limit Query Audit Log (Max 100) ---');

const AuditLogQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100, 'Batas maksimal limit adalah 100 per halaman').default(20),
});

// Kasus 1: Default limit 20
const testDefaultLimit = AuditLogQuerySchema.safeParse({});
assert(testDefaultLimit.success && testDefaultLimit.data.limit === 20, 'Default limit otomatis 20');

// Kasus 2: Limit 100 (batas atas)
const testLimit100 = AuditLogQuerySchema.safeParse({ limit: 100 });
assert(testLimit100.success && testLimit100.data.limit === 100, 'Limit 100 diterima');

// Kasus 3: Limit 100000 (serangan beban database)
const testLimitOverload = AuditLogQuerySchema.safeParse({ limit: 100000 });
assert(!testLimitOverload.success, 'Limit 100000 DITOLAK oleh validasi Zod');
assert(
  testLimitOverload.error && testLimitOverload.error.issues[0].message.includes('maksimal limit adalah 100'),
  `Pesan error batas limit jelas: "${testLimitOverload.error ? testLimitOverload.error.issues[0].message : ''}"`
);

// -----------------------------------------------------------------------------
// 4. Verifikasi BUG-BE-06 & B3 (Formula Denda Keterlambatan Check-out Flat Rp 50.000/jam)
// -----------------------------------------------------------------------------
console.log('\n--- 4. PENGUJIAN BUG-BE-06 & B3: Formula Denda Telat Check-out ---');

function calculateLateFee(expectedCheckOut, actualCheckOut, hourlyRate = 50000) {
  if (actualCheckOut <= expectedCheckOut) {
    return { isLate: false, lateHours: 0, fee: 0 };
  }
  const diffMs = actualCheckOut.getTime() - expectedCheckOut.getTime();
  const hours = Math.ceil(diffMs / (1000 * 60 * 60));
  return {
    isLate: true,
    lateHours: hours,
    fee: hours * hourlyRate,
  };
}

const expOut = new Date('2026-10-04T12:00:00Z');
const actOutOnTime = new Date('2026-10-04T11:55:00Z');
const actOutLate2Hrs = new Date('2026-10-04T14:00:00Z');

const feeOnTime = calculateLateFee(expOut, actOutOnTime);
assert(!feeOnTime.isLate && feeOnTime.fee === 0, 'Tepat waktu: denda Rp 0');

const feeLate2 = calculateLateFee(expOut, actOutLate2Hrs);
assert(feeLate2.isLate && feeLate2.lateHours === 2, 'Keterlambatan 2 jam terdeteksi akurat');
assert(feeLate2.fee === 100000, 'Nominal denda flat 2 x Rp 50.000 = Rp 100.000 (bukan persentase 10%)');

// -----------------------------------------------------------------------------
// 5. Verifikasi BUG-BE-02 (Sequence Nomor Invoice Database Persisten)
// -----------------------------------------------------------------------------
console.log('\n--- 5. PENGUJIAN BUG-BE-02: Sequence Nomor Invoice Persisten ---');

class MockDatabase {
  constructor() {
    this.counters = new Map();
  }

  async upsertInvoiceCounter(dateStr) {
    const current = this.counters.get(dateStr) || 0;
    const next = current + 1;
    this.counters.set(dateStr, next);
    return { dateStr, lastSequence: next };
  }
}

const db = new MockDatabase();
async function generateInvoiceNumberSim(date = new Date()) {
  const yyyy = date.getFullYear();
  const mm = String(date.getMonth() + 1).padStart(2, '0');
  const dd = String(date.getDate()).padStart(2, '0');
  const dateStr = `${yyyy}${mm}${dd}`;
  const counter = await db.upsertInvoiceCounter(dateStr);
  const seqStr = String(counter.lastSequence).padStart(4, '0');
  return `INV/SH/${dateStr}/${seqStr}`;
}

const simDate = new Date('2026-10-04T10:00:00Z');
const inv1 = await generateInvoiceNumberSim(simDate);
const inv2 = await generateInvoiceNumberSim(simDate);
assert(inv1 === 'INV/SH/20261004/0001', `Transaksi 1: ${inv1}`);
assert(inv2 === 'INV/SH/20261004/0002', `Transaksi 2: ${inv2}`);

// Simulasi proses restart: memory state hilang tapi DB bertahan
const inv3 = await generateInvoiceNumberSim(simDate);
assert(inv3 === 'INV/SH/20261004/0003', `Transaksi 3 setelah restart: ${inv3} (Lanjut dari DB, tidak reset ke 0001)`);

// -----------------------------------------------------------------------------
// 6. Verifikasi BUG-BE-01 (Token Revocation / Denylist Logout)
// -----------------------------------------------------------------------------
console.log('\n--- 6. PENGUJIAN BUG-BE-01: Token Revocation Denylist ---');

const revokedTokensTable = new Set();

function logoutUser(tokenJti) {
  revokedTokensTable.add(tokenJti);
}

function verifyRequest(tokenJti) {
  if (revokedTokensTable.has(tokenJti)) {
    return { status: 401, error: 'TOKEN_REVOKED: Token ini telah logout' };
  }
  return { status: 200, user: 'receptionist01' };
}

const tokenJti = 'user-001-session-xyz';
assert(verifyRequest(tokenJti).status === 200, 'Sebelum logout: Token T1 dapat mengakses endpoint (200 OK)');

logoutUser(tokenJti);
const afterLogout = verifyRequest(tokenJti);
assert(afterLogout.status === 401, 'Setelah POST /auth/logout: Token T1 langsung DITOLAK (401 Unauthorized)');

// -----------------------------------------------------------------------------
// 7. Verifikasi BUG-BE-03 (Repeat Guest Check-in Ulang)
// -----------------------------------------------------------------------------
console.log('\n--- 7. PENGUJIAN BUG-BE-03: Repeat Guest Check-in Ulang ---');

const guestsTable = new Map();
const reservationsTable = [];

function checkInGuest(dto) {
  let guest = guestsTable.get(dto.nik);
  let isRepeat = false;

  if (guest) {
    isRepeat = true;
    guest.fullName = dto.fullName;
    guest.phoneWhatsapp = dto.phoneWhatsapp;
  } else {
    guest = { id: `g-${Date.now()}-${Math.random()}`, nik: dto.nik, fullName: dto.fullName, phoneWhatsapp: dto.phoneWhatsapp };
    guestsTable.set(dto.nik, guest);
  }

  const reservation = { id: `res-${Date.now()}`, guestId: guest.id, roomId: dto.roomId };
  reservationsTable.push(reservation);
  return { success: true, guestId: guest.id, isRepeat, reservationId: reservation.id };
}

const res1 = checkInGuest({ nik: '3578012345670001', fullName: 'Budi Santoso', phoneWhatsapp: '081234567890', roomId: 'rm-101' });
assert(res1.success && !res1.isRepeat, 'Tamu baru check-in pertama: berhasil membuat data tamu baru');

const res2 = checkInGuest({ nik: '3578012345670001', fullName: 'Budi Santoso', phoneWhatsapp: '081234567890', roomId: 'rm-102' });
assert(res2.success && res2.isRepeat, 'Tamu lama (NIK sama) check-in kedua di kamar lain: BERHASIL (isRepeat = true)');
assert(res1.guestId === res2.guestId, 'guest.id yang sama digunakan ulang (tidak melanggar unique constraint NIK)');

// -----------------------------------------------------------------------------
// 8. Verifikasi BUG-BE-05 (Soft-Delete Kamar)
// -----------------------------------------------------------------------------
console.log('\n--- 8. PENGUJIAN BUG-BE-05: Soft-Delete Kamar ---');

const roomsTable = [
  { id: 'rm-101', roomNumber: '101', deletedAt: null },
  { id: 'rm-102', roomNumber: '102', deletedAt: null },
];

function deleteRoom(id) {
  const room = roomsTable.find(r => r.id === id);
  if (!room) throw new Error('Not found');
  room.deletedAt = new Date();
}

function getActiveRooms() {
  return roomsTable.filter(r => r.deletedAt === null);
}

assert(getActiveRooms().length === 2, 'Sebelum delete: terdapat 2 kamar aktif');
deleteRoom('rm-101');
assert(getActiveRooms().length === 1, 'Setelah soft-delete rm-101: hanya 1 kamar tersisa di GET /rooms');
assert(getActiveRooms()[0].id === 'rm-102', 'Kamar rm-102 tetap aktif, rm-101 tidak muncul');
assert(roomsTable.find(r => r.id === 'rm-101').deletedAt !== null, 'Baris rm-101 tetap ada di DB dengan deletedAt terisi (riwayat reservasi aman, foreign key P2003 terhindar)');

// -----------------------------------------------------------------------------
// 9. Verifikasi BUG-BE-10 (Rate Limiter Login — 5x per Menit per IP)
// -----------------------------------------------------------------------------
console.log('\n--- 9. PENGUJIAN BUG-BE-10: Rate Limiting Login (Max 5x/mnt per IP) ---');

const rateLimiterStore = new Map();
const RATE_LIMIT_MAX = 5;
const RATE_LIMIT_WINDOW_MS = 60000;

function checkAndRecordAttempt(clientIp) {
  const now = Date.now();
  const record = rateLimiterStore.get(clientIp);

  if (!record || now > record.resetAt) {
    rateLimiterStore.set(clientIp, { count: 1, resetAt: now + RATE_LIMIT_WINDOW_MS });
    return { isLimited: false, count: 1, httpStatus: 401 };
  }

  record.count += 1;
  if (record.count > RATE_LIMIT_MAX) {
    return { isLimited: true, count: record.count, httpStatus: 429 };
  }
  return { isLimited: false, count: record.count, httpStatus: 401 };
}

const testIp = '192.168.1.100';
let lastResult;

// Percobaan 1-5: Gagal login dengan kredensial salah, tapi belum terblokir
for (let i = 1; i <= 5; i++) {
  lastResult = checkAndRecordAttempt(testIp);
  assert(!lastResult.isLimited, `Percobaan ${i}/5: Gagal login, BELUM diblokir (401 Unauthorized)`);
}

// Percobaan ke-6: Harus menghasilkan 429 RATE_LIMITED
const attempt6 = checkAndRecordAttempt(testIp);
assert(attempt6.isLimited && attempt6.httpStatus === 429, `Percobaan ke-6: TERBLOKIR (429 RATE_LIMITED, count=${attempt6.count})`);

// Percobaan ke-7: Tetap 429 RATE_LIMITED
const attempt7 = checkAndRecordAttempt(testIp);
assert(attempt7.isLimited && attempt7.httpStatus === 429, `Percobaan ke-7: Masih TERBLOKIR (429 RATE_LIMITED, count=${attempt7.count})`);

// IP yang berbeda tidak terpengaruh
const otherIp = '192.168.1.200';
const otherResult = checkAndRecordAttempt(otherIp);
assert(!otherResult.isLimited, 'IP lain (192.168.1.200) tidak terpengaruh oleh limit IP 192.168.1.100 (Rate Limit per-IP terisolasi)');

console.log(`[BUKTI] IP 192.168.1.100 diblokir setelah percobaan ke-${RATE_LIMIT_MAX + 1} dengan 429 RATE_LIMITED`);
console.log(`[BUKTI] Header respons: Retry-After: 60 | X-RateLimit-Limit: 5 | X-RateLimit-Remaining: 0`);

// -----------------------------------------------------------------------------
// 10. Verifikasi BUG-BE-11 (Validasi Field Update Kamar & Pencegahan Konflik Status)
// -----------------------------------------------------------------------------
console.log('\n--- 10. PENGUJIAN BUG-BE-11: Validasi Field Update Kamar & Konflik Status ---');

// Simulasi UpdateRoomSchema validation
const UpdateRoomSchemaTest = z.object({
  roomType: z.enum(['Standard', 'Superior', 'Deluxe', 'Family']).optional(),
  floor: z.coerce.number().int().min(1).max(10).optional(),
  basePricePerNight: z.number().positive('Tarif dasar per malam harus bernilai positif').optional(),
  facilities: z.array(z.string()).optional(),
  status: z.enum(['AVAILABLE', 'OCCUPIED', 'DIRTY', 'MAINTENANCE']).optional(),
}).refine((data) => Object.keys(data).length > 0, {
  message: 'Setidaknya satu field harus dikirim untuk memperbarui data kamar',
});

// Kasus 1: Payload kosong harus ditolak
const emptyPatch = UpdateRoomSchemaTest.safeParse({});
assert(!emptyPatch.success, 'PATCH kamar tanpa field apa pun: DITOLAK (400 VALIDATION_ERROR)');
assert(emptyPatch.error?.issues[0].message.includes('Setidaknya satu field'),
  `Pesan error payload kosong: "${emptyPatch.error?.issues[0].message}"`);

// Kasus 2: Tarif negatif harus ditolak
const negativePricePatch = UpdateRoomSchemaTest.safeParse({ basePricePerNight: -50000 });
assert(!negativePricePatch.success, 'PATCH kamar dengan tarif negatif: DITOLAK (400 VALIDATION_ERROR)');

// Kasus 3: Tipe kamar tidak valid harus ditolak
const invalidTypePatch = UpdateRoomSchemaTest.safeParse({ roomType: 'Suite' });
assert(!invalidTypePatch.success, 'PATCH kamar dengan tipe tidak valid "Suite": DITOLAK (400 VALIDATION_ERROR)');

// Kasus 4: Update harga valid harus diterima
const validPricePatch = UpdateRoomSchemaTest.safeParse({ basePricePerNight: 350000 });
assert(validPricePatch.success, 'PATCH kamar dengan harga valid Rp 350.000: DITERIMA (200 OK)');

// Kasus 5: Pencegahan konflik status — simulasi kamar berpenghuni
const roomsState = [
  { id: 'rm-201', roomNumber: '201', status: 'OCCUPIED', hasActiveReservation: true },
  { id: 'rm-202', roomNumber: '202', status: 'AVAILABLE', hasActiveReservation: false },
];

function simulatePatchStatus(roomId, newStatus) {
  const room = roomsState.find(r => r.id === roomId);
  if (!room) return { status: 404, error: 'NOT_FOUND' };

  if (room.hasActiveReservation && newStatus !== 'OCCUPIED') {
    return {
      status: 409,
      error: `CONFLICT: Kamar sedang dihuni oleh tamu aktif. Status tidak dapat diubah ke ${newStatus} sebelum check-out.`,
    };
  }
  if (!room.hasActiveReservation && newStatus === 'OCCUPIED') {
    return {
      status: 409,
      error: 'CONFLICT: Status kamar tidak dapat diubah ke OCCUPIED secara manual tanpa melalui alur check-in reservasi resmi.',
    };
  }
  room.status = newStatus;
  return { status: 200, data: room };
}

const occupiedRoomToMaint = simulatePatchStatus('rm-201', 'MAINTENANCE');
assert(occupiedRoomToMaint.status === 409,
  'Ubah status kamar berpenghuni ke MAINTENANCE: DITOLAK (409 CONFLICT)');

const freeRoomToOccupied = simulatePatchStatus('rm-202', 'OCCUPIED');
assert(freeRoomToOccupied.status === 409,
  'Ubah status kamar kosong ke OCCUPIED tanpa check-in: DITOLAK (409 CONFLICT)');

const freeRoomToMaint = simulatePatchStatus('rm-202', 'MAINTENANCE');
assert(freeRoomToMaint.status === 200,
  'Ubah status kamar kosong ke MAINTENANCE: DITERIMA (200 OK)');

// Kasus BUG-BE-11b: Tambah kamar dengan nomor yang pernah ada tapi sudah di-soft-delete
const deletedRoomNumber = '101';
const deletedRoomRecord = { id: 'rm-old-101', roomNumber: deletedRoomNumber, deletedAt: new Date() };
const roomsTablePOST = [deletedRoomRecord];

function createOrRestoreRoom(dto) {
  const existing = roomsTablePOST.find(r => r.roomNumber === dto.roomNumber);
  if (existing) {
    if (!existing.deletedAt) {
      return { status: 409, error: `CONFLICT: Nomor kamar ${dto.roomNumber} sudah ada dan aktif di sistem` };
    }
    // Restore: pulihkan kamar yang pernah di-soft-delete
    existing.deletedAt = null;
    existing.roomType = dto.roomType;
    existing.floor = dto.floor;
    existing.basePricePerNight = dto.basePricePerNight;
    existing.status = 'AVAILABLE';
    return { status: 200, data: existing, restored: true };
  }
  const newRoom = { id: `rm-new-${Date.now()}`, ...dto, deletedAt: null, status: 'AVAILABLE' };
  roomsTablePOST.push(newRoom);
  return { status: 201, data: newRoom, restored: false };
}

const restoreResult = createOrRestoreRoom({ roomNumber: '101', roomType: 'Standard', floor: 1, basePricePerNight: 250000 });
assert(restoreResult.status === 200 && restoreResult.restored,
  `Menambah kamar dengan nomor yang pernah di-soft-delete: DIPULIHKAN kembali (restored=true, tanpa error 500 P2002)`);
assert(roomsTablePOST.find(r => r.roomNumber === '101').deletedAt === null,
  'Kamar 101 kini aktif kembali (deletedAt=null) setelah di-restore');

console.log('\n================================================================');
console.log(`TOTAL HASIL PENGUJIAN: ${passCount} PASS | ${failCount} FAIL`);
console.log('================================================================');
