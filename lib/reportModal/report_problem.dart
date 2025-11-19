import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const kDarkGreen = Color(0xFF004643);

Future<void> showReportProblemDialog(
    BuildContext context, {
      required String topicLabel, // e.g. "Loam Soil" / "Tomato (dry season)"
    }) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => _ReportProblemDialog(topicLabel: topicLabel),
  );
}

class _ReportProblemDialog extends StatefulWidget {
  final String topicLabel;

  const _ReportProblemDialog({super.key, required this.topicLabel});

  @override
  State<_ReportProblemDialog> createState() => _ReportProblemDialogState();
}

class _ReportProblemDialogState extends State<_ReportProblemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;

      String? reporterName;
      String? reporterEmail = user?.email;
      String? reporterUid = user?.uid;

      // Pull extra info from users collection if we have a UID
      if (reporterUid != null) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(reporterUid)
              .get();

          if (doc.exists) {
            final data = doc.data();
            reporterName = data?['fullName'] as String?;
            reporterEmail ??= data?['email'] as String?;
          }
        } catch (_) {
          // If this fails we still proceed, just without name/email.
        }
      }

      await FirebaseFirestore.instance.collection('reportedProblems').add({
        'topic': widget.topicLabel,
        'description': _controller.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),

        // extra reporter metadata
        'reporterUid': reporterUid,
        'reporterName': reporterName,
        'reporterEmail': reporterEmail,
      });

      if (!mounted) return;
      Navigator.of(context).pop(); // close dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Report sent. Thank you for helping improve GardenCity.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send report. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          // similar squeeze as your other modals
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Report a problem',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: kDarkGreen,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.topicLabel,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _controller,
                  maxLines: 5,
                  minLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    hintText:
                    'Describe what seems incorrect, missing, or unclear…',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please add a short description.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDarkGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text(
                    'Submit',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
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
