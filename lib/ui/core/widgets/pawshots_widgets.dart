import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/records.dart';
import '../../../l10n/app_localizations.dart';
import '../theme/pawshots_theme.dart';

String displayDate(BuildContext context, String date) => DateFormat(
  'd MMM y',
  AppLocalizations.of(context)!.localeName,
).format(DateTime.parse(date));

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size * 1.13,
    child: CustomPaint(
      painter: _ShieldPainter(),
      child: Icon(Icons.pets, size: size * .65, color: Colors.white),
    ),
  );
}

class _ShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(w * .5, 0)
      ..lineTo(w * .95, h * .12)
      ..quadraticBezierTo(w, h * .14, w, h * .2)
      ..lineTo(w * .98, h * .53)
      ..quadraticBezierTo(w * .95, h * .82, w * .5, h)
      ..quadraticBezierTo(w * .05, h * .82, w * .02, h * .53)
      ..lineTo(0, h * .2)
      ..quadraticBezierTo(0, h * .14, w * .05, h * .12)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [PawColors.petrol, PawColors.petrolDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_ShieldPainter oldDelegate) => false;
}

class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const BrandMark(size: 34),
      const SizedBox(width: 10),
      Text(
        AppLocalizations.of(context)!.appName,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -.9,
        ),
      ),
    ],
  );
}

/// Crops the bundled illustrative photograph at layout time, without requiring
/// network images. These are not owner-uploaded photographs.
class PetPortrait extends StatelessWidget {
  const PetPortrait({super.key, required this.species, this.radius = 16});
  final String species;
  final double radius;
  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context)!.petIllustration,
    image: true,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crop = species == 'cat'
              ? const Rect.fromLTWH(0, 710, 580, 610)
              : const Rect.fromLTWH(355, 325, 650, 740);
          final scale = math.max(
            constraints.maxWidth / crop.width,
            constraints.maxHeight / crop.height,
          );
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left:
                    -crop.left * scale -
                    (crop.width * scale - constraints.maxWidth) / 2,
                top:
                    -crop.top * scale -
                    (crop.height * scale - constraints.maxHeight) / 2,
                width: 1024 * scale,
                height: 1536 * scale,
                child: Image.asset(
                  'assets/images/welcome_pets.png',
                  fit: BoxFit.fill,
                  excludeFromSemantics: true,
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

String petSubtitle(BuildContext context, Pet pet) {
  final s = AppLocalizations.of(context)!;
  final birth = DateTime.parse(pet.birthDate), today = colomboToday();
  final months = math.max(
    0,
    (today.year - birth.year) * 12 +
        today.month -
        birth.month -
        (today.day < birth.day ? 1 : 0),
  );
  final age = months < 12 ? s.ageMonths(months) : s.ageYears(months ~/ 12);
  return '${pet.breed.isEmpty ? (pet.species == 'dog' ? s.dog : s.cat) : pet.breed} · $age';
}

class DoseRing extends StatelessWidget {
  const DoseRing({super.key, required this.recorded, required this.total});
  final int recorded, total;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 106,
    height: 106,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: CircularProgressIndicator(
            value: total == 0 ? 0 : recorded / total,
            strokeWidth: 9,
            strokeCap: StrokeCap.round,
            backgroundColor: PawColors.line,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.doseFraction(recorded, total),
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            Text(
              AppLocalizations.of(context)!.doses,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ],
    ),
  );
}

class EditorHeader extends StatelessWidget {
  const EditorHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: PawColors.iceDeep,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: PawColors.petrol, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: PawColors.muted, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class IceNotice extends StatelessWidget {
  const IceNotice({
    super.key,
    required this.text,
    this.icon = Icons.info_outline,
  });
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: PawColors.iceDeep.withValues(alpha: .65),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: PawColors.petrol),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: PawColors.petrol,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ),
      ],
    ),
  );
}
