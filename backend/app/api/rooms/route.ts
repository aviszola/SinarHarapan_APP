import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '../../../lib/prisma';
import { RoomService } from '../../../lib/services/room.service';
import { CreateRoomSchema, RoomQuerySchema } from '../../../lib/validators';

/**
 * GET /api/rooms
 * BUG-BE-05 FIX: Hanya mengembalikan kamar yang belum dihapus (deletedAt IS NULL)
 */
export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams;
    const query = {
      roomType: searchParams.get('roomType') || undefined,
      floor: searchParams.get('floor') ? Number(searchParams.get('floor')) : undefined,
      status: searchParams.get('status') || undefined,
      page: searchParams.get('page') ? Number(searchParams.get('page')) : 1,
      limit: searchParams.get('limit') ? Number(searchParams.get('limit')) : 50,
    };

    const parsedQuery = RoomQuerySchema.safeParse(query);
    if (!parsedQuery.success) {
      return NextResponse.json(
        {
          success: false,
          error: { code: 'VALIDATION_ERROR', message: parsedQuery.error.issues[0].message },
        },
        { status: 400 }
      );
    }

    const result = await RoomService.getRooms(prisma, parsedQuery.data);

    return NextResponse.json({
      success: true,
      data: result.rooms,
      pagination: result.pagination,
    });
  } catch (err: any) {
    console.error('[GET /api/rooms] Error:', err);
    return NextResponse.json(
      { success: false, error: { code: 'INTERNAL_ERROR', message: err.message } },
      { status: 500 }
    );
  }
}

/**
 * POST /api/rooms
 */
export async function POST(request: NextRequest) {
  try {
    const role = request.headers.get('x-user-role');
    const userId = request.headers.get('x-user-id');

    if (role !== 'MANAGER') {
      return NextResponse.json(
        { success: false, error: { code: 'FORBIDDEN', message: 'Hanya MANAGER yang berhak menambah unit kamar' } },
        { status: 403 }
      );
    }

    const body = await request.json();
    const validation = CreateRoomSchema.safeParse(body);

    if (!validation.success) {
      return NextResponse.json(
        { success: false, error: { code: 'VALIDATION_ERROR', message: validation.error.issues[0].message } },
        { status: 400 }
      );
    }

    const { roomNumber, roomType, floor, basePricePerNight, facilities } = validation.data;

    // Cek apakah nomor kamar sudah pernah terdaftar di database
    const existingRoom = await prisma.room.findFirst({
      where: { roomNumber },
    });

    let room;
    if (existingRoom) {
      if (existingRoom.deletedAt === null) {
        // Kamar aktif sudah ada -> tolak dengan 409 CONFLICT
        return NextResponse.json(
          { success: false, error: { code: 'CONFLICT', message: `Nomor kamar ${roomNumber} sudah ada dan aktif di sistem` } },
          { status: 409 }
        );
      } else {
        // BUG-BE-11: Kamar lama di-soft delete -> pulihkan (restore) dengan data baru, mencegah error 500 P2002
        room = await prisma.room.update({
          where: { id: existingRoom.id },
          data: {
            roomType,
            floor,
            basePricePerNight,
            facilities,
            status: 'AVAILABLE',
            deletedAt: null,
          },
        });
      }
    } else {
      room = await prisma.room.create({
        data: {
          roomNumber,
          roomType,
          floor,
          basePricePerNight,
          facilities,
          status: 'AVAILABLE',
        },
      });
    }

    await prisma.activityLog.create({
      data: {
        userId,
        actionType: 'CREATE_ROOM',
        resourceType: 'room',
        resourceId: room.id,
        details: { roomNumber, roomType, floor, basePricePerNight },
      },
    });

    return NextResponse.json({ success: true, data: room }, { status: 201 });
  } catch (err: any) {
    console.error('[POST /api/rooms] Error:', err);
    return NextResponse.json(
      { success: false, error: { code: 'INTERNAL_ERROR', message: err.message } },
      { status: 500 }
    );
  }
}
