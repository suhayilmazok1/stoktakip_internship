import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SnackBarUtils {
  static void showTopSnackBar(BuildContext context, String message, {bool isError = false, IconData? icon}) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: _TopToastWidget(
            message: message,
            isError: isError,
            icon: icon,
            onDismissed: () {
              overlayEntry.remove();
            },
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);
  }
}

class _TopToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final IconData? icon;
  final VoidCallback onDismissed;

  const _TopToastWidget({
    required this.message,
    required this.isError,
    this.icon,
    required this.onDismissed,
  });

  @override
  State<_TopToastWidget> createState() => _TopToastWidgetState();
}

class _TopToastWidgetState extends State<_TopToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _slide = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // Otomatik kapanma süresi
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse().then((value) {
          widget.onDismissed();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: widget.isError ? AppTheme.accentPink : AppTheme.successGreen,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                widget.icon ?? (widget.isError ? Icons.error_outline : Icons.check_circle_outline),
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
