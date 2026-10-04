import { z } from 'zod';

export const LoginSchema = z.object({
  username: z.string().min(3, 'Username minimal 3 karakter'),
  password: z.string().min(6, 'Password minimal 6 karakter'),
});

export const CreateRoomSchema = z.object({
  roomNumber: z.string().min(1, 'Nomor kamar wajib diisi'),
  roomType: z.enum(['Standard', 'Superior', 'Deluxe', 'Family']),
  floor: z.number().int().min(1).max(10),
  basePricePerNight: z.number().positive('Tarif dasar harus positif'),
  facilities: z.array(z.string()).default([]),
});

export const CheckInSchema = z.object({
  roomId: z.string().uuid('ID Kamar harus format UUID'),
  bookingSource: z.enum(['REDDOORZ', 'WALK_IN']),
  reddoorzBookingCode: z.string().optional().nullable(),
  nik: z.string().regex(/^\d{16}$/, 'NIK harus tepat 16 digit angka'),
  fullName: z.string().min(2, 'Nama lengkap minimal 2 karakter'),
  phoneWhatsapp: z.string().regex(/^(\+62|08)\d{8,13}$/, 'Format nomor WhatsApp harus valid (+62/08)'),
  address: z.string().optional().nullable(),
  totalNights: z.number().int().min(1, 'Durasi minimal 1 malam'),
  paymentMethod: z.enum(['CASH', 'QRIS', 'TRANSFER', 'REDDOORZ_PREPAID']),
}).refine((data) => {
  if (data.bookingSource === 'REDDOORZ' && (!data.reddoorzBookingCode || data.reddoorzBookingCode.trim().length === 0)) {
    return false;
  }
  return true;
}, {
  message: 'Kode Booking RedDoorz wajib diisi jika kanal adalah REDDOORZ',
  path: ['reddoorzBookingCode'],
});

// BUG-BE-08: Field additionalCharges dan detail nullable & transform to 0 / empty array
export const CheckOutSchema = z.object({
  additionalCharges: z.number().min(0, 'Biaya tambahan tidak boleh negatif').nullable().default(0).transform((val) => val ?? 0),
  additionalChargesDetail: z.array(z.object({
    category: z.enum(['LATE_CHECKOUT', 'MINIBAR', 'LAUNDRY', 'DAMAGE', 'OTHER']).or(z.string()).optional(),
    label: z.string().optional(),
    amount: z.number().min(0, 'Nominal biaya tidak boleh negatif'),
    note: z.string().optional(),
  })).nullable().default([]).transform((val) => val ?? []),
});

// BUG-BE-07: Validasi rentang tanggal ReportQuerySchema maksimal 90 hari
export const ReportQuerySchema = z.object({
  startDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Format tanggal harus YYYY-MM-DD'),
  endDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Format tanggal harus YYYY-MM-DD'),
}).refine((data) => {
  const start = new Date(data.startDate);
  const end = new Date(data.endDate);
  if (isNaN(start.getTime()) || isNaN(end.getTime())) {
    return false;
  }
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

// BUG-BE-09: Pembatasan parameter limit pada query audit logs maksimal 100
export const AuditLogQuerySchema = z.object({
  page: z.coerce.number().int().min(1, 'Halaman minimal 1').default(1),
  limit: z.coerce.number().int().min(1, 'Limit minimal 1').max(100, 'Batas maksimal limit adalah 100 per halaman').default(20),
  actionType: z.string().optional(),
  userId: z.string().uuid().optional(),
  startDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Format tanggal harus YYYY-MM-DD').optional(),
  endDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Format tanggal harus YYYY-MM-DD').optional(),
});

export const RoomQuerySchema = z.object({
  roomType: z.enum(['Standard', 'Superior', 'Deluxe', 'Family']).optional(),
  floor: z.coerce.number().int().min(1).max(10).optional(),
  status: z.enum(['AVAILABLE', 'OCCUPIED', 'DIRTY', 'MAINTENANCE']).optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100, 'Batas maksimal limit adalah 100 per halaman').default(50),
});

// BUG-BE-11: Validasi Field Update Kamar & Pencegahan Konflik Status
export const UpdateRoomSchema = z.object({
  roomType: z.enum(['Standard', 'Superior', 'Deluxe', 'Family']).optional(),
  floor: z.coerce.number().int().min(1).max(10).optional(),
  basePricePerNight: z.number().positive('Tarif dasar per malam harus bernilai positif').optional(),
  facilities: z.array(z.string()).optional(),
  status: z.enum(['AVAILABLE', 'OCCUPIED', 'DIRTY', 'MAINTENANCE']).optional(),
}).refine((data) => {
  return Object.keys(data).length > 0;
}, {
  message: 'Setidaknya satu field harus dikirim untuk memperbarui data kamar',
});

