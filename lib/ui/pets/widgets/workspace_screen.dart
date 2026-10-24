import 'dart:async';
import 'package:flutter/material.dart';
import '../../../data/repositories/demo_repository.dart';
import '../../../data/services/notification/reminder_scheduler.dart';
import '../../../domain/models/records.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/theme/pawshots_theme.dart';
import '../../core/widgets/pawshots_widgets.dart';
import '../../core/widgets/support_screens.dart';
import '../../reminders/widgets/reminder_settings_screen.dart';
import '../../vaccinations/widgets/plan_screen.dart';
import '../view_models/workspace_view_model.dart';
import 'pet_editor.dart';

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key, required this.model});
  final WorkspaceViewModel model;
  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen>
    with WidgetsBindingObserver {
  Timer? _clock;
  String? _selectedPet;
  bool _entered = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh();
    });
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) widget.model.refreshStatuses();
    });
  }

  void _refresh() {
    final s = AppLocalizations.of(context)!;
    unawaited(
      widget.model.refreshReminders(s.notificationTitle, s.notificationChannel),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void dispose() {
    _clock?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _addPet() => Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (_) => PetEditor(model: widget.model)),
  );
  void _openPlan(Pet pet) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => PlanScreen(model: widget.model, petId: pet.id),
    ),
  );
  Future<void> _demo() async {
    final s = AppLocalizations.of(context)!;
    final demo = WorkspaceViewModel(
      DemoRepository(
        widget.model.repository,
        coreName: s.coreVaccine,
        rabiesName: s.rabies,
      ),
      _DemoScheduler(),
      isDemo: true,
    );
    await demo.load();
    if (!mounted) {
      demo.dispose();
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => WorkspaceScreen(model: demo)),
    );
    demo.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: widget.model,
      builder: (context, _) {
        final model = widget.model;
        if (model.pets.isEmpty && !_entered && !model.isDemo) {
          return _WelcomeScreen(
            onStart: () {
              setState(() {
                _entered = true;
              });
              _addPet();
            },
            onDemo: _demo,
          );
        }
        final selected =
            model.pets.where((p) => p.id == _selectedPet).firstOrNull ??
            model.pets.firstOrNull;
        final vaccines = selected == null
            ? <Vaccine>[]
            : model.forPet(selected.id);
        final pending = vaccines.where((v) => v.nextDue != null).toList()
          ..sort((a, b) => a.nextDue!.compareTo(b.nextDue!));
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            toolbarHeight: 76,
            title: const BrandWordmark(),
            actions: [
              if (model.isDemo)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: PawColors.iceDeep,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    s.demoLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 16),
                child: IconButton(
                  tooltip: s.settings,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => SettingsScreen(model: model),
                    ),
                  ),
                  style: IconButton.styleFrom(backgroundColor: Colors.white),
                  icon: const Icon(
                    Icons.person_outline_rounded,
                    color: PawColors.petrol,
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _PetBottomBar(
            onTap: (index) {
              if (index == 0) return;
              if (index == 2) {
                _addPet();
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => switch (index) {
                    1 => ReminderSettingsScreen(model: model),
                    3 => RecordsScreen(model: model),
                    _ => SettingsScreen(model: model),
                  },
                ),
              );
            },
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              Text(
                model.isDemo ? s.demoGreeting : s.helloPetParent,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 3),
              Text(
                s.careEveryDay,
                style: const TextStyle(color: PawColors.muted, fontSize: 18),
              ),
              const SizedBox(height: 20),
              if (model.pets.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final pet in model.pets)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(32),
                            onTap: () => setState(() {
                              _selectedPet = pet.id;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.fromLTRB(7, 6, 18, 6),
                              decoration: BoxDecoration(
                                color: selected?.id == pet.id
                                    ? PawColors.iceDeep.withValues(alpha: .65)
                                    : Colors.white.withValues(alpha: .55),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: selected?.id == pet.id
                                      ? PawColors.petrol
                                      : PawColors.line,
                                  width: selected?.id == pet.id ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 42,
                                    height: 42,
                                    child: PetPortrait(
                                      species: pet.species,
                                      radius: 50,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    pet.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: selected?.id == pet.id
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                      color: selected?.id == pet.id
                                          ? PawColors.petrol
                                          : PawColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              if (selected == null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        const BrandMark(size: 52),
                        const SizedBox(height: 20),
                        Text(
                          s.emptyPets,
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(s.emptyPetsBody, textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _addPet,
                          icon: const Icon(Icons.add),
                          label: Text(s.addPet),
                        ),
                      ],
                    ),
                  ),
                )
              else
                _PetCareCard(
                  pet: selected,
                  vaccines: vaccines,
                  onTap: () => _openPlan(selected),
                ),
              const SizedBox(height: 20),
              Text(s.comingUp, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Card(
                child: pending.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: PawColors.petrol,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.noUpcoming,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  Text(
                                    s.noUpcomingBody,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          for (var i = 0; i < pending.take(3).length; i++) ...[
                            if (i > 0)
                              const Divider(
                                height: 1,
                                indent: 18,
                                endIndent: 18,
                              ),
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 4,
                              ),
                              title: Text(
                                pending[i].name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                displayDate(context, pending[i].nextDue!),
                                style: const TextStyle(color: PawColors.muted),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  StatusBadge(
                                    status: pending[i].status(),
                                    plain: true,
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: PawColors.muted,
                                  ),
                                ],
                              ),
                              onTap: selected == null
                                  ? null
                                  : () => _openPlan(selected),
                            ),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 32),
              if (model.reminderFailed) IceNotice(text: s.reminderError),
              Text(
                model.isDemo ? s.demoNotice : s.localWorkspace,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              if (model.isDemo)
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(s.backToMyPets),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _WelcomeScreen extends StatelessWidget {
  const _WelcomeScreen({required this.onStart, required this.onDemo});
  final VoidCallback onStart, onDemo;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) => Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.white, Colors.white],
                  stops: [0, .18, 1],
                ).createShader(bounds),
                child: Image.asset(
                  'assets/images/welcome_pets.png',
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, .27, .44, .82, 1],
                  colors: [
                    Color(0xE8EAF9FD),
                    Color(0x88EAF9FD),
                    Color(0x00EAF9FD),
                    Color(0x22EAF9FD),
                    PawColors.ice,
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 26),
                    const BrandWordmark(),
                    SizedBox(height: constraints.maxHeight < 700 ? 26 : 44),
                    Text(
                      s.welcomeHeadline,
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontSize: constraints.maxHeight < 700 ? 34 : 40,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s.welcomeBody,
                      style: const TextStyle(fontSize: 17, height: 1.5),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onStart,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 58),
                          shape: const StadiumBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(width: 22),
                            Text(s.getStarted),
                            const Icon(Icons.arrow_forward),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          s.alreadyAccount,
                          style: const TextStyle(fontSize: 13),
                        ),
                        TextButton(
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(s.logIn),
                              content: Text(s.signInPending),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(s.cancel),
                                ),
                              ],
                            ),
                          ),
                          child: Text(s.logIn),
                        ),
                      ],
                    ),
                    Center(
                      child: TextButton(
                        onPressed: onDemo,
                        child: Text(s.exploreDemo),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetCareCard extends StatelessWidget {
  const _PetCareCard({
    required this.pet,
    required this.vaccines,
    required this.onTap,
  });
  final Pet pet;
  final List<Vaccine> vaccines;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final pending = vaccines.where((v) => v.nextDue != null).toList()
      ..sort((a, b) => a.nextDue!.compareTo(b.nextDue!));
    final recorded = vaccines.where((v) => v.dateGiven != null).length;
    final nearest = pending.firstOrNull;
    final remaining = nearest == null
        ? 0
        : DateTime.parse(
            '${nearest.nextDue}T00:00:00Z',
          ).difference(colomboToday()).inDays;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              SizedBox(
                height: 258,
                child: Stack(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: SizedBox(
                            height: 220,
                            child: PetPortrait(
                              species: pet.species,
                              radius: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 4,
                          child: SizedBox(
                            height: 210,
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: DoseRing(
                                  recorded: recorded,
                                  total: vaccines.length,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 17,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [PawColors.petrol, PawColors.petrolDark],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pet.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              petSubtitle(context, pet),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (nearest != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: PawColors.orangeSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        color: PawColors.orange,
                        size: 21,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          remaining > 0
                              ? s.dueInDays(nearest.name, remaining)
                              : '${nearest.name} · ${nearest.status() == VaccineStatus.overdue ? s.overdue : s.dueSoon}',
                          style: const TextStyle(
                            color: Color(0xFFBA6200),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: PawColors.orange,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PetBottomBar extends StatelessWidget {
  const _PetBottomBar({required this.onTap});
  final ValueChanged<int> onTap;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return SafeArea(
      top: false,
      child: Container(
        height: 82,
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: PawColors.line)),
          boxShadow: [
            BoxShadow(
              color: PawColors.petrol.withValues(alpha: .04),
              blurRadius: 18,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < 5; i++)
              Expanded(
                child: i == 2
                    ? Center(
                        child: Transform.translate(
                          offset: const Offset(0, -13),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: PawColors.petrol.withValues(
                                    alpha: .22,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton.filled(
                              tooltip: s.addPet,
                              onPressed: () => onTap(i),
                              style: IconButton.styleFrom(
                                fixedSize: const Size(58, 58),
                                backgroundColor: PawColors.petrol,
                              ),
                              icon: const Icon(Icons.add, size: 32),
                            ),
                          ),
                        ),
                      )
                    : InkWell(
                        onTap: () => onTap(i),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              switch (i) {
                                0 => Icons.pets,
                                1 => Icons.notifications_none_rounded,
                                3 => Icons.description_outlined,
                                _ => Icons.settings_outlined,
                              },
                              color: i == 0
                                  ? PawColors.petrol
                                  : PawColors.muted,
                              size: 25,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              switch (i) {
                                0 => s.petsTab,
                                1 => s.reminders,
                                3 => s.records,
                                _ => s.settings,
                              },
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: i == 0
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: i == 0
                                    ? PawColors.petrol
                                    : PawColors.muted,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              width: 30,
                              height: 2,
                              color: i == 0
                                  ? PawColors.petrol
                                  : Colors.transparent,
                            ),
                          ],
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DemoScheduler implements ReminderScheduler {
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<void> rebuild(
    List<Vaccine> vaccines,
    ReminderPreferences preferences,
    String title,
    String channelName,
  ) async {}
}
