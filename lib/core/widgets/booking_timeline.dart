import 'package:flutter/material.dart';

class BookingTimeline extends StatelessWidget {
  final String status; // pending, confirmed, ongoing, completed, cancelled

  const BookingTimeline({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    int currentStep = _getStepForStatus(status);
    bool isCancelled = status == 'cancelled';

    return Row(
      children: [
        _buildStep(context, 'قيد الانتظار', 0, currentStep, isCancelled),
        _buildLine(0, currentStep, isCancelled),
        _buildStep(context, 'مؤكد', 1, currentStep, isCancelled),
        _buildLine(1, currentStep, isCancelled),
        _buildStep(context, 'جاري الرحلة', 2, currentStep, isCancelled),
        _buildLine(2, currentStep, isCancelled),
        _buildStep(context, 'مكتمل', 3, currentStep, isCancelled),
      ],
    );
  }

  int _getStepForStatus(String status) {
    switch (status) {
      case 'pending':
        return 0;
      case 'confirmed':
        return 1;
      case 'ongoing':
        return 2;
      case 'completed':
        return 3;
      case 'cancelled':
        return -1; // Handled separately
      default:
        return 0;
    }
  }

  Widget _buildStep(
    BuildContext context,
    String label,
    int stepIndex,
    int currentStep,
    bool isCancelled,
  ) {
    bool isCompleted = stepIndex <= currentStep;
    bool isActive = stepIndex == currentStep;

    Color color;
    if (isCancelled && isActive) {
      color = Colors.red;
    } else if (isCompleted) {
      color = const Color(0xFF0B1F3A);
    } else {
      color = Colors.grey.shade300;
    }

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isCompleted ? color : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isCompleted ? color : Colors.grey.shade400,
                width: 2,
              ),
            ),
            child: isCompleted
                ? Icon(
                    isCancelled && isActive ? Icons.close : Icons.check,
                    size: 14,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            isCancelled && isActive ? 'ملغى' : label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? color : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLine(int stepIndex, int currentStep, bool isCancelled) {
    bool isCompleted = stepIndex < currentStep;
    Color color = isCompleted && !isCancelled
        ? const Color(0xFF0B1F3A)
        : Colors.grey.shade300;

    return Expanded(
      child: Container(
        height: 2,
        color: color,
        margin: const EdgeInsets.only(bottom: 24), // Align with circles
      ),
    );
  }
}
