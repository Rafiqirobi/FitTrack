import 'package:flutter/material.dart';
import '../services/running_session_service.dart';

/// Persistent Running Banner Widget
/// Shows at the bottom of any page when a run is active
/// User can tap to return to running screen
class RunningActiveBanner extends StatelessWidget {
  final VoidCallback? onTap; // Callback when user taps the banner
  
  const RunningActiveBanner({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: runningSession,
      builder: (context, _) {
        if (!runningSession.isRunning) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final isDarkMode = theme.brightness == Brightness.dark;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            color: Colors.green[600],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Animated Running Indicator
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Running Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '🏃 Still Running',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${runningSession.formattedTime} • ${runningSession.distanceKm.toStringAsFixed(2)} km • ${runningSession.currentPaceStr}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Tap to Resume Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Alternative: Compact Floating Button (for corner placement)
class RunningActiveFloatingButton extends StatelessWidget {
  final VoidCallback? onTap;
  
  const RunningActiveFloatingButton({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: runningSession,
      builder: (context, _) {
        if (!runningSession.isRunning) {
          return const SizedBox.shrink();
        }

        return Positioned(
          bottom: 20,
          right: 20,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[600],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green[600]!.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '🏃',
                    style: TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    runningSession.formattedTime,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
