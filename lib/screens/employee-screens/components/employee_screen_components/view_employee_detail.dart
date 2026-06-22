import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewEmployeeScreen extends StatelessWidget {
  final Map<String, dynamic> employee;

  const ViewEmployeeScreen({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String? avatarUrl = employee['avatar_url'];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          employee['full_name'] ?? 'Employee Profile',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // --- HEADER: Avatar & Name ---
            CircleAvatar(
              radius: 55,
              backgroundColor: const Color(0xFF00A36C).withOpacity(0.1),
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null
                  ? Text(
                      employee['full_name']?[0].toUpperCase() ?? 'U',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00A36C),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              employee['full_name'] ?? 'N/A',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00A36C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                employee['job_title'] ?? "Title Not Assigned",
                style: const TextStyle(
                  color: Color(0xFF00A36C),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- SECTION 1: Work Details ---
            _buildSectionHeader(Icons.work_outline, "Work Details"),
            _buildCard([
              _infoTile(Icons.email, "Email", employee['email']),
              _infoTile(
                Icons.phone,
                "Work Phone",
                employee['phone_num']?.toString(),
              ),
              _infoTile(Icons.location_city, "Branch", employee['branch']),
              _infoTile(
                Icons.corporate_fare,
                "Department",
                employee['dept_name'],
              ),
              _infoTile(
                Icons.admin_panel_settings,
                "System Access",
                employee['role'],
              ),
            ]),

            // --- SECTION 2: Professional Background ---
            _buildSectionHeader(
              Icons.school_outlined,
              "Professional Background",
            ),
            _buildCard([
              _infoTile(Icons.menu_book, "Education", employee['education']),
              _infoTile(Icons.star_border, "Core Skills", employee['skills']),
              _infoTile(
                Icons.work_history_outlined,
                "Expertise",
                employee['expertise'],
              ),
            ]),

            // --- SECTION 3: Personal Information ---
            _buildSectionHeader(Icons.person_outline, "Personal Information"),
            _buildCard([
              _infoTile(
                Icons.home_outlined,
                "Home Address",
                employee['address'],
              ),
              _infoTile(
                Icons.cake_outlined,
                "Date of Birth",
                employee['date_of_birth'],
              ),
              _infoTile(Icons.people_outline, "Gender", employee['gender']),
            ]),

            // --- SECTION 4: Emergency Contact ---
            _buildSectionHeader(
              Icons.local_hospital_outlined,
              "Emergency Contact",
            ),
            _buildCard([
              _infoTile(
                Icons.health_and_safety_outlined,
                "Contact Name",
                employee['emergency_contact_name'],
              ),
              _infoTile(
                Icons.phone_in_talk_outlined,
                "Contact Phone",
                employee['emergency_contact_phone'],
              ),
            ]),
            _buildSectionHeader(
              Icons.folder_shared_outlined,
              "Digital Documents",
            ),
            _buildCard([
              _documentTile("Resume / CV", employee['cv_url']),
              _documentTile(
                "Educational Certificate",
                employee['certificate_url'],
              ),
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _documentTile(String label, String? url) {
    final bool hasDoc = url != null && url.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: hasDoc
                ? Colors.blue.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.picture_as_pdf,
            color: hasDoc ? Colors.blue : Colors.grey,
            size: 20,
          ),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          hasDoc ? "Tap to view document" : "Not uploaded",
          style: TextStyle(
            color: hasDoc ? Colors.blue : Colors.grey,
            fontSize: 12,
          ),
        ),
        trailing: hasDoc
            ? const Icon(Icons.download, color: Colors.blue)
            : null,
        onTap: () async {
          if (hasDoc) {
            final Uri uri = Uri.parse(url);
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      ),
    );
  }

  // Helper widget to build the section titles
  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 24.0, bottom: 8.0, top: 16.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to group tiles into a neat card
  Widget _buildCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // Upgraded Info Tile that handles long text gracefully
  Widget _infoTile(IconData icon, String label, String? value) {
    final displayValue = (value == null || value.trim().isEmpty)
        ? 'Not Provided'
        : value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00A36C).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF00A36C), size: 20),
        ),
        title: Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          displayValue,
          style: TextStyle(
            fontSize: 15,
            color: displayValue == 'Not Provided'
                ? Colors.grey.shade400
                : Colors.black87,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}
