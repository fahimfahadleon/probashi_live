import 'package:flutter/material.dart';

class CustomTabBar extends StatelessWidget {
  final int selectedIndex;
  final List<String> tabs;
  final Function(int) onTap;

  const CustomTabBar({
    super.key,
    required this.selectedIndex,
    required this.tabs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final totalWidth = constraints.maxWidth;
      // Measure approximate text widths or just divide space equally for simplicity:
      final tabWidths = tabs.map((t) {
        final painter = TextPainter(
          text: TextSpan(text: t, style: DefaultTextStyle.of(context).style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout();
        return painter.size.width + 24; // add some horizontal padding
      }).toList();

      final totalTabsWidth = tabWidths.reduce((a, b) => a + b);
      final remainingSpace = (totalWidth - totalTabsWidth).clamp(0, double.infinity);
      final spacerWidth = remainingSpace / (tabs.length + 1);

      List<Widget> tabWidgets = [];
      for (int i = 0; i < tabs.length; i++) {
        if (i == 0) tabWidgets.add(SizedBox(width: spacerWidth));
        tabWidgets.add(GestureDetector(
          onTap: () => onTap(i),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              border: i == selectedIndex
                  ? Border(bottom: BorderSide(width: 2, color: Colors.amberAccent))
                  : null,
            ),
            child: Text(
              tabs[i],
              style: TextStyle(
                color: i == selectedIndex ? Colors.amberAccent : Colors.white70,
                fontWeight: i == selectedIndex ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ));
        tabWidgets.add(SizedBox(width: spacerWidth));
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: tabWidgets,
      );
    });
  }
}