// lib/screens/mobile/no_internet_screen.dart
import 'package:flutter/material.dart';
import '../../utils/helpers.dart';

class NoInternetScreen extends StatefulWidget {
  final VoidCallback onRetry;

  const NoInternetScreen({
    super.key,
    required this.onRetry,
  });

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen> {
  bool _isRetrying = false;

  Future<void> _retry() async {
    setState(() {
      _isRetrying = true;
    });

    final hasInternet = await Helpers.hasInternetConnection();

    setState(() {
      _isRetrying = false;
    });

    if (hasInternet) {
      widget.onRetry();
    } else {
      Helpers.showSnackBar(
        context,
        'لا يوجد اتصال بالإنترنت. تأكد من اتصالك وحاول مرة أخرى.',
        isError: true,
      );
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
              // No Internet Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.wifi_off,
                  size: 64,
                  color: Colors.red[400],
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'لا يوجد اتصال بالإنترنت',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[600],
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                'يتطلب هذا التطبيق اتصالاً بالإنترنت للعمل. تأكد من اتصالك بالإنترنت وحاول مرة أخرى.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isRetrying ? null : _retry,
                  icon: _isRetrying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.refresh,
                          color: Colors.white,
                        ),
                  label:
                      Text(_isRetrying ? 'جاري المحاولة...' : 'إعادة المحاولة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Connection tips
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info,
                          color: Colors.blue[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'نصائح للاتصال:',
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• تأكد من تشغيل الواي فاي أو البيانات\n'
                      '• تحقق من قوة الإشارة\n'
                      '• جرب الانتقال إلى مكان آخر\n'
                      '• أعد تشغيل جهازك إذا لزم الأمر',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 14,
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
