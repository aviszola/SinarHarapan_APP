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
  address: z.string().optional(),
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

export const CheckOutSchema = z.object({
  additionalCharges: z.number().min(0).default(0),
  additionalChargesDetail: z.array(z.object({
    category: z.enum(['LATE_CHECKOUT', 'MINIBAR', 'LAUNDRY', 'DAMAGE', 'OTHER']),
    amount: z.number().positive(),
    note: z.string().optional(),
  })).default([]),
});

export const ReportQuerySchema = z.object({
  startDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Format tanggal harus YYYY-MM-DD'),
  endDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Format tanggal harus YYYY-MM-DD'),
});
