import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';

// --- SUPABASE CONNECTION CONFIG ---
// Get this from Project Settings > Database > Connection String > URI
final String _dbHost = 'db.ipmkemontxkxzfymidej.supabase.co';
final int _dbPort = 5432;
final String _dbName = 'postgres';
final String _dbUser = 'postgres';
final String _dbPassword = 'Anime456789928&*&';

late Connection conn;

void main() async {
  // 1. Establish Secure Connection to Supabase
  try {
    conn = await Connection.open(
      Endpoint(
        host: _dbHost,
        port: _dbPort,
        database: _dbName,
        username: _dbUser,
        password: _dbPassword,
      ),
      settings: ConnectionSettings(sslMode: SslMode.require),
    );
    print('✅ Connected to Supabase Cloud Engine');
  } catch (e) {
    print('❌ Supabase Connection Failed: $e');
    return;
  }

  final router = Router();

  // API for the Windows Webcam Scanner
  router.post('/api/verify-payment', (Request request) async {
    final payload = jsonDecode(await request.readAsString());
    final String paymentId = payload['payment_id'];
    final String refNo = payload['reference_no'];

    try {
      // Updating this row directly in Supabase
      await conn.execute(
        r'UPDATE payments SET status = $1, reference_no = $2 WHERE id = $3',
        parameters: ['Paid', refNo, paymentId],
      );

      print('💰 Payment Confirmed: $refNo');
      return Response.ok(jsonEncode({'status': 'success'}));
    } catch (e) {
      return Response.internalServerError(body: 'Sync Fault: $e');
    }
  });

  // API to process payment for an Office Request via QR Hash
  router.post('/api/pay-request', (Request request) async {
    final payload = jsonDecode(await request.readAsString());
    final String qrHash = payload['qr_hash'];
    final String method = payload['payment_method'] ?? 'Cash';

    try {
      // 1. Find the request and student
      final result = await conn.execute(
        r'SELECT student_id, amount_due FROM office_requests WHERE qr_hash = $1 AND payment_status = $2',
        parameters: [qrHash, 'Unpaid'],
      );

      if (result.isEmpty)
        return Response.notFound('Request not found or already paid');

      final studentId = result.first[0];
      final amountDue = result.first[1] as double;

      // 2. Update request status
      await conn.execute(
        r'UPDATE office_requests SET payment_status = $1, request_status = $2 WHERE qr_hash = $3',
        parameters: ['Paid', 'Processing', qrHash],
      );

      // 3. Deduct from student balance (Automatic Reflection)
      await conn.execute(
        r'UPDATE student_details SET account_balance = account_balance - $1 WHERE profile_id = $2',
        parameters: [amountDue, studentId],
      );

      // 4. Record the payment
      await conn.execute(
        r'INSERT INTO payments (student_id, amount_paid, category, payment_method, status, reference_no) VALUES ($1, $2, $3, $4, $5, $6)',
        parameters: [
          studentId,
          amountDue,
          'Office Request',
          method,
          'Paid',
          'QR-$qrHash'
        ],
      );

      return Response.ok(jsonEncode({'status': 'success'}));
    } catch (e) {
      return Response.internalServerError(body: 'Sync Fault: $e');
    }
  });

  final handler =
      const Pipeline().addMiddleware(logRequests()).addHandler(router.call);

  final server = await serve(handler, InternetAddress.anyIPv4, 8080);
  print('🚀 UEMS Logic Gateway live on port ${server.port}');
}
