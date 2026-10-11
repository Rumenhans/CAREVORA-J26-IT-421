import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import 'common/app_text_field.dart';
import 'common/gradient_button.dart';

class SsoDialog extends StatefulWidget {
  const SsoDialog({super.key});

  @override
  State<SsoDialog> createState() => _SsoDialogState();
}

class _SsoDialogState extends State<SsoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _domainController = TextEditingController();
  bool _isRedirecting = false;

  @override
  void dispose() {
    _domainController.dispose();
    super.dispose();
  }

  Future<void> _handleSso() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isRedirecting = true);
    await Future.delayed(const Duration(milliseconds: 900));

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Redirecting to SSO Identity Provider for ${_domainController.text.trim()}...',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(28),
        constraints: const BoxConstraints(maxWidth: 440),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.shield,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Enterprise Single Sign-On (SSO)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sign in with your organization domain (Okta, Azure AD, or Google Workspace).',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.body,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _domainController,
                label: 'Care Home Domain',
                hintText: 'sunshine-care.com',
                leadingIcon: LucideIcons.globe,
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your organization domain.';
                  }
                  if (!value.contains('.')) {
                    return 'Please enter a valid domain (e.g. carehome.com).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              GradientButton(
                isLoading: _isRedirecting,
                loadingLabel: 'Verifying Domain...',
                onPressed: _handleSso,
                child: const Text(
                  'Continue with SSO',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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
