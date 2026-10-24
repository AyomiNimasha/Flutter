# PawShots folder structure

Current stage: an Android Flutter local workspace, PostgreSQL migrations, and Docker development tooling are implemented. See [Flutter development](flutter_development.md) for implemented features, commands, and remaining API integration.

- lib/config: dependency wiring
- lib/routing: navigation
- lib/l10n: localization ARB files
- lib/ui/core: shared theme and widgets
- lib/ui/{onboarding,pets,vaccinations,reminders,certificate}: view_models and widgets
- lib/domain/models: domain models
- lib/domain/use_cases: shared business logic
- lib/data/repositories: data ownership
- lib/data/services/{database,notification,image,pdf,cloud_sync,auth}: external services
- lib/data/database/{tables,daos}: drift schema and database access
- assets/data: editable vaccine templates
- docs: architecture decisions and data model
- test: mirrors application layers and features

Unused planned folders contain .gitkeep files. The current application uses MaterialPageRoute navigation and a shared WorkspaceViewModel; split routing and per-feature ViewModels as network-backed flows are added. Built-in vaccine template assets are not populated yet.

Use MVVM with ChangeNotifier and ListenableBuilder. Views render ViewModel state. Repositories do not depend on one another; use cases coordinate shared logic. Wire dependencies in lib/config/dependencies.dart.

Commit pubspec.lock when generated. Never commit secrets, signing keys, real owner data, real pet photos, or local databases. Mark all future sample vaccine templates DRAFT: pending veterinarian review.
