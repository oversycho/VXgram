# VXGram (Flutter + Supabase + BLoC, clean layers)

    lib/features/<feature>/
      domain/        repository interface (+ entities)      <- what the app needs
      data/
        datasources/ DataSource interface + Supabase impl   <- raw backend calls
        models/      JSON -> entity mapping
        repositories/ Repository impl (maps errors -> AppFailure)
      bloc/          depends ONLY on domain interfaces
      ui/            widgets, read blocs

Dependency direction: ui -> bloc -> domain <- data. `main.dart` is the only file that knows the concrete classes
(composition root). Tests use fakes from `test/fakes/` (no network, no Supabase).

Run: paste your keys into `lib/core/env.dart`, then `flutter pub get && flutter run`. Tests: `flutter test`.
