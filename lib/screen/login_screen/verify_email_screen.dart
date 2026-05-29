import 'dart:async';

import 'package:e_commerce_flutter/utility/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../utility/app_color.dart';
import '../../widget/page_wrapper.dart';
import 'login_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;
  int _resendSeconds = 60;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
        return;
      }
      setState(() => _resendSeconds -= 1);
    });
  }

  String _maskedEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return '${name[0]}***@$domain';
    return '${name[0]}***${name[name.length - 1]}@$domain';
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      _showError('Enter the 6-digit code from your email.');
      return;
    }

    setState(() => _isVerifying = true);
    final error = await context.userProvider.verifyEmail(
      email: widget.email,
      code: code,
    );
    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (error != null) {
      _showError(error);
      return;
    }

    Get.offAll(() => const LoginScreen());
  }

  Future<void> _resend() async {
    setState(() => _isResending = true);
    final error =
        await context.userProvider.resendVerificationCode(widget.email);
    if (!mounted) return;
    setState(() => _isResending = false);

    if (error != null) {
      _showError(error);
      return;
    }
    _startResendCountdown();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  Future<void> _signOut() async {
    await context.userProvider.logOutUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: PageWrapper(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: 'Back to login',
                    onPressed: _signOut,
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),
                const SizedBox(height: 24),
                const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 64,
                  color: AppColor.darkOrange,
                ),
                const SizedBox(height: 24),
                Text(
                  'Verify your email',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 24,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'We sent a 6-digit code to ${_maskedEmail(widget.email)}.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _codeController,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  maxLength: 6,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '000000',
                    filled: true,
                    fillColor: AppColor.lightGrey.withValues(alpha: 0.45),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColor.darkOrange,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _verify(),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isVerifying ? null : _verify,
                  child: _isVerifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Verify email'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed:
                      (_isResending || _resendSeconds > 0) ? null : _resend,
                  child: Text(
                    _isResending
                        ? 'Sending code...'
                        : _resendSeconds > 0
                            ? 'Send a new code in ${_resendSeconds}s'
                            : 'Send a new code',
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _signOut,
                  child: const Text('Use a different account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
