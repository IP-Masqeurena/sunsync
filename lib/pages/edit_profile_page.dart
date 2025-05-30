import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/cupertino.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../utils/image_compressor.dart';
import '../widgets/bottom_nav.dart';

class EditProfilePage extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> existingData;
  const EditProfilePage({required this.uid, required this.existingData, super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _picker = ImagePicker();
  File? _photo;
  bool _isUnder = true, _saving = false;
  final _userSvc = UserService();
  late final Map<String, TextEditingController> _ctrls;

  // Dropdown state
  int?    _gradYear;
  String? _jobSector;
  String? _occupation;
  int?    _yearFirstJob;
  String? _timesSwitched;
  late bool   _workOverseas;
  String? _workMode;

  // Dropdown data
  final List<int> _years = List.generate(2050 - 1980 + 1, (i) => 1980 + i);
  final List<String> _sectors = [
    'Technology & Digital Services',
    'Engineering',
    'Healthcare',
    'Financial Services',
    'Business & Management',
    'Unknown',
  ];
  final Map<String, List<String>> _occMap = {
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
  final List<String> _switchOptions = ['None','1','2','3','4','5','More than 5'];
  final List<String> _workModeOptions = ['Office','Hybrid','Remote'];

  @override
  void initState() {
    super.initState();
    _ctrls = {
      'full_name':      TextEditingController(text: widget.existingData['full_name']),
      'student_id':     TextEditingController(text: widget.existingData['student_id']),
      'age':            TextEditingController(text: widget.existingData['age']?.toString()),
      'course':         TextEditingController(text: widget.existingData['course']),
    };
    _isUnder        = widget.existingData['is_undergrad'] ?? true;
    _gradYear       = widget.existingData['grad_year'];
    _jobSector      = widget.existingData['job_sector'] ?? 'Unknown';
    _occupation     = widget.existingData['occupation']?.toString();
    _yearFirstJob   = widget.existingData['year_first_job'];
    _timesSwitched  = widget.existingData['times_switched_jobs']?.toString() ?? 'None';
    _workOverseas   = widget.existingData['work_overseas'] == true;
    _workMode       = widget.existingData['work_mode']?.toString() ?? 'Office';
  }

  @override
  void dispose() {
    for (var c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future _pickPhoto() async {
    final p = await _picker.pickImage(source: ImageSource.gallery);
    if (p != null) {
      final compressed = await ImageCompressor.compress(File(p.path));
      if (compressed != null) {
        setState(() => _photo = compressed);
      }
    }
  }

  Future _save() async {
    setState(() => _saving = true);
    String? url = widget.existingData['avatar_url'];
    if (_photo != null) {
      url = await _userSvc.uploadAvatar(widget.uid, _photo!) ?? url;
    }
    final data = {
      'full_name':           _ctrls['full_name']!.text.trim(),
      'student_id':          _ctrls['student_id']!.text.trim(),
      'age':                 int.tryParse(_ctrls['age']!.text.trim()),
      'course':              _ctrls['course']!.text.trim(),
      'grad_year':           _gradYear,
      'is_undergrad':        _isUnder,
      'job_sector':          _jobSector,
      'occupation':          _occupation ?? '',
      'year_first_job':      _yearFirstJob,
      'times_switched_jobs': _timesSwitched,
      'work_overseas':       _workOverseas,
      'work_mode':           _workMode,
      if (url != null) 'avatar_url': url,
    };
    await _userSvc.saveDetails(widget.uid, data);
    setState(() => _saving = false);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const BottomNav()),
      (r) => false,
    );
  }

  void _showYearPicker({
  required BuildContext context,
  required int? initialYear,
  required ValueChanged<int?> onYearSelected,
}) {
  int selectedYear = initialYear ?? _years.first;
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
                  initialItem: _years.indexOf(selectedYear).clamp(0, _years.length-1),
                ),
                itemExtent: 40,
                onSelectedItemChanged: (index) {
                  selectedYear = _years[index];
                },
                children: _years.map((year) => Center(child: Text(year.toString()))).toList(),
              ),
            ),
          ],
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final existingUrl = widget.existingData['avatar_url'] as String?;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          GestureDetector(
            onTap: _pickPhoto,
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
                backgroundImage: _photo != null
                    ? FileImage(_photo!)
                    : (existingUrl != null ? NetworkImage(existingUrl) : null) as ImageProvider<Object>?,
                child: _photo==null && existingUrl==null ? 
                  Icon(Icons.camera_alt, size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant) : null,
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
                    selected: {_isUnder},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() => _isUnder = newSelection.first);
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
                  
                  for (final key in ['full_name','student_id','age','course'])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextField(
                        controller: _ctrls[key],
                        decoration: InputDecoration(
                          labelText: key.replaceAll('_',' ').toUpperCase(),
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
      borderRadius: BorderRadius.circular(10),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    suffixIcon: const Icon(Icons.calendar_today),
  ),
  controller: TextEditingController(text: _gradYear?.toString()),
  onTap: () => _showYearPicker(
    context: context,
    initialYear: _gradYear,
    onYearSelected: (year) => setState(() => _gradYear = year),
  ),
),
                ],
              ),
            ),
          ),

          IgnorePointer(
            ignoring: _isUnder,
            child: Opacity(
              opacity: _isUnder ? 0.5 : 1,
              child: Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Job Sector',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        value: _jobSector,
                        items: _sectors
                            .map<DropdownMenuItem<String>>((s) => DropdownMenuItem<String>(
                                  value: s,
                                  child: Text(s),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() {
                          _jobSector = v;
                          _occupation = null;
                        }),
                        borderRadius: BorderRadius.circular(15),
                        icon: const Icon(Icons.arrow_drop_down_rounded),
                      ),
                      const SizedBox(height: 16),
                      
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Occupation',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        value: _occupation,
                        items: _occMap[_jobSector]!
                            .map<DropdownMenuItem<String>>((o) => DropdownMenuItem<String>(
                                  value: o,
                                  child: Text(o),
                                ))
                            .toList(),
                        onChanged: _occMap[_jobSector]!.isEmpty
                            ? null
                            : (v) => setState(() => _occupation = v),
                        borderRadius: BorderRadius.circular(15),
                        icon: const Icon(Icons.arrow_drop_down_rounded),
                      ),
                      const SizedBox(height: 16),
                      
                   TextFormField(
  readOnly: true,
  decoration: InputDecoration(
    labelText: 'Year of First Job',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    suffixIcon: const Icon(Icons.calendar_today),
  ),
  controller: TextEditingController(text: _yearFirstJob?.toString()),
  onTap: () => _showYearPicker(
    context: context,
    initialYear: _yearFirstJob,
    onYearSelected: (year) => setState(() => _yearFirstJob = year),
  ),
),
const SizedBox(height: 16),
                      
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Times Switched Jobs',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        value: _timesSwitched,
                        items: _switchOptions
                            .map<DropdownMenuItem<String>>((s) => DropdownMenuItem<String>(
                                  value: s,
                                  child: Text(s),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _timesSwitched = v),
                        borderRadius: BorderRadius.circular(15),
                        icon: const Icon(Icons.arrow_drop_down_rounded),
                      ),
                      const SizedBox(height: 16),
                      
                      SwitchListTile(
                        title: const Text('Worked Overseas?'),
                        value: _workOverseas,
                        onChanged: (v) => setState(() => _workOverseas = v),
                        contentPadding: EdgeInsets.zero,
                        tileColor: Theme.of(context).colorScheme.surfaceVariant,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Work Mode',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        value: _workMode,
                        items: _workModeOptions
                            .map<DropdownMenuItem<String>>((m) => DropdownMenuItem<String>(
                                  value: m,
                                  child: Text(m),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _workMode = v),
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
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _saving ? 'Saving…' : 'Save Changes',
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