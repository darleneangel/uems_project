import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/announcement_service.dart';

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
  final TextEditingController _author = TextEditingController();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _department = TextEditingController();
  final TextEditingController _priority = TextEditingController();
  final TextEditingController _targetAudience = TextEditingController();
  final TextEditingController _content = TextEditingController();
  List<PlatformFile> _attachments = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _author.dispose();
    _title.dispose();
    _department.dispose();
    _priority.dispose();
    _targetAudience.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
      );
      if (result != null) {
        if (!mounted) return;
        setState(() {
          _attachments = result.files;
        });
      }
    } catch (e) {
      debugPrint("Error picking files: $e");
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final ref = DateTime.now().millisecondsSinceEpoch.toString().substring(7);

    try {
      // Await the announcement submission as it now hits Supabase directly
      await AnnouncementService().addAnnouncement(
        office: widget.officeKey,
        title: _title.text.trim(),
        content: '${_content.text.trim()}\n\nPosted by: ${_author.text.trim()}',
        attachments: _attachments.isNotEmpty
            ? _attachments.map((a) => a.name).toList()
            : null,
        department:
            _department.text.trim().isNotEmpty ? _department.text.trim() : null,
        priority:
            _priority.text.trim().isNotEmpty ? _priority.text.trim() : null,
        targetAudience: _targetAudience.text.trim().isNotEmpty
            ? _targetAudience.text.trim()
            : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Announcement submitted — Ref: ANN-$ref (pending admin verification)'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form for next announcement
      _author.clear();
      _title.clear();
      _department.clear();
      _priority.clear();
      _targetAudience.clear();
      _content.clear();
      setState(() => _attachments = []);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to submit: $e'),
            backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _author,
              decoration:
                  const InputDecoration(labelText: 'Author / Office Contact'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Provide a name or contact' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _title,
              decoration:
                  const InputDecoration(labelText: 'Announcement Title'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Provide a title' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _department,
              decoration: const InputDecoration(
                labelText: 'Department (optional)',
                hintText: 'e.g., Undergraduate Admissions',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priority,
              decoration: const InputDecoration(
                labelText: 'Priority (optional)',
                hintText: 'e.g., High, Medium, Critical',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _targetAudience,
              decoration: const InputDecoration(
                labelText: 'Target Audience (optional)',
                hintText: 'e.g., All Students, Graduating Seniors',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _content,
              decoration:
                  const InputDecoration(labelText: 'Announcement Content'),
              maxLines: 8,
              validator: (v) => (v == null || v.isEmpty)
                  ? 'Provide announcement content'
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              'Attachments (images, PDFs)',
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
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B21A8),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Submit Announcement'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
