import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:connect/core/utils/responsive_extension.dart';
import 'package:connect/core/presentation/widgets/clean_background.dart';
import '../../../../core/presentation/widgets/custom_text_field.dart';

import 'package:connect/features/profile/domain/entities/user_profile_entity.dart';
import 'package:connect/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:connect/features/profile/presentation/bloc/profile_event.dart';
import 'package:connect/features/profile/presentation/bloc/profile_state.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfileEntity currentUser;

  const EditProfileScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _aboutController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUser.name);
    _usernameController = TextEditingController(text: widget.currentUser.username ?? '');
    _aboutController = TextEditingController(text: "Hey there! I am using Connect.");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _submitUpdate() {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      context.read<ProfileBloc>().add(
        UpdateProfileRequested(
          name: _nameController.text.trim(),
          // Username is excluded since it shouldn't be updated
          profilePic: _selectedImage,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.w700,color: colorScheme.onSurface,),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: colorScheme.onSurface,
      ),),
      body: CleanBackground(
        child: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfileError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            else if (state is ProfileUpdateSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile updated successfully!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );

              // Request fresh profile data before navigating back
              context.read<ProfileBloc>().add(GetMyProfileRequested());
              Navigator.of(context).pop();
            }
          },
          builder: (context, state) {
            final bool isUpdating = state is ProfileUpdating;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: context.widthPct(0.08)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: context.heightPct(0.12)),

                      // --- Profile Picture Section ---
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.primary.withOpacity(0.3),
                                  width: 3.0,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: context.isMobile ? 65 : 85, // Slightly larger
                                backgroundColor: colorScheme.surfaceContainerHighest,
                                // Fixed Image Loading Issue
                                backgroundImage: _selectedImage != null
                                    ? FileImage(_selectedImage!) as ImageProvider
                                    : (widget.currentUser.profilePicUrl != null && widget.currentUser.profilePicUrl!.isNotEmpty)
                                    ? NetworkImage(widget.currentUser.profilePicUrl!)
                                    : null,
                                child: _selectedImage == null && (widget.currentUser.profilePicUrl == null || widget.currentUser.profilePicUrl!.isEmpty)
                                    ? Icon(
                                  Icons.person_outline,
                                  size: context.isMobile ? 65 : 85,
                                  color: colorScheme.onSurfaceVariant,
                                )
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: isUpdating ? null : _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: colorScheme.surface, width: 3),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: context.heightPct(0.05)),

                      // --- Account Info Section Title ---
                      Text(
                        'Public Information',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- Input Section ---
                      CustomTextField(
                        controller: _nameController,
                        labelText: 'Full Name',
                        hintText: 'e.g. John Doe',
                        prefixIcon: Icons.person_outline,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: context.heightPct(0.025)),

                      // About / Bio Field (To fill the screen space)
                      CustomTextField(
                        controller: _aboutController,
                        labelText: 'About',
                        hintText: 'Hey there! I am using Connect.',
                        prefixIcon: Icons.info_outline,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,

                      ),

                      SizedBox(height: context.heightPct(0.04)),

                      const Divider(),

                      SizedBox(height: context.heightPct(0.02)),

                      // Disabled Username Field
                      TextFormField(
                        controller: _usernameController,
                        enabled: false, // Disables the field
                        style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
                        decoration: InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.alternate_email, color: colorScheme.onSurface.withOpacity(0.5)),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          helperText: "You cannot change your username once created.",
                        ),
                      ),

                      SizedBox(height: context.heightPct(0.06)),

                      // --- Save Button Section ---
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isUpdating ? null : _submitUpdate,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: isUpdating
                              ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                              : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}