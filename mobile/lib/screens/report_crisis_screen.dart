import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
// In a real app we'd use image_picker

class ReportCrisisScreen extends ConsumerStatefulWidget {
  const ReportCrisisScreen({super.key});

  @override
  ConsumerState<ReportCrisisScreen> createState() => _ReportCrisisScreenState();
}

class _ReportCrisisScreenState extends ConsumerState<ReportCrisisScreen> {
  File? _imageFile;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;

  Future<void> _pickAndAnalyzeImage() async {
    // Mocking the image picker and analysis delay
    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    await Future.delayed(const Duration(seconds: 3));

    // Mock response from Gemini Vision endpoint
    setState(() {
      _isAnalyzing = false;
      _imageFile = File('mock_path'); // Mock file
      _analysisResult = {
        "crisis_type": "urban_flooding",
        "severity": 4,
        "water_depth_estimate_cm": 45,
        "stranded_vehicles": [
          {"bbox": [100, 150, 300, 250], "label": "Stranded Car"} // [x1, y1, x2, y2]
        ],
        "visible_text": ["G-10 Markaz"]
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vision Report')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: _imageFile == null
                  ? const Center(child: Icon(Icons.camera_alt, size: 64, color: Colors.white24))
                  : _buildImageWithOverlay(),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _pickAndAnalyzeImage,
              icon: _isAnalyzing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.upload),
              label: Text(_isAnalyzing ? 'Gemini 3 Pro is analyzing...' : 'Upload Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            if (_analysisResult != null) ...[
              const SizedBox(height: 24),
              const Text('Analysis Results', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildResultCard(),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildImageWithOverlay() {
    // In reality, we'd use CustomPaint to draw the bounding boxes over the Image.file
    // For this scaffold, we simulate the overlay.
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.image, size: 64, color: Colors.white54),
              Text('Mock Flood Image'),
            ],
          ),
        ),
        // Mock Bounding Box
        Positioned(
          left: 100,
          top: 100,
          width: 150,
          height: 80,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.redAccent, width: 2),
              color: Colors.redAccent.withOpacity(0.2),
            ),
            child: const Align(
              alignment: Alignment.topLeft,
              child: Container(
                color: Colors.redAccent,
                padding: EdgeInsets.all(2),
                child: Text('Stranded Car', style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRow('Type', _analysisResult!['crisis_type']),
            _buildRow('Severity', '${_analysisResult!['severity']}/5'),
            _buildRow('Water Depth', '${_analysisResult!['water_depth_estimate_cm']} cm'),
            _buildRow('Text Found', _analysisResult!['visible_text'].join(', ')),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
