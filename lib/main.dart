import 'package:flutter/material.dart';
import 'config/dependencies.dart';
import 'l10n/app_localizations.dart';
import 'ui/pets/view_models/workspace_view_model.dart';
import 'ui/pets/widgets/workspace_screen.dart';
import 'ui/core/theme/pawshots_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(PawshotsApp(loadWorkspace: createWorkspace));
}

class PawshotsApp extends StatefulWidget {
  const PawshotsApp({super.key, required this.loadWorkspace});
  final Future<WorkspaceViewModel> Function() loadWorkspace;
  @override
  State<PawshotsApp> createState() => _PawshotsAppState();
}

class _PawshotsAppState extends State<PawshotsApp> {
  late Future<WorkspaceViewModel> _workspace = widget.loadWorkspace();
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: pawshotsTheme(),
    builder: (context, child) => ColoredBox(
      color: const Color(0xFFDDF2F7),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    ),
    home: FutureBuilder<WorkspaceViewModel>(
      future: _workspace,
      builder: (context, snapshot) {
        if (snapshot.hasData) return WorkspaceScreen(model: snapshot.data!);
        final s = AppLocalizations.of(context)!;
        return Scaffold(
          body: Center(
            child: snapshot.hasError
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(s.startupError),
                      FilledButton(
                        onPressed: () => setState(() {
                          _workspace = widget.loadWorkspace();
                        }),
                        child: Text(s.retry),
                      ),
                    ],
                  )
                : const CircularProgressIndicator(),
          ),
        );
      },
    ),
  );
}
