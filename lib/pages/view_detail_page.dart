import 'package:flutter/material.dart';

class ViewDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final String? avatarUrl;

  const ViewDetailPage({
    Key? key,
    required this.data,
    this.avatarUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fullName = data['full_name'] ?? 'User Name';
    final isUndergrad = data['is_undergrad'] == true;
    final subtitle = isUndergrad ? 'Undergraduate' : 'Postgraduate';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with avatar and name
            Container(
              color: Colors.grey.shade200,
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                    child: avatarUrl == null
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            const Divider(height: 1),

            // Detail list
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: data.entries
                    .where((e) => e.key != 'avatar_url' && e.key != 'banner_choice')
                    .map((entry) {
                  final key = _prettyKey(entry.key);
                  final value = entry.value?.toString() ?? '-';
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: ListTile(
                      title: Text(
                        key,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(value),
                    ),
                  );
                }).toList(),
              ),
            )
          ],
        ),
      ),
    );
  }

  String _prettyKey(String key) {
    switch (key) {
      case 'full_name':
        return 'Full Name';
      case 'student_id':
        return 'Student ID';
      case 'age':
        return 'Age';
      case 'grad_year':
        return 'Year Graduated';
      case 'course':
        return 'Course';
      case 'department':
        return 'Department';
      case 'occupation':
        return 'Occupation';
      case 'is_undergrad':
        return 'Undergraduate';
      default:
        return key.replaceAll('_', ' ').splitMapJoin(RegExp(r'\b'), onMatch: (m) => m.group(0)!.toUpperCase());
    }
  }
}
