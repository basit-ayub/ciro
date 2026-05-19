import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ReportCrisisScreen extends StatefulWidget {
  const ReportCrisisScreen({super.key});

  @override
  State<ReportCrisisScreen> createState() => _ReportCrisisScreenState();
}

class _ReportCrisisScreenState extends State<ReportCrisisScreen> {
  String? _selectedCrisisType;
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  final List<String> _crisisTypes = [
    'Urban Flooding',
    'Structure Collapse',
    'Fire Incident',
    'Traffic / Roadblock',
    'Medical Emergency',
    'Other'
  ];

  void _submitReport() async {
    if (_selectedCrisisType == null || _detailsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide crisis type and details.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Mock network request
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    
    setState(() {
      _isSubmitting = false;
      _detailsController.clear();
      _selectedCrisisType = null;
      _imageFile = null;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.greenAccent),
            SizedBox(width: 8),
            Text('Report Submitted', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Your report has been successfully ingested by the Vision Agent and routed to the Sentinel.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'REPORT A CRISIS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Crisis Type Dropdown
              const Text('Crisis Type', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCrisisType,
                    dropdownColor: const Color(0xFF2A2A2A),
                    hint: const Text('Select the type of incident', style: TextStyle(color: Colors.white38)),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white),
                    items: _crisisTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCrisisType = newValue;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Details Input
              const Text('Context & Details', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _detailsController,
                maxLines: 5,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Describe the situation (e.g., Water levels rising rapidly near the intersection...)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Image Upload
              const Text('Vision Evidence (Optional)', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() {
                      _imageFile = image;
                    });
                  }
                },
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: _imageFile != null ? Colors.green.withOpacity(0.1) : const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _imageFile != null ? Colors.greenAccent : Colors.white10,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _imageFile != null ? Icons.check_circle : Icons.camera_alt,
                          size: 40,
                          color: _imageFile != null ? Colors.greenAccent : Colors.white38,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _imageFile != null ? 'Attached: ${_imageFile!.name}' : 'Tap to attach photo/video',
                          style: TextStyle(
                            color: _imageFile != null ? Colors.greenAccent : Colors.white54,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              
              // Submit Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send),
                            SizedBox(width: 8),
                            Text(
                              'SUBMIT CRITICAL REPORT',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
