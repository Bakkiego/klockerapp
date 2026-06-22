import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart'; // 🚀 Added
import '../../../providers/user_provider.dart'; // 🚀 Added
import '../../../supabase/repo/supabase_service.dart';

class TicketDetailScreen extends StatefulWidget {
  final Map<String, dynamic> ticket;

  const TicketDetailScreen({super.key, required this.ticket});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  late String _currentStatus;
  bool _isUpdating = false;

  final List<String> _statusOptions = ['Open', 'Pending', 'Resolved'];

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.ticket['status'] ?? 'Open';
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() {
      _currentStatus = newStatus;
      _isUpdating = true;
    });

    try {
      await SupabaseService().updateTicketStatus(
        widget.ticket['id'],
        newStatus,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $newStatus'),
            backgroundColor: const Color(0xFF00A36C),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _openAttachment(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open file'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isImage(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.png');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 🚀 THE BOUNCER: Check if they are a Ticket Manager
    final userProvider = context.watch<UserProvider>();
    final canManageTickets = userProvider.can('manage_tickets');

    final employeeName =
        widget.ticket['employee']?['full_name'] ?? 'Unknown User';
    final attachmentUrl = widget.ticket['attachment_url'];

    String dateStr = 'Unknown Date';
    if (widget.ticket['created_at'] != null) {
      final date = DateTime.parse(widget.ticket['created_at']);
      dateStr = DateFormat('MMM dd, yyyy - h:mm a').format(date);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ticket Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // 🚀 SMART UI: Only show the dropdown to authorized managers
          if (canManageTickets)
            _isUpdating
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : DropdownButton<String>(
                    value: _currentStatus,
                    dropdownColor: theme.scaffoldBackgroundColor,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down),
                    items: _statusOptions.map((status) {
                      Color sColor = status == "Open"
                          ? Colors.redAccent
                          : (status == "Resolved"
                                ? Colors.green
                                : Colors.orange);
                      return DropdownMenuItem(
                        value: status,
                        child: Text(
                          status,
                          style: TextStyle(
                            color: sColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null && val != _currentStatus)
                        _updateStatus(val);
                    },
                  ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER METADATA ---
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.ticket['category'] ?? 'General',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Priority: ${widget.ticket['priority']}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),

                // 🚀 Fallback status badge for baseline users since they can't see the dropdown
                if (!canManageTickets) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _currentStatus == "Resolved"
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Status: $_currentStatus",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _currentStatus == "Resolved"
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            Text(
              widget.ticket['title'] ?? 'No Title',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFF00A36C),
                  radius: 16,
                  child: Icon(Icons.person, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employeeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // --- DESCRIPTION ---
            const Text(
              "Description",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              widget.ticket['description'] ?? 'No description provided.',
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),

            const SizedBox(height: 32),

            // --- ATTACHMENT SECTION ---
            if (attachmentUrl != null) ...[
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                "Attachment",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Intelligent Attachment Display
              if (_isImage(attachmentUrl))
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    attachmentUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        color: Colors.grey.withOpacity(0.1),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00A36C),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 150,
                      color: Colors.red.withOpacity(0.1),
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.red,
                          size: 50,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Card(
                  elevation: 0,
                  color: Colors.grey.withOpacity(0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.insert_drive_file,
                      color: Colors.blue,
                      size: 40,
                    ),
                    title: const Text("Document Attached"),
                    subtitle: const Text("Tap to view or download"),
                    trailing: const Icon(Icons.download),
                    onTap: () => _openAttachment(attachmentUrl),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
