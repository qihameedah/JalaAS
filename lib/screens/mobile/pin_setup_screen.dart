// lib/screens/mobile/pin_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:jala_as/screens/mobile/login_screen.dart';
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
  String _currentPin = '';
  String _confirmPin = '';
  bool _isSettingPin = true;
  bool _isLoading = false;
  bool _isDisposed = false;

  // Keys to force rebuild of PinCodeTextField when needed
  Key _setupPinFieldKey = UniqueKey();
  Key _confirmPinFieldKey = UniqueKey();

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _onPinChanged(String value) {
    if (!mounted || _isDisposed) {
      return;
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
      return;
    }

    setState(() {
      _isSettingPin = false;
      _confirmPin = '';
      _confirmPinFieldKey = UniqueKey(); // Force rebuild to clear the field
    });
  }

  Future<void> _validateAndSavePin() async {
    if (!mounted || _isDisposed) {
      return;
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
      return;
    }

    setState(() {
      _isSettingPin = true;
      _currentPin = '';
      _confirmPin = '';
      _setupPinFieldKey = UniqueKey(); // Force rebuild to clear the field
      _confirmPinFieldKey = UniqueKey();
    });
  }

  // lib/screens/mobile/pin_setup_screen.dart - Updated build method
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
                                    Icons.lock,
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
                            _isSettingPin ? 'قم بإنشاء رمز PIN' : 'أكد رمز PIN',
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
                            _isSettingPin
                                ? 'أدخل رمز PIN مكون من ${AppConstants.pinLength} أرقام لحماية التطبيق'
                                : 'أدخل رمز PIN مرة أخرى للتأكيد',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[600],
                                ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 24),

                          // PIN Input Field
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: _isDisposed
                                ? const SizedBox()
                                : PinCodeTextField(
                                    key: _isSettingPin
                                        ? _setupPinFieldKey
                                        : _confirmPinFieldKey,
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
                                      inactiveFillColor: const Color(
                                          AppConstants.surfaceColor),
                                      selectedFillColor: Colors.white,
                                      activeColor: const Color(
                                          AppConstants.primaryColor),
                                      inactiveColor: Colors.grey[300],
                                      selectedColor: const Color(
                                          AppConstants.primaryColor),
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
                            )
                          else if (!_isSettingPin)
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _resetToStart,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      side: const BorderSide(
                                          color:
                                              Color(AppConstants.primaryColor)),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                    child: Text(
                                      'رجوع',
                                      style: TextStyle(
                                        color: const Color(
                                            AppConstants.primaryColor),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                          const Expanded(flex: 2, child: SizedBox()),

                          Text(
                            "سيتم طلب رمز PIN عند فتح التطبيق أو بعد عدم الاستخدام لمدة 5 دقائق",
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                            textAlign: TextAlign.center,
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
