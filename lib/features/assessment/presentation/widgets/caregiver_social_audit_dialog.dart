import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/carevora_models.dart';
import '../../application/social_audit_service.dart';

class CaregiverSocialAuditDialog extends StatefulWidget {
  final Resident resident;
  final int backendResidentId;
  final String caregiverName;
  final String? authToken;
  final Function(SocialAuditRecord record) onAuditSaved;

  const CaregiverSocialAuditDialog({
    super.key,
    required this.resident,
    required this.backendResidentId,
    required this.caregiverName,
    this.authToken,
    required this.onAuditSaved,
  });

  @override
  State<CaregiverSocialAuditDialog> createState() => _CaregiverSocialAuditDialogState();
}

class _CaregiverSocialAuditDialogState extends State<CaregiverSocialAuditDialog> {
  final _formKey = GlobalKey<FormState>();

  // Form State
  final int _reportingPeriodDays = 7;

  // Domain 1: Family/External
  int _familyVisits = 1;
  int _familyCalls = 2;
  bool _externalContactUnknown = false;

  // Domain 2: Peer Interaction
  PeerInteractionFrequency _peerFrequency = PeerInteractionFrequency.often;

  // Domain 3: Group Activity
  int _activitiesAvailable = 4;
  int _activitiesAttended = 3;
  ActivityParticipationMode _participationMode = ActivityParticipationMode.activeEngagement;
  bool _healthMobilityBarriers = false;

  // Domain 4: Time Spent Alone
  double _hoursAlone = 4.0;
  SolitudeContext _aloneContext = SolitudeContext.chosenSolitude;

  // Domain 5: Notes
  final TextEditingController _notesController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirmAndSubmit() async {
    if (_isSubmitting) return;

    if (!_externalContactUnknown && _activitiesAttended > _activitiesAvailable) {
      setState(() {
        _errorMessage = 'Activities attended cannot exceed total activities available.';
      });
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (confirmCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(LucideIcons.shieldCheck, color: AppColors.primary, size: 22),
            SizedBox(width: 10),
            Text('Confirm Audit Submission', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Record this 7-day social audit for ${widget.resident.name}?\n\n'
          'The verified observations will be saved to the database and will update the resident\'s social wellness profile.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmCtx, false),
            child: const Text('Review Again'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(confirmCtx, true),
            child: const Text('Confirm & Save'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final formData = SocialAuditFormData(
        reportingPeriodDays: _reportingPeriodDays,
        familyInPersonVisits: _externalContactUnknown ? null : _familyVisits,
        familyPhoneVideoContacts: _externalContactUnknown ? null : _familyCalls,
        externalContactUnknown: _externalContactUnknown,
        peerInteractionLevel: _peerFrequency,
        activitiesAvailable: _activitiesAvailable,
        activitiesAttended: _activitiesAttended,
        activityParticipationLevel: _participationMode,
        healthMobilityBarriers: _healthMobilityBarriers,
        estimatedHoursAlonePerDay: _hoursAlone,
        aloneTimeContext: _aloneContext,
        caregiverNotes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      final record = await SocialAuditService.submitSocialAudit(
        residentId: widget.backendResidentId,
        formData: formData,
        token: widget.authToken,
      );

      if (mounted) {
        widget.onAuditSaved(record);
        Navigator.pop(context, record);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.lavenderBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.usersRound, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Caregiver Social Audit',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy),
                          ),
                          Text(
                            'Observational Assessment — 7-Day Reporting Window',
                            style: TextStyle(fontSize: 12, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Resident & Caregiver Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.userCheck, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Resident: ${widget.resident.name} (Room ${widget.resident.roomNo})',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.navy),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Staff: ${widget.caregiverName}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEF4444)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.alertCircle, color: Color(0xFFB91C1C), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Scrollable Form Body
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section 1: Family & External Contacts
                        _buildSectionHeader('1. Family & External Contacts (Previous 7 Days)', LucideIcons.phoneCall),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                title: const Text(
                                  'Unknown / Not Recorded (Do not assume 0)',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                value: _externalContactUnknown,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  setState(() {
                                    _externalContactUnknown = val ?? false;
                                  });
                                },
                              ),
                              if (!_externalContactUnknown) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStepperField(
                                        label: 'In-person visits',
                                        sublabel: 'Friends & family visits',
                                        value: _familyVisits,
                                        onChanged: (v) => setState(() => _familyVisits = v),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: _buildStepperField(
                                        label: 'Phone / video calls',
                                        sublabel: 'Incoming & outgoing calls',
                                        value: _familyCalls,
                                        onChanged: (v) => setState(() => _familyCalls = v),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Section 2: Observed Peer Interaction
                        _buildSectionHeader('2. Observed Peer Interaction with Residents', LucideIcons.users),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Frequency of voluntary conversation or socializing in shared areas:',
                                style: TextStyle(fontSize: 12, color: AppColors.muted),
                              ),
                              const SizedBox(height: 8),
                              ...PeerInteractionFrequency.values.map((lvl) {
                                return RadioListTile<PeerInteractionFrequency>(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(lvl.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                  value: lvl,
                                  // ignore: deprecated_member_use
                                  groupValue: _peerFrequency,
                                  activeColor: AppColors.primary,
                                  // ignore: deprecated_member_use
                                  onChanged: (v) {
                                    if (v != null) setState(() => _peerFrequency = v);
                                  },
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Section 3: Group Activity Participation
                        _buildSectionHeader('3. Group Activity Participation', LucideIcons.sparkles),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStepperField(
                                      label: 'Activities Available',
                                      sublabel: 'Scheduled in home',
                                      value: _activitiesAvailable,
                                      onChanged: (v) => setState(() => _activitiesAvailable = v),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: _buildStepperField(
                                      label: 'Activities Attended',
                                      sublabel: 'Resident joined',
                                      value: _activitiesAttended,
                                      onChanged: (v) => setState(() => _activitiesAttended = v),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text('Observed Engagement Style:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<ActivityParticipationMode>(
                                initialValue: _participationMode,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                items: ActivityParticipationMode.values.map((mode) {
                                  return DropdownMenuItem(
                                    value: mode,
                                    child: Text(mode.label, style: const TextStyle(fontSize: 12)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _participationMode = val);
                                },
                              ),
                              const SizedBox(height: 8),
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                title: const Text(
                                  'Health / mobility barrier prevented attendance',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9A3412)),
                                ),
                                subtitle: const Text(
                                  'Illness, sensory, or mobility barriers are not penalized as voluntary isolation.',
                                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                                ),
                                value: _healthMobilityBarriers,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  setState(() => _healthMobilityBarriers = val ?? false);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Section 4: Time Spent Alone (Solitude Context)
                        _buildSectionHeader('4. Estimated Time Alone & Solitude Context', LucideIcons.clock),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Estimated hours alone per day:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  Text('${_hoursAlone.toStringAsFixed(1)} hrs/day', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                ],
                              ),
                              Slider(
                                value: _hoursAlone,
                                min: 0.0,
                                max: 24.0,
                                divisions: 48,
                                activeColor: AppColors.primary,
                                onChanged: (v) => setState(() => _hoursAlone = v),
                              ),
                              const SizedBox(height: 6),
                              const Text('Solitude Quality (Chosen vs Involuntary):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<SolitudeContext>(
                                initialValue: _aloneContext,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                items: SolitudeContext.values.map((ctx) {
                                  return DropdownMenuItem(
                                    value: ctx,
                                    child: Text(ctx.label, style: const TextStyle(fontSize: 12)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _aloneContext = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Section 5: Factual Caregiver Notes
                        _buildSectionHeader('5. Additional Factual Observations (Optional)', LucideIcons.fileText),
                        TextField(
                          controller: _notesController,
                          maxLines: 3,
                          maxLength: 1000,
                          decoration: InputDecoration(
                            hintText: 'Enter objective behavioral observations (e.g. visited garden with peer, declined crafts due to mild eye fatigue)...',
                            hintStyle: const TextStyle(fontSize: 12, color: AppColors.muted),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Non-diagnostic disclaimer
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: const [
                              Icon(LucideIcons.info, size: 16, color: AppColors.muted),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Caregiver Social Audit records observable circumstances. It is not a clinical or psychiatric diagnosis.',
                                  style: TextStyle(fontSize: 11, color: AppColors.muted, fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(LucideIcons.checkCheck, size: 18),
                      label: Text(_isSubmitting ? 'Saving Audit...' : 'Save & Verify Audit'),
                      onPressed: _isSubmitting ? null : _handleConfirmAndSubmit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.navy)),
        ],
      ),
    );
  }

  Widget _buildStepperField({
    required String label,
    required String sublabel,
    required int value,
    required Function(int) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          Text(sublabel, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(LucideIcons.minusCircle, size: 20, color: AppColors.primary),
                onPressed: value > 0 ? () => onChanged(value - 1) : null,
              ),
              Text(
                '$value',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(LucideIcons.plusCircle, size: 20, color: AppColors.primary),
                onPressed: value < 50 ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
