// lib/screens/mobile/pin_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:jala_as/screens/mobile/mobile_login_screen.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class PinSetupScreen extends StatefulWidget {
  final VoidCallback onPinSet;

  const PinSetupScreen({
    super.key,
    required this.onPinSet,
  });

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  String _currentPin = '';
  String _confirmPin = '';
  bool _isSettingPin = true;
  bool _isLoading = false;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _onPinChanged(String value) {
    if (!mounted || _isDisposed) {
      return; // Check if widget is still mounted and not disposed
    }

    setState(() {
      if (_isSettingPin) {
        _currentPin = value;
      } else {
        _confirmPin = value;
      }
    });

    if (value.length == AppConstants.pinLength) {
      if (_isSettingPin) {
        _proceedToConfirmation();
      } else {
        _validateAndSavePin();
      }
    }
  }

  void _proceedToConfirmation() {
    if (!mounted || _isDisposed) {
      return; // Check if widget is still mounted and not disposed
    }

    setState(() {
      _isSettingPin = false;
    });

    // Clear the confirmation controller and reset confirmPin
    if (!_isDisposed) {
      _confirmPinController.clear();
    }
    _confirmPin = '';

    // Add a small delay to ensure the UI updates properly
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && !_isDisposed) {
        // Auto-focus on the confirmation field
        FocusScope.of(context).requestFocus(FocusNode());
      }
    });
  }

  Future<void> _validateAndSavePin() async {
    if (!mounted || _isDisposed) {
      return; // Check if widget is still mounted and not disposed
    }

    if (_currentPin != _confirmPin) {
      if (mounted && !_isDisposed) {
        Helpers.showSnackBar(
          context,
          'رمز PIN غير متطابق. حاول مرة أخرى.',
          isError: true,
        );
        _resetToStart();
      }
      return;
    }

    if (mounted && !_isDisposed) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      await Helpers.savePinCode(_currentPin);

      if (mounted && !_isDisposed) {
        Helpers.showSnackBar(context, 'تم حفظ رمز PIN بنجاح');

        // Wait a moment for the user to see the success message
        await Future.delayed(const Duration(seconds: 1));

        if (mounted && !_isDisposed) {
          widget.onPinSet();

          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginScreen()));
        }
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        Helpers.showSnackBar(
          context,
          'فشل في حفظ رمز PIN. حاول مرة أخرى.',
          isError: true,
        );
      }
    } finally {
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetToStart() {
    if (!mounted || _isDisposed) {
      return; // Check if widget is still mounted and not disposed
    }

    setState(() {
      _isSettingPin = true;
      _currentPin = '';
      _confirmPin = '';
    });

    // Only clear controllers if they haven't been disposed
    if (!_isDisposed) {
      _pinController.clear();
      _confirmPinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Title
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(AppConstants.primaryColor),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.lock,
                  size: 64,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 32),

              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(AppConstants.primaryColor),
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              Text(
                _isSettingPin ? 'قم بإنشاء رمز PIN' : 'أكد رمز PIN',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                _isSettingPin
                    ? 'أدخل رمز PIN مكون من ${AppConstants.pinLength} أرقام لحماية التطبيق'
                    : 'أدخل رمز PIN مرة أخرى للتأكيد',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // PIN Input Field
              Directionality(
                textDirection: TextDirection.ltr,
                child: _isDisposed
                    ? const SizedBox()
                    : // Return empty widget if disposed
                    PinCodeTextField(
                        key: ValueKey(_isSettingPin
                            ? 'setup'
                            : 'confirm'), // Add key to force rebuild
                        appContext: context,
                        length: AppConstants.pinLength,
                        controller: _isSettingPin
                            ? _pinController
                            : _confirmPinController,
                        onChanged: _onPinChanged,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        obscuringCharacter: '●',
                        animationType: AnimationType.fade,
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(8),
                          fieldHeight: 60,
                          fieldWidth: 50,
                          activeFillColor: Colors.white,
                          inactiveFillColor: Colors.grey[100],
                          selectedFillColor: Colors.white,
                          activeColor: const Color(AppConstants.primaryColor),
                          inactiveColor: Colors.grey[300],
                          selectedColor: const Color(AppConstants.primaryColor),
                        ),
                        enableActiveFill: true,
                        autoFocus: true,
                      ),
              ),

              const SizedBox(height: 32),

              if (_isLoading)
                const CircularProgressIndicator()
              else if (!_isSettingPin)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _resetToStart,
                        child: const Text('رجوع'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _confirmPin.length == AppConstants.pinLength
                            ? _validateAndSavePin
                            : null,
                        child: const Text('تأكيد'),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 48),

              Text(
                "سيتم طلب رمز PIN عند فتح التطبيق أو بعد عدم الاستخدام لمدة ${AppConstants.backgroundTimeoutMinutes} دقائق",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
