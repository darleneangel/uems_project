import 'package:flutter/foundation.dart';

class OfficeRequest {
  OfficeRequest({
    required this.id,
    required this.office,
    required this.requestType,
    required this.details,
    required this.createdAt,
    this.status = 'pending',
  });

  final int id;
  final String office;
  String requestType;
  String details;
  final DateTime createdAt;
  String status; // 'pending','approved','rejected'
}

class OfficeRequestService {
  OfficeRequestService._internal();
  static final OfficeRequestService _instance = OfficeRequestService._internal();
  factory OfficeRequestService() => _instance;

  final ValueNotifier<List<OfficeRequest>> notifier = ValueNotifier([]);
  int _nextId = 1;

  void addRequest({required String office, required String requestType, required String details}) {
    final req = OfficeRequest(
      id: _nextId++,
      office: office,
      requestType: requestType,
      details: details,
      createdAt: DateTime.now(),
    );
    notifier.value = [req, ...notifier.value];
  }

  List<OfficeRequest> getAll() => notifier.value;

  void approve(int id) {
    final list = notifier.value.map((r) {
      if (r.id == id) r.status = 'approved';
      return r;
    }).toList();
    notifier.value = list;
  }

  void reject(int id) {
    final list = notifier.value.map((r) {
      if (r.id == id) r.status = 'rejected';
      return r;
    }).toList();
    notifier.value = list;
  }

  void updateRequest(int id, {String? requestType, String? details}) {
    final list = notifier.value.map((r) {
      if (r.id == id) {
        if (requestType != null) r.requestType = requestType;
        if (details != null) r.details = details;
      }
      return r;
    }).toList();
    notifier.value = list;
  }

  void archive(int id) {
    final list = notifier.value.map((r) {
      if (r.id == id) r.status = 'archived';
      return r;
    }).toList();
    notifier.value = list;
  }

  void restore(int id) {
    final list = notifier.value.map((r) {
      if (r.id == id) r.status = 'pending';
      return r;
    }).toList();
    notifier.value = list;
  }
}
