import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
const kDarkGreen = Color(0xFF004643);

class AddPlant extends StatefulWidget {
  const AddPlant({super.key});

  @override
  State<AddPlant> createState() => _AddPlantState();
}

class _AddPlantState extends State<AddPlant> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  String? _plantType;
  String? _soilType;
  XFile? _pickedImage;
  bool _saving = false;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _chooseImage() async {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Upload Photo'),
              onTap: () async {
                Navigator.pop(ctx);
                final img = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                );
                if (img != null) setState(() => _pickedImage = img);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(ctx);
                final img = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 85,
                );
                if (img != null) setState(() => _pickedImage = img);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _uploadToCloudinary(XFile file) async {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
    final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'];
    if (cloudName == null || uploadPreset == null) {
      throw Exception('Cloudinary env vars missing.');
    }

    final cloudinary = CloudinaryPublic(cloudName, uploadPreset, cache: false);
    final response = await cloudinary.uploadFile(
      CloudinaryFile.fromFile(
        file.path,
        resourceType: CloudinaryResourceType.Image,
        folder: 'garden/plants',
      ),
    );
    return response.secureUrl;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a photo.')),
      );
      return;
    }

    // Get current user ID
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to add plants.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      // 1) Upload image to Cloudinary
      final imageUrl = await _uploadToCloudinary(_pickedImage!);

      // 2) Save doc to Firestore with userId
      await FirebaseFirestore.instance.collection('gardenPlants').add({
        'plantName': _nameCtrl.text.trim(),
        'plantType': _plantType,
        'soilType': _soilType,
        'imageUrl': imageUrl,
        'userId': currentUser.uid, // Add user ID
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context); // close dialog on success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plant added.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // close
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _saving ? null : () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 6),

                // preview + hint
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _pickedImage == null
                        ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_upload_outlined,
                              size: 48, color: kDarkGreen.withOpacity(0.9)),
                          const SizedBox(height: 6),
                          const Text(
                            'Supported formats: JPEG, PNG',
                            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    )
                        : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        // ignore: deprecated_member_use
                        File(_pickedImage!.path),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Choose / change photo
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _chooseImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kDarkGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: Text(_pickedImage == null ? 'Upload / Take Photo' : 'Change Photo'),
                  ),
                ),
                const SizedBox(height: 14),

                // Name of Plant
                _label('Name of Plant'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(hintText: 'Enter name'),
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a plant name' : null,
                ),
                const SizedBox(height: 14),

                // Type
                _label('Type'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _plantType,
                  decoration: const InputDecoration(),
                  items: const [
                    DropdownMenuItem(value: 'Vine', child: Text('Vine')),
                    DropdownMenuItem(value: 'Leaf', child: Text('Leaf')),
                    DropdownMenuItem(value: 'Root', child: Text('Root')),
                    DropdownMenuItem(value: 'Fruit', child: Text('Fruit')),
                  ],
                  onChanged: _saving ? null : (v) => setState(() => _plantType = v),
                  validator: (v) => v == null ? 'Select a type' : null,
                  hint: const Text('Select Option'),
                ),
                const SizedBox(height: 14),

                // Soil Type
                _label('Soil Type'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _soilType,
                  decoration: const InputDecoration(),
                  items: const [
                    DropdownMenuItem(value: 'Loam', child: Text('Loam')),
                    DropdownMenuItem(value: 'Clay', child: Text('Clay')),
                    DropdownMenuItem(value: 'Sandy', child: Text('Sandy')),
                    DropdownMenuItem(value: 'Silty', child: Text('Silty')),
                  ],
                  onChanged: _saving ? null : (v) => setState(() => _soilType = v),
                  validator: (v) => v == null ? 'Select a soil type' : null,
                  hint: const Text('Select Option'),
                ),
                const SizedBox(height: 18),

                // Submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kDarkGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size.fromHeight(46),
                    ),
                    child: _saving
                        ? const SizedBox(
                        height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Add Plant'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _label(String t) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      t,
      style: const TextStyle(
        color: kDarkGreen,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    ),
  );
}