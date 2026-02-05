import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:file_picker/file_picker.dart' show PlatformFile;

class OfficeRequestView extends StatefulWidget {
  final String officeKey;
  final String officeTitle;
  const OfficeRequestView({
    super.key,
    required this.officeKey,
    required this.officeTitle,
  });

  @override
  State<OfficeRequestView> createState() => _OfficeRequestViewState();
}

class _OfficeRequestViewState extends State<OfficeRequestView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.officeTitle),
        backgroundColor: const Color(0xFF2E1065),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: OfficeRequestForm(officeKey: widget.officeKey),
      ),
    );
  }
}

// Embeddable form widget (can be used inside panels without a Scaffold)
class OfficeRequestForm extends StatefulWidget {
  final String officeKey;
  const OfficeRequestForm({super.key, required this.officeKey});

  @override
  State<OfficeRequestForm> createState() => _OfficeRequestFormState();
}

class _OfficeRequestFormState extends State<OfficeRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _studentId = TextEditingController(
    text: '2025-00001',
  );
  final TextEditingController _name = TextEditingController(
    text: 'DARLENE ANGEL',
  );
  final TextEditingController _program = TextEditingController(
    text: 'BS Computer Science',
  );
  final TextEditingController _year = TextEditingController(text: '3');
  final TextEditingController _contact = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  String _delivery = 'Pickup';
  List<PlatformFile> _attachments = [];

  @override
  void dispose() {
    _studentId.dispose();
    _name.dispose();
    _program.dispose();
    _year.dispose();
    _contact.dispose();
    _notes.dispose();
    super.dispose();
  }

  Widget _officeSpecificFields() {
    switch (widget.officeKey) {
      case 'registrar':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              items: const [
                DropdownMenuItem(
                  value: 'transcript',
                  child: Text('Official Transcript'),
                ),
                DropdownMenuItem(
                  value: 'enrollment',
                  child: Text('Certification of Enrollment'),
                ),
                DropdownMenuItem(
                  value: 'graduation',
                  child: Text('Graduation/Diploma Request'),
                ),
                DropdownMenuItem(
                  value: 'verification',
                  child: Text('Enrollment Verification (Employer)'),
                ),
              ],
              onChanged: (_) {},
              decoration: const InputDecoration(labelText: 'Document Type'),
            ),
            const SizedBox(height: 12),
          ],
        );
      case 'cashier':
        return Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Payment Reference (if any)',
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      case 'financial_aid':
        return Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Scholarship / Aid Type',
              ),
            ),
          ],
        );
      case 'library':
        return Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Book Title / Record',
              ),
            ),
          ],
        );
      case 'student_affairs':
        return Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Request Type (ID / Leave / Permission)',
              ),
            ),
          ],
        );
      case 'health':
        return Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Medical Certificate Type',
              ),
            ),
          ],
        );
      case 'it':
        return Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'System / Service'),
            ),
            const SizedBox(height: 8),
            Text('Examples: Account, Password Reset, Access Request'),
          ],
        );
      case 'career':
        return Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Employer / Company',
              ),
            ),
          ],
        );
      case 'alumni':
        return Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Degree Verification Type',
              ),
            ),
          ],
        );
      case 'exams':
        return Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Exam / Grade Issue',
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _pickFiles() async {
    final result = await file_picker.FilePicker.platform.pickFiles(
      allowMultiple: true,
    );
    if (result != null) {
      setState(() {
        _attachments = result.files;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final id = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Request submitted — Ref: REQ-$id')));
    // For embedded panel, we won't pop a route; parent can clear selected office
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _studentId,
            decoration: const InputDecoration(labelText: 'Student ID'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Full Name'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _program,
            decoration: const InputDecoration(labelText: 'Program'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _year,
            decoration: const InputDecoration(labelText: 'Year / Level'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _contact,
            decoration: const InputDecoration(
              labelText: 'Contact (Email / Phone)',
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Provide contact' : null,
          ),
          const SizedBox(height: 12),

          _officeSpecificFields(),

          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _delivery,
            items: const [
              DropdownMenuItem(value: 'Pickup', child: Text('Pickup')),
              DropdownMenuItem(value: 'Email', child: Text('Email (PDF)')),
              DropdownMenuItem(value: 'Courier', child: Text('Courier')),
            ],
            onChanged: (v) => setState(() => _delivery = v ?? 'Pickup'),
            decoration: const InputDecoration(labelText: 'Delivery Method'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notes,
            decoration: const InputDecoration(
              labelText: 'Notes / Additional Info',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // attachments
          Text(
            'Attachments (ID, Authorization files)',
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: _pickFiles,
                child: const Text('Upload'),
              ),
            ],
          ),
          if (_attachments.isNotEmpty) ...[
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _attachments.map((f) => Text(f.name)).toList(),
            ),
          ],
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B21A8),
              ),
              child: const Text('Submit Request'),
            ),
          ),
        ],
      ),
    );
  }
}
