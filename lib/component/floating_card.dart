import 'dart:ui';

import 'package:fluent_ui/fluent_ui.dart';

class FloatingCard extends StatefulWidget {
  const FloatingCard(
      {required this.closeCard, this.follow, required this.child, super.key});
  final Widget child;
  final Widget? follow;
  final Function(bool bl) closeCard;
  @override
  State<FloatingCard> createState() => FloatingCardState();
}

class FloatingCardState extends State<FloatingCard> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              height: double.infinity,
              width: double.infinity,
              color: Colors.black.withOpacity(0.3),
              child: (Container()),
            ),
          ),
          onTap: () => widget.closeCard(false),
        ),
        Center(
          child: SizedBox(
            height: 360,
            width: 480,
            child: Column(children: [
              Expanded(
                child: Card(child: widget.child),
              ),
              widget.follow != null
                  ? const SizedBox(
                      height: 18,
                    )
                  : Container(),
              widget.follow != null ? widget.follow! : Container(),
            ]),
          ),
        ),
      ],
    );
  }
}
