import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '../../../../lib/prisma';
import { RoomService } from '../../../../lib/services/room.service';
import { UpdateRoomSchema } from '../../../../lib/validators';

/**
 * GET /api/rooms/[id]
 */
export async function GET(request: NextRequest, { params }: { params: { id: string } }) {
  try {
    const room = await RoomService.getRoomById(prisma, params.id);
    return NextResponse.json({ success: true, data: room });
  } catch (err: any) {
    if (err.message.startsWith('NOT_FOUND')) {
      return NextResponse.json(
        { success: false, error: { code: 'NOT_FOUND', message: err.message.replace('NOT_FOUND: ', '') } },
        { status: 404 }
      );
    }
    return NextResponse.json(
      { success: false, error: { code: 'INTERNAL_ERROR', message: err.message } },
      { status: 500 }
    );
  }
}

/**
 * PATCH /api/rooms/[id]
 * BUG-BE-11 FIX: Validasi ketat field update kamar (UpdateRoomSchema) & pencegahan konflik status kamar aktif
 */
export async function PATCH(request: NextRequest, { params }: { params: { id: string } }) {
  try {
    const role = request.headers.get('x-user-role');
    const userId = request.headers.get('x-user-id');

    if (role !== 'MANAGER') {
      return NextResponse.json(
        { success: false, error: { code: 'FORBIDDEN', message: 'Hanya MANAGER yang berhak mengubah data kamar' } },
        { status: 403 }
      );
    }

    const body = await request.json();

    // 1. Validasi skema DTO dengan Zod (BUG-BE-11)
    const validation = UpdateRoomSchema.safeParse(body);
    if (!validation.success) {
      return NextResponse.json(
        {
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: validation.error.issues[0].message,
            fields: validation.error.issues,
          },
        },
        { status: 400 }
      );
    }

    const dataToUpdate = validation.data;

    // 2. Cek keberadaan kamar
    const room = await prisma.room.findFirst({
      where: { id: params.id, deletedAt: null },
    });

    if (!room) {
      return NextResponse.json(
        { success: false, error: { code: 'NOT_FOUND', message: 'Kamar tidak ditemukan atau telah dihapus' } },
        { status: 404 }
      );
    }

    // 3. Pencegahan Konflik Status (BUG-BE-11):
    // Cek apakah ada tamu aktif yang sedang menginap di kamar ini
    const activeReservation = await prisma.reservation.findFirst({
      where: { roomId: params.id, actualCheckOutTime: null },
    });

    if (activeReservation) {
      // Kamar berpenghuni: DILARANG mengubah status ke AVAILABLE, DIRTY, atau MAINTENANCE secara manual
      if (dataToUpdate.status && dataToUpdate.status !== 'OCCUPIED') {
        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'CONFLICT',
              message: `Kamar sedang dihuni oleh tamu aktif (Reservasi ID: ${activeReservation.id}). Status tidak dapat diubah ke ${dataToUpdate.status} sebelum proses check-out diselesaikan.`,
            },
          },
          { status: 409 }
        );
      }
    } else {
      // Kamar tidak berpenghuni: DILARANG mengubah status langsung ke OCCUPIED tanpa alur reservasi resmi
      if (dataToUpdate.status === 'OCCUPIED') {
        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'CONFLICT',
              message: 'Status kamar tidak dapat diubah ke OCCUPIED secara manual tanpa melalui alur check-in reservasi resmi.',
            },
          },
          { status: 409 }
        );
      }
    }

    const updatedRoom = await prisma.room.update({
      where: { id: params.id },
      data: {
        roomType: dataToUpdate.roomType ?? room.roomType,
        floor: dataToUpdate.floor ?? room.floor,
        basePricePerNight: dataToUpdate.basePricePerNight ?? room.basePricePerNight,
        facilities: dataToUpdate.facilities ?? room.facilities,
        status: dataToUpdate.status ?? room.status,
      },
    });

    await prisma.activityLog.create({
      data: {
        userId,
        actionType: dataToUpdate.basePricePerNight ? 'EDIT_PRICE' : 'EDIT_ROOM_STATUS',
        resourceType: 'room',
        resourceId: room.id,
        details: dataToUpdate,
      },
    });

    return NextResponse.json({ success: true, data: updatedRoom });
  } catch (err: any) {
    console.error('[PATCH /api/rooms/[id]] Error:', err);
    return NextResponse.json(
      { success: false, error: { code: 'INTERNAL_ERROR', message: err.message } },
      { status: 500 }
    );
  }
}


/**
 * DELETE /api/rooms/[id]
 * BUG-BE-05 FIX: Soft-delete kamar untuk mencegah PostgreSQL P2003 Foreign Key Constraint Violation.
 */
export async function DELETE(request: NextRequest, { params }: { params: { id: string } }) {
  try {
    const role = request.headers.get('x-user-role');
    const userId = request.headers.get('x-user-id');

    if (role !== 'MANAGER') {
      return NextResponse.json(
        { success: false, error: { code: 'FORBIDDEN', message: 'Hanya MANAGER yang berhak menghapus unit kamar' } },
        { status: 403 }
      );
    }

    const result = await RoomService.removeRoom(prisma, params.id, userId || undefined);

    return NextResponse.json({
      success: true,
      data: { message: result.message },
    });
  } catch (err: any) {
    if (err.message.startsWith('NOT_FOUND')) {
      return NextResponse.json(
        { success: false, error: { code: 'NOT_FOUND', message: err.message.replace('NOT_FOUND: ', '') } },
        { status: 404 }
      );
    }
    if (err.message.startsWith('CONFLICT')) {
      return NextResponse.json(
        { success: false, error: { code: 'CONFLICT', message: err.message.replace('CONFLICT: ', '') } },
        { status: 409 }
      );
    }
    console.error('[DELETE /api/rooms/[id]] Error:', err);
    return NextResponse.json(
      { success: false, error: { code: 'INTERNAL_ERROR', message: err.message } },
      { status: 500 }
    );
  }
}
