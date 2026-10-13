// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinarharapan_app/features/room_management/domain/room_model.dart';
import 'package:sinarharapan_app/features/room_management/presentation/room_card.dart';

void main() {
  group('RoomCard Semantics Hierarchy Tests', () {
    testWidgets('Kamar 5A (Tersedia): identifier kartu dan tombol Check-in muncul sebagai node terpisah', (tester) async {
      final handle = tester.ensureSemantics();

      final room5A = RoomModel(
        id: 'room-5A',
        roomNumber: '5A',
        roomType: 'AC',
        floor: 1,
        basePricePerNight: 200000,
        status: RoomStatusType.available,
        facilities: const ['AC', 'WiFi'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 200,
              child: RoomCard(
                room: room5A,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Verifikasi node kartu 'room_card_5A'
      final cardNodeFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.identifier == 'room_card_5A',
      );
      expect(cardNodeFinder, findsOneWidget, reason: 'Kartu room_card_5A harus ada di tree');

      // Verifikasi node tombol aksi 'room_action_checkin_button'
      final actionBtnFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.identifier == 'room_action_checkin_button',
      );
      expect(actionBtnFinder, findsOneWidget, reason: 'Tombol aksi room_action_checkin_button harus ada sebagai node terpisah');

      // Pastikan SemanticsData kedua node terpisah di accessibility tree
      final cardSemantics = tester.getSemantics(cardNodeFinder);
      expect(cardSemantics.identifier, 'room_card_5A');

      final actionSemantics = tester.getSemantics(actionBtnFinder);
      expect(actionSemantics.identifier, 'room_action_checkin_button');
      expect(actionSemantics.hasFlag(SemanticsFlag.isButton), isTrue);

      handle.dispose();
    });

    testWidgets('Kamar Terisi: identifier kartu dan tombol Check-out muncul sebagai node terpisah', (tester) async {
      final handle = tester.ensureSemantics();

      final roomOccupied = RoomModel(
        id: 'room-01',
        roomNumber: '01',
        roomType: 'AC',
        floor: 1,
        basePricePerNight: 170000,
        status: RoomStatusType.occupied,
        facilities: const ['AC', 'WiFi'],
        activeGuestName: 'Tamu Rahasia', // nama tamu nyata dilarang masuk ke identifier
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 200,
              child: RoomCard(
                room: roomOccupied,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Verifikasi identifier kartu TIDAK mengandung nama tamu
      final cardNodeFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.identifier == 'room_card_01',
      );
      expect(cardNodeFinder, findsOneWidget);

      final cardSemantics = tester.getSemantics(cardNodeFinder);
      expect(cardSemantics.identifier, 'room_card_01');
      expect(cardSemantics.identifier.contains('Tamu Rahasia'), isFalse, reason: 'Identifier tidak boleh berisi nama tamu');

      // Verifikasi tombol aksi Check-out
      final actionBtnFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.identifier == 'room_action_checkout_button',
      );
      expect(actionBtnFinder, findsOneWidget);

      final actionSemantics = tester.getSemantics(actionBtnFinder);
      expect(actionSemantics.identifier, 'room_action_checkout_button');
      expect(actionSemantics.hasFlag(SemanticsFlag.isButton), isTrue);

      handle.dispose();
    });
  });
}
