import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/shared/entities/enums.dart';

void main() {
  test('transport job mapping keeps order, farmer, buyer, and assignment', () {
    final job = mapTransportJob({
      'id': 'tr-1',
      'requestCode': 'TR-000125',
      'orderId': 'order-1',
      'buyerId': 'buyer-1',
      'farmerId': 'farmer-1',
      'product': 'Rice',
      'quantityKg': 100,
      'pickupLabel': 'Farm gate',
      'pickupCity': 'Kurunegala',
      'deliveryLabel': 'Shop, Main street',
      'deliveryCity': 'Colombo',
      'requiredVehicleType': 'small_lorry',
      'distanceKm': 94,
      'estimatedCost': 4200,
      'status': 'waiting_pickup',
      'deliveryMethod': 'bit_app_transport',
      'transporterId': 'transporter-1',
      'driverName': 'Nimal',
      'transporter': {'name': 'Nimal', 'organizationName': 'Green Haul'},
      'vehicle': {'vehicleNumber': 'WP-1234', 'vehicleType': 'small_lorry'},
      'payment': {'paymentStatus': 'paid'},
      'tracking': [
        {'status': 'assigned', 'createdAt': '2026-10-01T08:00:00.000Z', 'note': 'Assigned'},
      ],
    });

    expect(job.orderId, 'order-1');
    expect(job.buyerId, 'buyer-1');
    expect(job.farmerId, 'farmer-1');
    expect(job.transporterId, 'transporter-1');
    expect(job.transporterName, 'Green Haul');
    expect(job.vehicleNumber, 'WP-1234');
    expect(job.status, TransportStatus.waitingPickup);
    expect(job.transportPaymentStatus, PaymentRecordStatus.paid);
    expect(job.tracking.single.status, TransportStatus.assigned);
  });

  test('notification mapping uses the saved user and read time', () {
    final note = mapNotification({
      'id': 'n-1',
      'userId': 'farmer-1',
      'title': 'Bid accepted',
      'body': 'An order has been created.',
      'readAt': null,
      'createdAt': '2026-10-01T08:00:00.000Z',
    });

    expect(note.userId, 'farmer-1');
    expect(note.title, 'Bid accepted');
    expect(note.read, isFalse);
  });
}
