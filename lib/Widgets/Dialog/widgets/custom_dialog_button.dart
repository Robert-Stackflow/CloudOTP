import 'package:flutter/material.dart';

class CustomDialogButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final Color bgColor;
  final Color buttonTextColor;
  final bool isOutlined;
  final double borderRadius;

  const CustomDialogButton({
    super.key,
    required this.text,
    this.onTap,
    required this.bgColor,
    required this.isOutlined,
    this.buttonTextColor = Colors.white,
    this.borderRadius = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isOutlined ? Colors.transparent : bgColor,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          height: 45,
          decoration: BoxDecoration(
            border: isOutlined
                ? Border.all(
                    color: isOutlined ? bgColor.withAlpha(127) : bgColor)
                : null,
            borderRadius: BorderRadius.circular(borderRadius),
            color: Colors.transparent,
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isOutlined ? bgColor : buttonTextColor,
            ),
          ),
        ),
      ),
    );
  }
}
