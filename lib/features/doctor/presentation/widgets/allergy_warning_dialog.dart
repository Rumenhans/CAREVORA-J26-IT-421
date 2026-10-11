import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AllergyWarningDialog extends StatefulWidget {
  final String residentName;
  final String medicineName;
  final String allergyMatched;
  final ValueChanged<String> onOverrideApproved;

  const AllergyWarningDialog({
    super.key,
    required this.residentName,
    required this.medicineName,
    required this.allergyMatched,
    required this.onOverrideApproved,
  });

  @override
  State<AllergyWarningDialog> createState() => _AllergyWarningDialogState();
}

class _AllergyWarningDialogState extends State<AllergyWarningDialog> {
  final _reasonController = TextEditingController();
  bool _canOverride = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: const [
          Icon(Icons.warning_amber_rounded, color: AppColors.riskHigh, size: 28),
          SizedBox(width: 10),
          Text(
            'CRITICAL ALLERGY ALERT',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.riskHigh),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Resident ${widget.residentName} has a recorded allergy matching "${widget.allergyMatched}"!',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navy),
            ),
            const SizedBox(height: 10),
            Text(
              'Prescribing ${widget.medicineName} poses a potential severe clinical risk.',
              style: const TextStyle(fontSize: 13, color: AppColors.body),
            ),
            const SizedBox(height: 16),
            const Text(
              'Doctor Override Mandate:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navy),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _reasonController,
              onChanged: (val) {
                setState(() {
                  _canOverride = val.trim().length >= 5;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Enter clinical justification for overriding allergy warning...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel Prescribing', style: TextStyle(color: AppColors.muted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _canOverride ? AppColors.riskHigh : Colors.grey,
          ),
          onPressed: _canOverride
              ? () {
                  widget.onOverrideApproved(_reasonController.text.trim());
                  Navigator.pop(context, true);
                }
              : null,
          child: const Text('Explicit Clinical Override', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
