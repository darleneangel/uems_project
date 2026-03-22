import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/supabase_service.dart';

class AccessSecurityPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const AccessSecurityPanel({
    super.key,
    required this.isDarkMode,
    required this.userData,
  });

  @override
  State<AccessSecurityPanel> createState() => _AccessSecurityPanelState();
}

class _AccessSecurityPanelState extends State<AccessSecurityPanel> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isActionLoading = false;
  Map<String, dynamic>? _lockdownSettings;
  String _searchQuery = "";

  // Institutional Palette
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  @override
  void initState() {
    super.initState();
    _syncSecuritySettings();
  }

  /// 🛰️ DATABASE: Syncs global maintenance/lockdown toggles
  Future<void> _syncSecuritySettings() async {
    if (!mounted) return;
    try {
      final res = await _service.client
          .from('system_settings')
          .select('*')
          .eq('key', 'system_maintenance')
          .maybeSingle();

      setState(() {
        _lockdownSettings = res?['value'];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Security Sync Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 🛰️ DATABASE: Toggles institutional lockdown status
  Future<void> _toggleLockdown(bool isLocked) async {
    setState(() => _isActionLoading = true);
    try {
      final updatedValue = {
        'is_locked': isLocked,
        'message': isLocked ? "System undergoing emergency maintenance." : "",
        'triggered_by': widget.userData['id']
      };

      await _service.client
          .from('system_settings')
          .update({'value': updatedValue}).eq('key', 'system_maintenance');

      await _syncSecuritySettings();
      _showToast(
          isLocked ? "System Lockdown Activated" : "System Access Restored",
          isLocked ? Colors.redAccent : success);
    } catch (e) {
      _showToast("Lockdown Command Failed", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  /// 🛰️ DATABASE: Modifies user account permissions or status
  Future<void> _updateUserAccess(
      String profileId, String role, String status) async {
    setState(() => _isActionLoading = true);
    try {
      await _service.client.from('profiles').update({
        'role': role,
        'account_status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', profileId);

      _showToast("Permissions Synchronized", success);
    } catch (e) {
      _showToast("Update Rejected by Ledger", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final cardColor = widget.isDarkMode ? surfaceDark : Colors.white;

    if (_isLoading)
      return const Center(child: CircularProgressIndicator(color: aViolet));

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(textColor),
          const SizedBox(height: 32),
          _buildModuleLockSection(cardColor, textColor),
          const SizedBox(height: 32),
          Expanded(child: _buildUserIdentityVault(cardColor, textColor)),
        ],
      ),
    );
  }

  Widget _buildHeader(Color t) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("System Access & Security",
              style: GoogleFonts.inter(
                  fontSize: 24, fontWeight: FontWeight.w900, color: t)),
          const Text(
              "Manage institutional user roles, account lifecycle, and emergency module availability.",
              style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
        ],
      );

  Widget _buildModuleLockSection(Color bg, Color text) {
    final bool isLocked = _lockdownSettings?['is_locked'] ?? false;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(28),
          border:
              Border.all(color: isLocked ? Colors.redAccent : Colors.white10),
          boxShadow: [
            if (isLocked)
              BoxShadow(
                  color: Colors.redAccent.withOpacity(0.1), blurRadius: 20)
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: Icon(LucideIcons.shieldAlert,
                    color: isLocked ? Colors.redAccent : Colors.blueGrey),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Emergency System Lockdown",
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: text)),
                    const Text(
                        "Immediately restrict portal access for all Student and Faculty accounts.",
                        style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
                  ],
                ),
              ),
              if (_isActionLoading)
                const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.redAccent))
              else
                Switch(
                  value: isLocked,
                  activeColor: Colors.redAccent,
                  onChanged: (v) => _toggleLockdown(v),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserIdentityVault(Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("IDENTITY AUDIT & ROLE MANAGEMENT",
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: aViolet,
                  letterSpacing: 1.5)),
          const SizedBox(height: 24),
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            style: TextStyle(color: text),
            decoration: InputDecoration(
              hintText: "Search name or ID to manage permissions...",
              prefixIcon:
                  const Icon(LucideIcons.search, size: 18, color: aViolet),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _service.client
                  .from('profiles')
                  .stream(primaryKey: ['id']).order('ln', ascending: true),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final list = snapshot.data!.where((u) {
                  final name = "${u['fn']} ${u['ln']}".toLowerCase();
                  final id =
                      (u['user_id_number'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery) ||
                      id.contains(_searchQuery);
                }).toList();

                if (list.isEmpty) {
                  return const Center(
                      child: Text("No institutional matches found.",
                          style:
                              TextStyle(color: Colors.blueGrey, fontSize: 12)));
                }

                return ListView.separated(
                  itemCount: list.length,
                  physics: const BouncingScrollPhysics(),
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.white10),
                  itemBuilder: (context, i) {
                    final user = list[i];
                    final String status = user['account_status'] ?? 'Active';
                    final bool isSuspended = status == 'Suspended';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: aViolet.withOpacity(0.1),
                        child: Text(user['ln'][0],
                            style: const TextStyle(
                                color: aViolet, fontWeight: FontWeight.bold)),
                      ),
                      title: Text("${user['fn']} ${user['ln']}",
                          style: TextStyle(
                              color: text,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      subtitle: Text(
                          "${user['role'].toString().toUpperCase()} • ID: ${user['user_id_number']}",
                          style: const TextStyle(
                              color: Colors.blueGrey, fontSize: 11)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _statusChip(
                              status, isSuspended ? Colors.redAccent : success),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: Icon(
                                isSuspended
                                    ? LucideIcons.unlock
                                    : LucideIcons.ban,
                                size: 18,
                                color:
                                    isSuspended ? success : Colors.redAccent),
                            onPressed: () => _updateUserAccess(
                                user['id'],
                                user['role'],
                                isSuspended ? 'Active' : 'Suspended'),
                          ),
                          _rolePicker(user),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _rolePicker(Map<String, dynamic> user) {
    return PopupMenuButton<String>(
      icon: const Icon(LucideIcons.userCog, size: 18, color: aViolet),
      color: surfaceDark,
      onSelected: (role) => _updateUserAccess(
          user['id'], role, user['account_status'] ?? 'Active'),
      itemBuilder: (context) => [
        'student',
        'professor',
        'registrar',
        'accounting',
        'hr',
        'pchair'
      ]
          .map((r) => PopupMenuItem(
              value: r,
              child: Text(r.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 11))))
          .toList(),
    );
  }

  Widget _statusChip(String t, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(t,
          style:
              TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w900)));

  void _showToast(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(24),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }
}
