import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PaymentChannelsPanel extends StatefulWidget {
  final bool isDarkMode;
  const PaymentChannelsPanel({super.key, required this.isDarkMode});

  @override
  State<PaymentChannelsPanel> createState() => _PaymentChannelsPanelState();
}

class _PaymentChannelsPanelState extends State<PaymentChannelsPanel> {
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  String _selectedChannel = 'GCash';
  bool _isProcessing = false;

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  void _generateQRCode() {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter amount first"),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("QR Code - $_selectedChannel"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_2, size: 100, color: Colors.black),
                    SizedBox(height: 8),
                    Text("QR Code", style: TextStyle(color: Colors.black)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Amount: ₱${_amountController.text}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              "Reference: ${_referenceController.text.isEmpty ? 'AUTO-GEN' : _referenceController.text}",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("QR Code saved to gallery"),
                  backgroundColor: Color(0xFF69F0AE),
                ),
              );
            },
            child: const Text("SAVE"),
          ),
        ],
      ),
    );
  }

  void _processBankTransfer() {
    setState(() => _isProcessing = true);
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bank transfer details sent to email"),
            backgroundColor: Color(0xFF69F0AE),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final subTextColor = widget.isDarkMode ? Colors.white54 : Colors.blueGrey;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(cardColor, textColor, subTextColor),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildPaymentForm(cardColor, textColor, subTextColor)),
              const SizedBox(width: 24),
              Expanded(child: _buildChannelInfo(cardColor, textColor, subTextColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color cardColor, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.creditCard, color: Color(0xFF8B5CF6), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Payment Channels",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  "QR GCash, Bank Transfer, and Mode of Payment options",
                  style: GoogleFonts.inter(
                    color: subTextColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm(Color cardColor, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Process Payment",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          
          TextFormField(
            controller: _amountController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: "Amount (₱)",
              labelStyle: TextStyle(
                color: widget.isDarkMode ? Colors.white70 : Colors.black87,
              ),
              hintText: "0.00",
              hintStyle: TextStyle(
                color: widget.isDarkMode ? Colors.white38 : Colors.grey,
              ),
              prefixIcon: Icon(
                LucideIcons.dollarSign,
                color: widget.isDarkMode ? Colors.white54 : Colors.grey,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: widget.isDarkMode ? Colors.white24 : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF8B5CF6),
                  width: 2,
                ),
              ),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _referenceController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: "Reference Number (Optional)",
              labelStyle: TextStyle(
                color: widget.isDarkMode ? Colors.white70 : Colors.black87,
              ),
              hintText: "Leave blank for auto-generation",
              hintStyle: TextStyle(
                color: widget.isDarkMode ? Colors.white38 : Colors.grey,
              ),
              prefixIcon: Icon(
                LucideIcons.hash,
                color: widget.isDarkMode ? Colors.white54 : Colors.grey,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: widget.isDarkMode ? Colors.white24 : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF8B5CF6),
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            initialValue: _selectedChannel,
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
            dropdownColor: widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white,
            decoration: InputDecoration(
              labelText: "Payment Channel",
              labelStyle: TextStyle(
                color: widget.isDarkMode ? Colors.white70 : Colors.black87,
              ),
              prefixIcon: Icon(
                LucideIcons.banknote,
                color: widget.isDarkMode ? Colors.white54 : Colors.grey,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: widget.isDarkMode ? Colors.white24 : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF8B5CF6),
                  width: 2,
                ),
              ),
            ),
            items: [
              'GCash',
              'Bank Transfer - BPI',
              'Bank Transfer - BDO',
              'Bank Transfer - Metrobank',
              'Over the Counter',
            ].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              );
            }).toList(),
            onChanged: (String? value) {
              setState(() => _selectedChannel = value!);
            },
          ),
          const SizedBox(height: 24),
          
          if (_selectedChannel == 'GCash')
            ElevatedButton.icon(
              onPressed: _generateQRCode,
              icon: const Icon(LucideIcons.qrCode, size: 16),
              label: const Text("GENERATE QR CODE"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            )
          else if (_selectedChannel.startsWith('Bank'))
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _processBankTransfer,
              icon: _isProcessing 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(LucideIcons.send, size: 16),
              label: Text(_isProcessing ? "PROCESSING..." : "SEND BANK DETAILS"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please visit the cashier for over-the-counter payments"),
                    backgroundColor: Colors.orangeAccent,
                  ),
                );
              },
              icon: const Icon(LucideIcons.info, size: 16),
              label: const Text("VIEW INSTRUCTIONS"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChannelInfo(Color cardColor, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Channel Information",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          
          _channelInfoCard(
            "GCash",
            "Instant QR payment",
            LucideIcons.qrCode,
            const Color(0xFF00B900),
            textColor,
            subTextColor,
          ),
          const SizedBox(height: 12),
          
          _channelInfoCard(
            "Bank Transfer",
            "2-3 business days",
            LucideIcons.building,
            const Color(0xFF0066CC),
            textColor,
            subTextColor,
          ),
          const SizedBox(height: 12),
          
          _channelInfoCard(
            "Over the Counter",
            "Immediate processing",
            LucideIcons.store,
            const Color(0xFFFF6B35),
            textColor,
            subTextColor,
          ),
          
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.info, color: Color(0xFF8B5CF6), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Processing Times",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "• GCash: Instant\n• Bank Transfer: 2-3 business days\n• Over the Counter: Same day",
                  style: GoogleFonts.inter(
                    color: subTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _channelInfoCard(
    String title,
    String description,
    IconData icon,
    Color color,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration( // Ensure visibility in light mode
        color: widget.isDarkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    color: subTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
