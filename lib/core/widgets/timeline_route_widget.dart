import 'package:flutter/material.dart';

class TimelineRouteWidget extends StatelessWidget {
  final String origin;
  final String destination;
  final List<String> stops;

  const TimelineRouteWidget({
    super.key,
    required this.origin,
    required this.destination,
    this.stops = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTimelineItem(context, origin, true, false),
        for (var stop in stops) _buildTimelineItem(context, stop, false, false),
        _buildTimelineItem(context, destination, false, true),
      ],
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    String title,
    bool isFirst,
    bool isLast,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isFirst
                      ? const Color(0xFFF5A623)
                      : (isLast ? Colors.green : Colors.grey),
                  width: 3,
                ),
                color: Colors.white,
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 30, color: Colors.grey.shade300),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 0, bottom: 20),
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: isFirst || isLast ? 14 : 12,
                fontWeight: isFirst || isLast
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
