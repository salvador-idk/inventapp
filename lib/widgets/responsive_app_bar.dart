import 'package:flutter/material.dart';

class ResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final double elevation;

  const ResponsiveAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.elevation = 4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.blueGrey[700],
      foregroundColor: Colors.white,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: actions,
      elevation: elevation,
      centerTitle: false,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}