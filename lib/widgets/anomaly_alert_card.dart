import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/anomaly_alert_service.dart';

class AnomalyAlertCard extends StatelessWidget {
  const AnomalyAlertCard({super.key, required this.alert, this.onDismiss});

  final AnomalyAlert alert;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade50, Colors.amber.shade50],
        ),
        border: Border.all(color: Colors.orange.shade200, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.warning_rounded,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unusual Spending Detected',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alert.message,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.grey[200]
                                  : Colors.grey[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(128),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'This spending',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'PKR ${alert.amount.toStringAsFixed(0)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.red.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(height: 40, width: 1, color: Colors.grey[300]),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Your average',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'PKR ${alert.average.toStringAsFixed(0)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.green.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_rounded,
                        color: Colors.blue.shade600,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          alert.suggestion,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.blue.shade800,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Colors.grey[500],
                ),
                onPressed: onDismiss,
                splashRadius: 20,
              ),
            ),
        ],
      ),
    );
  }
}

class AnomalyAlertsList extends StatefulWidget {
  const AnomalyAlertsList({
    super.key,
    required this.alerts,
    this.scrollable = false,
  });

  final List<AnomalyAlert> alerts;
  final bool scrollable;

  @override
  State<AnomalyAlertsList> createState() => _AnomalyAlertsListState();
}

class _AnomalyAlertsListState extends State<AnomalyAlertsList> {
  late List<AnomalyAlert> _dismissedAlerts;

  @override
  void initState() {
    super.initState();
    _dismissedAlerts = [];
  }

  void _dismissAlert(AnomalyAlert alert) {
    setState(() {
      _dismissedAlerts.add(alert);
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleAlerts = widget.alerts
        .where((a) => !_dismissedAlerts.contains(a))
        .toList();

    if (visibleAlerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      shrinkWrap: !widget.scrollable,
      physics: widget.scrollable
          ? const BouncingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      itemCount: visibleAlerts.length,
      itemBuilder: (context, index) => AnomalyAlertCard(
        alert: visibleAlerts[index],
        onDismiss: () => _dismissAlert(visibleAlerts[index]),
      ),
    );
  }
}
