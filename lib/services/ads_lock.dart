import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdWaitDialog extends StatefulWidget {
  final VoidCallback onComplete;
  const AdWaitDialog({super.key, required this.onComplete});

  @override
  State<AdWaitDialog> createState() => _AdWaitDialogState();
}

class _AdWaitDialogState extends State<AdWaitDialog> {
  late Timer _timer;
  late DateTime _startTime;
  int _secondsRemaining = 10;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();

    // Timer checks every 500ms to be accurate even if app is backgrounded
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      final elapsed = DateTime.now().difference(_startTime).inSeconds;
      final remaining = 10 - elapsed;

      if (remaining <= 0) {
        // Time is up!
        _timer.cancel();
        if (mounted) {
          Navigator.pop(context); // Close dialog
          widget.onComplete(); // Award points
        }
      } else {
        // Update UI
        if (mounted && remaining != _secondsRemaining) {
          setState(() {
            _secondsRemaining = remaining;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Ensures timer stops if user Cancels/Leaves
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Disable back button
      child: Center(
        child: Container(
          padding: EdgeInsets.all(20.w),
          margin: EdgeInsets.symmetric(horizontal: 24.w),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.amber),
              SizedBox(height: 16.h),
              Text(
                "Verifying Support...",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "$_secondsRemaining seconds remaining",
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 16.h),
              // Cancel Button - Allows them to leave, but they get NO points
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
