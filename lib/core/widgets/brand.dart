import 'package:flutter/material.dart';

/// One sharp, tightly framed wordmark across authentication and app surfaces.
/// Decode at physical pixels, not logical pixels, to avoid blurry HD screens.
class FixPkLogo extends StatelessWidget {
  const FixPkLogo({super.key, this.width = 180});
  final double width;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/brand/fixpk-logo.webp',
    width: width,
    height: width / 2,
    fit: BoxFit.contain,
    cacheWidth: (width * MediaQuery.devicePixelRatioOf(context)).ceil().clamp(
      1,
      1774,
    ),
    filterQuality: FilterQuality.medium,
    semanticLabel: 'FixPK',
  );
}

class BrandedStartup extends StatelessWidget {
  const BrandedStartup({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FixPkLogo(width: 208),
            SizedBox(height: 32),
            SizedBox(
              width: 100,
              child: LinearProgressIndicator(
                minHeight: 2,
                semanticsLabel: 'Starting FixPK',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
