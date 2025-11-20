import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(subtitle, style: const TextStyle(color: Colors.black45))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
