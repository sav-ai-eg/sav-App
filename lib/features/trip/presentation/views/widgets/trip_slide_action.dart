import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_colors.dart';

class TripSlideAction extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final Future<bool> Function() onSubmit;

  const TripSlideAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onSubmit,
    this.color = AppColors.errorColor,
    this.isLoading = false,
  });

  @override
  State<TripSlideAction> createState() => _TripSlideActionState();
}

class _TripSlideActionState extends State<TripSlideAction> {
  double _dragProgress = 0;
  bool _submitting = false;

  @override
  void didUpdateWidget(covariant TripSlideAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !_submitting) {
      _submitting = true;
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _dragProgress = 0;
      _submitting = false;
    }
  }

  Future<void> _finishDrag(BoxConstraints constraints) async {
    final canSubmit =
        _dragProgress >= 0.82 && !_submitting && !widget.isLoading;
    if (!canSubmit) {
      if (mounted) {
        setState(() => _dragProgress = 0);
      }
      return;
    }

    setState(() => _submitting = true);
    final accepted = await widget.onSubmit();
    if (!mounted) {
      return;
    }

    setState(() {
      _submitting = accepted || widget.isLoading;
      if (!accepted) {
        _dragProgress = 0;
      } else {
        _dragProgress = 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final thumbSize = 54.w;
        final maxDrag = (constraints.maxWidth - thumbSize)
            .clamp(1.0, double.infinity)
            .toDouble();
        final left = maxDrag * _dragProgress;

        return Container(
          height: 62.h,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(color: widget.color.withValues(alpha: 0.18)),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: _dragProgress > 0.55 ? 0.28 : 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.label,
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: widget.color,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(
                        Icons.keyboard_double_arrow_right_rounded,
                        color: widget.color,
                        size: 20.sp,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: left,
                child: GestureDetector(
                  onHorizontalDragUpdate: widget.isLoading || _submitting
                      ? null
                      : (details) {
                          setState(() {
                            _dragProgress =
                                (_dragProgress + (details.delta.dx / maxDrag))
                                    .clamp(0.0, 1.0);
                          });
                        },
                  onHorizontalDragEnd: widget.isLoading || _submitting
                      ? null
                      : (_) => _finishDrag(constraints),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: thumbSize,
                    height: 54.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(18.r),
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.22),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: widget.isLoading || _submitting
                        ? SizedBox(
                            width: 22.w,
                            height: 22.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Icon(widget.icon, color: Colors.white, size: 24.sp),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
