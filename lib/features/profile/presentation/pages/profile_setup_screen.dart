import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:connect/core/utils/responsive_extension.dart';
import 'package:connect/core/presentation/widgets/clean_background.dart';
import '../../../../core/presentation/widgets/custom_text_field.dart';

import 'package:connect/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:connect/features/profile/presentation/bloc/profile_event.dart';
import 'package:connect/features/profile/presentation/bloc/profile_state.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  File? _selectedImage;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  // Function to pick an image from the device gallery
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  // Function to validate and submit the profile form
  void _submitProfile() {
    // Dismiss the keyboard
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      // Dispatch the setup event to the BLoC
      context.read<ProfileBloc>().add(
        ProfileSetupSubmitted(
          name: _nameController.text.trim(),
          username: _usernameController.text.trim(), // Required field
          profilePic: _selectedImage, // Can be null if the user didn't pick an image
          fcmDeviceToken: null, // TODO: Implement FCM token retrieval later
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CleanBackground(
        // Listen to state changes and rebuild UI accordingly
        child: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            // Show a floating SnackBar on error (e.g., Username already taken)
            if (state is ProfileError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
            // Navigate to the next screen upon successful profile setup
            else if (state is ProfileSetupSuccess) {
              context.go('/home'); // Update this with your actual home route
            }
          },
          builder: (context, state) {
            // Check if the current state is loading
            final bool isLoading = state is ProfileLoading;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: context.widthPct(0.08)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [

                      // --- Header Section ---
                      Text(
                        'Complete Profile',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: context.isMobile ? 28 : 36,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: context.heightPct(0.01)),
                      Text(
                        'Add a photo and your details to get started.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: context.isMobile ? 14 : 16,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      SizedBox(height: context.heightPct(0.05)),

                      // --- Profile Picture Picker Section ---
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: context.isMobile ? 60 : 80,
                              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              backgroundImage: _selectedImage != null
                                  ? FileImage(_selectedImage!)
                                  : null,
                              child: _selectedImage == null
                                  ? Icon(
                                Icons.person_outline,
                                size: context.isMobile ? 60 : 80,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                // Disable picking an image while loading
                                onTap: isLoading ? null : _pickImage,
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Theme.of(context).colorScheme.primary,
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

                      // --- Input Section ---
                      CustomTextField(
                        controller: _nameController,
                        labelText: 'Full Name',
                        hintText: 'John Doe',
                        prefixIcon: Icons.person,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          if (value.trim().length < 2) {
                            return 'Name is too short';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: context.heightPct(0.025)),

                      CustomTextField(
                        controller: _usernameController,
                        labelText: 'Username',
                        hintText: 'johndoe99',
                        prefixIcon: Icons.alternate_email,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submitProfile(),
                        validator: (value) {
                          // Username is now strictly required
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a username';
                          }
                          if (value.length < 3) {
                            return 'Username must be at least 3 characters';
                          }
                          if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                            return 'Only letters, numbers, and underscores allowed';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: context.heightPct(0.05)),

                      // --- Button Section ---
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          // Disable the button to prevent multiple submissions while loading
                          onPressed: isLoading ? null : _submitProfile,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                              : const Text(
                            'Save & Continue',
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