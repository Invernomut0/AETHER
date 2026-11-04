# AETHERPersistence

Configuration, presets, schema migrations and repositories.

`JSONConfigurationRepository` initializes a missing configuration atomically with schema 1 defaults. It upgrades unversioned/schema 0 objects, fills missing legacy keys and preserves recognized user settings. Invalid values, malformed current schemas and future schema versions fail without overwriting the source file. Saves accept only the current schema.

The app uses `~/Library/Application Support/AETHER/configuration.json`. Tests use real files in isolated temporary directories and the shipped `Configuration/DefaultConfiguration.json`. SQLite remains planned for release.

See `Documentation/MODULES.md` and the relevant acceptance criteria before implementation.
