import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/office_request_service.dart';

class OfficeRequestForm extends StatefulWidget {
  const OfficeRequestForm({super.key});

  @override
  State<OfficeRequestForm> createState() => _OfficeRequestFormState();
}

class _OfficeRequestFormState extends State<OfficeRequestForm> {
  String _selectedOffice = 'admissions';
  String _requestType = '';
  final TextEditingController _descriptionController = TextEditingController();

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1033);

  final Map<String, Map<String, dynamic>> officeDetails = {
    'admissions': {
      'name': 'Admissions',
      'icon': LucideIcons.userPlus,
      'color': Colors.blue,
      'requests': [
        'Application Status',
        'Admission Requirements',
        'Schedule Campus Tour',
        'Submit Application'
      ],
    },
    'registrar': {
      'name': 'Registrar',
      'icon': LucideIcons.users,
      'color': Colors.green,
      'requests': [
        'Transcript Request',
        'Grade Verification',
        'Schedule Change',
        'Enrollment Confirmation'
      ],
    },
    'accounting': {
      'name': 'Accounting',
      'icon': LucideIcons.wallet,
      'color': Colors.orange,
      'requests': [
        'Payment Plan',
        'Invoice Inquiry',
        'Refund Request',
        'Financial Aid Status'
      ],
    },
  };

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top-level title removed to avoid duplication with page header.
        // Content now starts directly with the first section.
        // Office Selection Row
        Text(
          'Select Office',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: officeDetails.entries.map((entry) {
            final isSelected = _selectedOffice == entry.key;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _selectedOffice = entry.key;
                  _requestType = '';
                }),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                      color: isSelected
                          ? entry.value['color'].withOpacity(0.2)
                          : surfaceDark,
                      border: Border.all(
                        color: isSelected ? entry.value['color'] : aViolet.withOpacity(0.12),
                        width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        entry.value['icon'],
                        color: isSelected ? entry.value['color'] : Colors.white54,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.value['name'],
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        // Request Type Selection
        Text(
          'Request Type',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: officeDetails[_selectedOffice]!['requests']
                .map<Widget>((request) {
                  final isSelected = _requestType == request;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => setState(() => _requestType = request),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                            color: isSelected
                                ? aViolet.withOpacity(0.3)
                                : aViolet.withOpacity(0.04),
                          border: Border.all(
                              color: isSelected
                                  ? aViolet
                                  : aViolet.withOpacity(0.12),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          request,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected ? aViolet : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  );
                })
                .toList(),
          ),
        ),
        const SizedBox(height: 24),
        // Description
        Text(
          'Additional Details',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 12),
          TextField(
          controller: _descriptionController,
          maxLines: 4,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Provide any additional information...',
            hintStyle: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
            filled: true,
            fillColor: aViolet.withOpacity(0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: aViolet, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Submit Button
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _requestType.isEmpty
                    ? null
                    : () {
                        // Persist request for admin verification
                        OfficeRequestService().addRequest(
                          office: _selectedOffice,
                          requestType: _requestType,
                          details: _descriptionController.text.trim(),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Request submitted and pending admin approval'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _descriptionController.clear();
                        setState(() => _requestType = '');
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: aViolet,
                    disabledBackgroundColor: aViolet.withOpacity(0.06),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Submit Request',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _descriptionController.clear();
                  setState(() => _requestType = '');
                },
                style: OutlinedButton.styleFrom(
                    side: BorderSide(color: aViolet.withOpacity(0.12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Clear',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
