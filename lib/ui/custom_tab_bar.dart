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
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(tabs.length, (i) {
            return GestureDetector(
              onTap: () => onTap(i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  border: i == selectedIndex
                      ? const Border(
                    bottom: BorderSide(width: 2, color: Colors.amberAccent),
                  )
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
            );
          }),
        );
      },
    );
  }

}