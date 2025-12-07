import 'package:anime_verse/widgets/app_scaffold.dart';
import 'package:anime_verse/widgets/profile_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/auth_provider.dart';
import '../utils/validators.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  /// Show dialog untuk change password dengan re-authentication
  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user == null) return;

    // Check if user signed in with email/password
    final signInMethods = user.providerData.map((e) => e.providerId).toList();
    final isEmailPasswordUser = signInMethods.contains('password');

    if (!isEmailPasswordUser) {
      // Show info dialog for Google users
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Password Management'),
            content: const Text(
              'You signed in with Google. Password management is handled by your Google account. '
                  'Please visit your Google Account settings to change your password.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Controllers for form fields
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Show dialog
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Current Password
                TextFormField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Current password is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // New Password
                TextFormField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: 16),

                // Confirm New Password
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    return Validators.validatePasswordConfirmation(
                      newPasswordController.text,
                      value,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );

    // Process password change if confirmed
    if (result == true && context.mounted) {
      // Use separate BuildContext for loading dialog to avoid navigation issues
      BuildContext? loadingDialogContext;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          loadingDialogContext = dialogContext;
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      try {
        // Step 1: Re-authenticate with current password
        final reauthSuccess = await authProvider.reauthenticateWithEmail(
          email: user.email!,
          password: currentPasswordController.text,
        );

        // Close loading dialog
        if (loadingDialogContext != null && loadingDialogContext!.mounted) {
          Navigator.of(loadingDialogContext!).pop();
        }

        if (!reauthSuccess) {
          // Show error message for re-authentication failure
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  authProvider.errorMessage ?? 'Current password is incorrect',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return; // Stop execution
        }

        // Step 2: Update password
        final updateSuccess = await authProvider.updatePassword(
          newPasswordController.text,
        );

        // Show result message
        if (context.mounted) {
          if (updateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Password changed successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  authProvider.errorMessage ?? 'Failed to change password',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        // Ensure loading dialog is closed on any error
        if (loadingDialogContext != null && loadingDialogContext!.mounted) {
          Navigator.of(loadingDialogContext!).pop();
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An error occurred: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    // Cleanup controllers
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return AppScaffold(
      appBar: AppBar(
        title: Text(
          "Profile",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: screenWidth * 0.06,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.02),

            // Profile Header Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(screenWidth * 0.06),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(screenWidth * 0.04),
              ),
              child: Column(
                children: [
                  // Profile Picture
                  Container(
                    width: screenWidth * 0.25,
                    height: screenWidth * 0.25,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 3,
                      ),
                    ),
                    child: ClipOval(
                      child: user?.photoURL != null
                          ? Image.network(
                        user!.photoURL!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey.withValues(alpha: 0.3),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.withValues(alpha: 0.3),
                            child: Icon(
                              Icons.person,
                              size: screenWidth * 0.12,
                              color: Colors.white70,
                            ),
                          );
                        },
                      )
                          : Container(
                        color: Colors.grey.withValues(alpha: 0.3),
                        child: Icon(
                          Icons.person,
                          size: screenWidth * 0.12,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  // Email
                  Text(
                    user?.email ?? 'No email',
                    style: TextStyle(
                      fontSize: screenWidth * 0.038,
                      color: Colors.white70,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.015),

                  // Member since
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.008,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(screenWidth * 0.05),
                    ),
                    child: Text(
                      user?.metadata.creationTime != null
                          ? 'Member since ${_formatDate(user!.metadata.creationTime!)}'
                          : 'Member since recently',
                      style: TextStyle(
                        fontSize: screenWidth * 0.032,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: screenHeight * 0.03),

            // Account Settings Section Title
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Account Settings',
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.015),

            // Change Username Button
            ProfileButton(
              icon: Icons.person_outline,
              title: 'Change Username',
              subtitle: 'Update your display name',
              onTap: () {
                // TODO: [PRAKTIKUM EXERCISE] Implement Change Username Feature
                //
                // CONTEXT:
                // - Current sign-up flow doesn't collect displayName/username
                // - Email users: displayName = null (no input during registration)
                // - Google users: displayName = auto from Google account
                //
                // WHAT TO DO:
                // 1. Create _showChangeNameDialog() method (similar to _showChangePasswordDialog above)
                // 2. Show dialog with TextField for new display name
                // 3. Validate using Validators.validateName() [ALREADY EXISTS]
                // 4. Call authProvider.updateDisplayName(newName) [ALREADY EXISTS]
                // 5. Show success/error feedback with SnackBar
                //
                // OPTIONAL ENHANCEMENT:
                // - Modify SignUpScreen to collect displayName during registration
                // - Add TextField with _displayNameController
                // - Pass displayName to authProvider.signUpWithEmail()
                //
                // HINTS:
                // - See _showChangePasswordDialog() above for dialog pattern
                // - AuthService.updateDisplayName() is already implemented
                // - Validators.validateName() validates 2-50 characters
                //
                // DIFFICULTY: ⭐⭐☆☆☆ (Beginner-friendly)
                // TIME ESTIMATE: 30-45 minutes
              },
            ),

            SizedBox(height: screenHeight * 0.01),

            // Change Password Button
            ProfileButton(
              icon: Icons.lock_outline,
              title: 'Change Password',
              subtitle: 'Update your account password',
              onTap: () => _showChangePasswordDialog(context),
            ),

            SizedBox(height: screenHeight * 0.03),

            // App Information Section Title
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'App Information',
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.015),

            // About Button
            ProfileButton(
              icon: Icons.info_outline,
              title: 'About AnimeVerse',
              subtitle: 'Version 1.0.0',
              onTap: () {
                // TODO: Implement about app functionality
              },
            ),

            SizedBox(height: screenHeight * 0.04),

            // Logout Button
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Show confirmation dialog
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Apakah Anda yakin ingin logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text(
                            'Logout',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (shouldLogout == true && context.mounted) {
                    // Call signOut from AuthProvider
                    final authProvider = context.read<AuthProvider>();
                    final success = await authProvider.signOut();

                    if (!success && context.mounted) {
                      // Show error if logout failed
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            authProvider.errorMessage ?? 'Logout gagal',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    // No need to navigate - router will auto-redirect after auth state changes
                  }
                },
                icon: Icon(
                  Icons.logout,
                  size: screenWidth * 0.05,
                ),
                label: Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.8),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.018,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.04),
                  ),
                  elevation: 5,
                ),
              ),
            ),

            SizedBox(height: screenHeight * 0.1),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}