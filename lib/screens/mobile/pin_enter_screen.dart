// lib/screens/mobile/pin_enter_screen.dart
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import 'login_screen.dart';
import 'contact_selection_screen.dart';

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
      // Use the verifyPin method from Helpers which handles hashing comparison
      final isCorrect = await Helpers.verifyPin(_enteredPin);

      if (!mounted) return;

      if (isCorrect) {
        await Helpers.updateLastActiveTime();

        if (!mounted) return;

        Helpers.showSnackBar(context, 'تم التحقق من رمز PIN بنجاح');

        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        widget.onPinVerified();

        // Check if user is logged in to determine where to navigate
        final isLoggedIn = await Helpers.isLoggedIn();

        if (!mounted) return;

        if (isLoggedIn) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ContactSelectionScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
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

// lib/screens/mobile/pin_enter_screen.dart - Updated build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundColor),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  maxWidth: 500,
                ),
                child: Center(
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Expanded(flex: 1, child: SizedBox()),

                          // App Logo
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(AppConstants.primaryColor)
                                      .withOpacity(0.1),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/logo.png',
                              height: 50,
                              width: 50,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 50,
                                  width: 50,
                                  decoration: BoxDecoration(
                                    color:
                                        const Color(AppConstants.primaryColor),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.lock_outline,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 20),

                          Text(
                            AppConstants.appName,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(AppConstants.primaryColor),
                                ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 32),

                          Text(
                            'أدخل رمز PIN',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(AppConstants.primaryColor),
                                ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 12),

                          Text(
                            'أدخل رمز PIN المكون من ${AppConstants.pinLength} أرقام للمتابعة',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[600],
                                ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 24),

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
                                fieldHeight: 50,
                                fieldWidth: 40,
                                activeFillColor: Colors.white,
                                inactiveFillColor:
                                    const Color(AppConstants.surfaceColor),
                                selectedFillColor: Colors.white,
                                activeColor:
                                    const Color(AppConstants.primaryColor),
                                inactiveColor: Colors.grey[300],
                                selectedColor:
                                    const Color(AppConstants.primaryColor),
                              ),
                              enableActiveFill: true,
                              autoFocus: true,
                              showCursor: true,
                              cursorColor:
                                  const Color(AppConstants.primaryColor),
                            ),
                          ),

                          const SizedBox(height: 24),

                          if (_isLoading)
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(AppConstants.primaryColor)),
                            ),

                          const Expanded(flex: 2, child: SizedBox()),

                          if (_attemptCount > 0)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(AppConstants.accentColor)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: const Color(AppConstants.accentColor)
                                        .withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning,
                                    color:
                                        const Color(AppConstants.accentColor),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'المحاولات المتبقية: ${_maxAttempts - _attemptCount}',
                                      style: TextStyle(
                                        color: const Color(
                                            AppConstants.accentColor),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
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
