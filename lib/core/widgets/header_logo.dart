import 'package:flutter/material.dart';

import '../gen/assets.gen.dart';

/// The centred Islami wordmark that heads most screens, sized as a fraction of
/// the screen width (each screen in the Figma file uses its own).
class HeaderLogo extends StatelessWidget {
  final double widthFactor;

  const HeaderLogo({super.key, this.widthFactor = 0.6});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Assets.images.imgHeader.image(
        width: MediaQuery.sizeOf(context).width * widthFactor,
      ),
    );
  }
}
