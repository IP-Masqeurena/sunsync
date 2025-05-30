import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../utils/image_compressor.dart';
import '../widgets/bottom_nav.dart';

class DetailsPage extends StatefulWidget {
  final String uid;
  const DetailsPage({required this.uid, super.key});
  @override _DPState createState() => _DPState();
}

class _DPState extends State<DetailsPage> {
  final picker = ImagePicker();
  File? photo;
  bool isUnder = true, saving = false;
  final us = UserService();

  final ctrls = {
    'full_name': TextEditingController(),
    'student_id': TextEditingController(),
    'age': TextEditingController(),
    'course': TextEditingController(),
  };

  int? gradYear;
  String? jobSector = 'Unknown';
  String? occupation;
  int? yearFirstJob;
  String? timesSwitched = 'None';
  bool workOverseas = false;
  String? workMode = 'Office';

  final years = List.generate(2050 - 1980 + 1, (i) => 1980 + i);
  final sectors = [
    'Technology & Digital Services',
    'Engineering',
    'Healthcare',
    'Financial Services',
    'Business & Management',
    'Unknown',
  ];
  final occMap = {
    'Technology & Digital Services': [
      'Cybersecurity Specialist',
      'Data Scientist / Data Analyst',
      'Software Engineer / Developer',
      'Digital Marketing Specialist',
      'E-commerce Specialist',
      'IT Project Manager',
      'Blockchain Developer',
      'Others',
    ],
    'Engineering': [
      'Electrical & Electronic (E&E) Engineer',
      'Mechanical Engineer',
      'Civil Engineer',
      'Chemical Engineer',
      'Others',
    ],
    'Healthcare': [
      'Medical Doctor',
      'Nurses',
      'Pharmacist',
      'Dentist',
    ],
    'Financial Services': [
      'Financial Analyst',
      'Accountant / Auditor',
    ],
    'Business & Management': [
      'Project Manager',
      'Business Analyst',
      'Human Resources Specialist',
    ],
    'Unknown': [],
  };
  final switchOptions = ['None', '1', '2', '3', '4', '5', 'More than 5'];
  final workModeOptions = ['Office', 'Hybrid', 'Remote'];


void _showYearPicker({
  required BuildContext context,
  required int? initialYear,
  required ValueChanged<int?> onYearSelected,
}) {
  final years = List.generate(2050 - 1980 + 1, (i) => 1980 + i);
  int selectedYear = initialYear ?? years.first;
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Container(
        height: 250,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    onYearSelected(selectedYear);
                    Navigator.pop(context);
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
            Expanded(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem: years.indexOf(selectedYear).clamp(0, years.length-1),
                ),
                itemExtent: 40,
                onSelectedItemChanged: (index) {
                  selectedYear = years[index];
                },
                children: years.map((year) => Center(child: Text(year.toString()))).toList(),
              ),
            ),
          ],
        ),
      );
    },
  );
}


  Future pick() async {
    final p = await picker.pickImage(source: ImageSource.gallery);
    if (p != null) {
      final compressed = await ImageCompressor.compress(File(p.path));
      if (compressed != null) {
        setState(() => photo = compressed);
      }
    }
  }

  Future submit() async {
    setState(() => saving = true);
    String? url;
    if (photo != null) {
      url = await us.uploadAvatar(widget.uid, photo!);
    }

    final data = <String, dynamic>{
      'email': AuthService().currentUser!.email,
      'full_name': ctrls['full_name']!.text.trim(),
      'student_id': ctrls['student_id']!.text.trim(),
      'age': int.tryParse(ctrls['age']!.text.trim()),
      'course': ctrls['course']!.text.trim(),
      'grad_year': gradYear,
      'is_undergrad': isUnder,
      'job_sector': jobSector,
      'occupation': occupation ?? '',
      'year_first_job': yearFirstJob,
      'times_switched_jobs': timesSwitched,
      'work_overseas': workOverseas,
      'work_mode': workMode,
      if (url != null) 'avatar_url': url,
    };

    await us.saveDetails(widget.uid, data);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const BottomNav()),
      (_) => false
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          GestureDetector(
            onTap: pick,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 2
                ),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                backgroundImage: photo != null ? FileImage(photo!) : null,
                child: photo == null
                    ? Icon(Icons.camera_alt, 
                        size: 40, 
                        color: Theme.of(context).colorScheme.onSurfaceVariant)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 24),

          Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Undergrad'),
                        ),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Postgrad'),
                        ),
                      ),
                    ],
                    selected: {isUnder},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() => isUnder = newSelection.first);
                    },
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  for (final key in ['full_name', 'student_id', 'age', 'course'])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextField(
                        controller: ctrls[key],
                        decoration: InputDecoration(
                          labelText: key.replaceAll('_', ' ').toUpperCase(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),

                  TextFormField(
  readOnly: true,
  decoration: InputDecoration(
    labelText: 'Year of Graduation',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    suffixIcon: const Icon(Icons.calendar_today),
  ),
  controller: TextEditingController(text: gradYear?.toString()),
  onTap: () => _showYearPicker(
    context: context,
    initialYear: gradYear,
    onYearSelected: (year) => setState(() => gradYear = year),
  ),
),
                ],
              ),
            ),
          ),

          IgnorePointer(
            ignoring: isUnder,
            child: Opacity(
              opacity: isUnder ? 0.5 : 1,
              child: Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Job Sector',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        value: jobSector,
                        items: sectors
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) => setState(() {
                          jobSector = v;
                          occupation = null;
                        }),
                        borderRadius: BorderRadius.circular(15),
                        icon: const Icon(Icons.arrow_drop_down_rounded),
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Occupation',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        value: occupation,
                        items: occMap[jobSector]!
                            .map<DropdownMenuItem<String>>((o) =>
                              DropdownMenuItem<String>(
                                value: o,
                                child: Text(o),
                              ))
                            .toList(),
                        onChanged: occMap[jobSector]!.isEmpty
                            ? null
                            : (v) => setState(() => occupation = v),
                        borderRadius: BorderRadius.circular(15),
                        icon: const Icon(Icons.arrow_drop_down_rounded),
                      ),
                      const SizedBox(height: 16),

                     TextFormField(
  readOnly: true,
  decoration: InputDecoration(
    labelText: 'Year of First Job',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    suffixIcon: const Icon(Icons.calendar_today),
  ),
  controller: TextEditingController(text: yearFirstJob?.toString()),
  onTap: () => _showYearPicker(
    context: context,
    initialYear: yearFirstJob,
    onYearSelected: (year) => setState(() => yearFirstJob = year),
  ),
),
const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Times Switched Jobs',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        value: timesSwitched,
                        items: switchOptions
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) => setState(() => timesSwitched = v),
                        borderRadius: BorderRadius.circular(15),
                        icon: const Icon(Icons.arrow_drop_down_rounded),
                      ),
                      const SizedBox(height: 16),

                      SwitchListTile(
                        title: const Text('Worked Overseas?'),
                        value: workOverseas,
                        onChanged: (v) => setState(() => workOverseas = v),
                        contentPadding: EdgeInsets.zero,
                        tileColor: Theme.of(context).colorScheme.surfaceVariant,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Work Mode',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        value: workMode,
                        items: workModeOptions
                            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (v) => setState(() => workMode = v),
                        borderRadius: BorderRadius.circular(15),
                        icon: const Icon(Icons.arrow_drop_down_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: saving ? null : submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                saving ? 'Creating Account...' : 'Complete Profile',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}