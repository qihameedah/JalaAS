// lib/screens/mobile/pin_enter_screen.dart
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class PinEnterScreen extends StatefulWidget {
  final VoidCallback onPinVerified;

  const PinEnterScreen({
    super.key,
    required this.onPinVerified,
  });

  @override
  State<PinEnterScreen> createState() => _PinEnterScreenState();
}

class _PinEnterScreenState extends State<PinEnterScreen> {
  final TextEditingController _pinController = TextEditingController();
  String _enteredPin = '';
  bool _isLoading = false;
  int _attemptCount = 0;
  static const int _maxAttempts = 3;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _pinController.dispose();
    super.dispose();
  }

  void _onPinChanged(String value) {
    if (!mounted || _isDisposed)
      return; // Check if widget is still mounted and not disposed

    setState(() {
      _enteredPin = value;
    });

    if (value.length == AppConstants.pinLength) {
      _verifyPin();
    }
  }

  Future<void> _verifyPin() async {
    if (!mounted || _isDisposed)
      return; // Check if widget is still mounted and not disposed

    setState(() {
      _isLoading = true;
    });

    try {
      final storedPin = await Helpers.getPinCode();

      if (!mounted || _isDisposed) return; // Check again after async operation

      if (storedPin == _enteredPin) {
        await Helpers.updateLastActiveTime();

        if (mounted && !_isDisposed) {
          Helpers.showSnackBar(context, 'تم التحقق من رمز PIN بنجاح');

          // Wait a moment for the user to see the success message
          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted && !_isDisposed) {
            widget.onPinVerified();
          }
        }
      } else {
        _attemptCount++;

        if (mounted && !_isDisposed) {
          if (_attemptCount >= _maxAttempts) {
            Helpers.showSnackBar(
              context,
              'تم تجاوز عدد المحاولات المسموح. يرجى إعادة تشغيل التطبيق.',
              isError: true,
            );

            // Exit the app or take appropriate action
            // In a real app, you might want to implement a lockout period
          } else {
            Helpers.showSnackBar(
              context,
              'رمز PIN غير صحيح. المحاولات المتبقية: ${_maxAttempts - _attemptCount}',
              isError: true,
            );

            // Only clear controller if not disposed
            if (!_isDisposed) {
              _pinController.clear();
            }
            setState(() {
              _enteredPin = '';
            });
          }
        }
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        Helpers.showSnackBar(
          context,
          'خطأ في التحقق من رمز PIN. حاول مرة أخرى.',
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
                  Icons.lock_outline,
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
                'أدخل رمز PIN',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                'أدخل رمز PIN المكون من ${AppConstants.pinLength} أرقام للمتابعة',
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
                        appContext: context,
                        length: AppConstants.pinLength,
                        controller: _pinController,
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

              if (_isLoading) const CircularProgressIndicator(),

              const SizedBox(height: 32),

              if (_attemptCount > 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning,
                        color: Colors.red[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'المحاولات المتبقية: ${_maxAttempts - _attemptCount}',
                          style: TextStyle(
                            color: Colors.red[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
