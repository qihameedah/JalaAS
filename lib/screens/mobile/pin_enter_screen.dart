import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import 'login_screen.dart';

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
  String _enteredPin = '';
  bool _isLoading = false;
  int _attemptCount = 0;
  static const int _maxAttempts = 3;

  // Key to force rebuild of PinCodeTextField when needed
  Key _pinFieldKey = UniqueKey();

  void _onPinChanged(String value) {
    if (!mounted) return;

    setState(() {
      _enteredPin = value;
    });

    if (value.length == AppConstants.pinLength) {
      _verifyPin();
    }
  }

  void _clearPin() {
    if (!mounted) return;

    setState(() {
      _enteredPin = '';
      _pinFieldKey = UniqueKey(); // Force rebuild to clear the field
    });
  }

  Future<void> _verifyPin() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final storedPin = await Helpers.getPinCode();

      if (!mounted) return;

      if (storedPin == _enteredPin) {
        await Helpers.updateLastActiveTime();

        if (!mounted) return;

        Helpers.showSnackBar(context, 'تم التحقق من رمز PIN بنجاح');

        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        widget.onPinVerified();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        _attemptCount++;

        if (!mounted) return;

        if (_attemptCount >= _maxAttempts) {
          Helpers.showSnackBar(
            context,
            'تم تجاوز عدد المحاولات المسموح. يرجى إعادة تشغيل التطبيق.',
            isError: true,
          );
        } else {
          Helpers.showSnackBar(
            context,
            'رمز PIN غير صحيح. المحاولات المتبقية: ${_maxAttempts - _attemptCount}',
            isError: true,
          );

          // Clear the PIN by rebuilding the widget
          _clearPin();
        }
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'خطأ في التحقق من رمز PIN. حاول مرة أخرى.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: PinCodeTextField(
                        key: _pinFieldKey,
                        appContext: context,
                        length: AppConstants.pinLength,
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
          ),
        ),
      ),
    );
  }
}