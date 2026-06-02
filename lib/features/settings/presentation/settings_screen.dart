import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../data/settings_repository.dart';
import '../data/export_service.dart';
import '../data/import_service.dart';
import '../../workout/data/workout_repository.dart';
import 'manage_exercises_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.scale),
            title: Text(l10n.weightUnit),
            subtitle: Text(settings.weightUnit == WeightUnit.kg ? 'kg' : 'lbs'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showWeightUnitDialog(context, l10n, settings, notifier),
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: Text(l10n.theme),
            subtitle: Text(_getThemeLabel(l10n, settings.themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context, l10n, settings, notifier),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(settings.locale.languageCode == 'ko' ? l10n.korean : l10n.english),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageDialog(context, l10n, settings, notifier),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.fitness_center),
            title: Text(l10n.manageExercises),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ManageExercisesScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: Text(l10n.exportData),
            subtitle: Text(l10n.exportDataDesc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _exportData(context, l10n, ref),
          ),
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: Text(l10n.importData),
            subtitle: Text(l10n.importDataDesc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _importData(context, l10n, ref),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.about),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAboutDialog(context, l10n),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(l10n.resetData, style: const TextStyle(color: Colors.red)),
            onTap: () => _showResetDialog(context, l10n, ref),
          ),
        ],
      ),
    );
  }

  String _getThemeLabel(AppLocalizations l10n, AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return l10n.themeLight;
      case AppThemeMode.dark:
        return l10n.themeDark;
      case AppThemeMode.system:
        return l10n.themeSystem;
    }
  }

  void _showWeightUnitDialog(
    BuildContext context,
    AppLocalizations l10n,
    AppSettings settings,
    SettingsNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.weightUnit),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: WeightUnit.values.map((unit) {
            return RadioListTile<WeightUnit>(
              title: Text(unit == WeightUnit.kg ? 'kg' : 'lbs'),
              value: unit,
              groupValue: settings.weightUnit,
              onChanged: (value) {
                if (value != null) {
                  notifier.setWeightUnit(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showThemeDialog(
    BuildContext context,
    AppLocalizations l10n,
    AppSettings settings,
    SettingsNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.theme),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeMode.values.map((mode) {
            return RadioListTile<AppThemeMode>(
              title: Text(_getThemeLabel(l10n, mode)),
              value: mode,
              groupValue: settings.themeMode,
              onChanged: (value) {
                if (value != null) {
                  notifier.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showLanguageDialog(
    BuildContext context,
    AppLocalizations l10n,
    AppSettings settings,
    SettingsNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(l10n.korean),
              value: 'ko',
              groupValue: settings.locale.languageCode,
              onChanged: (value) {
                if (value != null) {
                  notifier.setLocale(Locale(value));
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: Text(l10n.english),
              value: 'en',
              groupValue: settings.locale.languageCode,
              onChanged: (value) {
                if (value != null) {
                  notifier.setLocale(Locale(value));
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context, AppLocalizations l10n, WidgetRef ref) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final exportService = ref.read(exportServiceProvider);

    final box = context.findRenderObject() as RenderBox?;
    final sharePositionOrigin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;

    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text(l10n.exporting)),
    );

    try {
      await exportService.exportAllData(sharePositionOrigin: sharePositionOrigin);
    } catch (e) {
      final message = e.toString().contains('No data')
          ? l10n.noDataToExport
          : l10n.exportFailed(e.toString());
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _importData(BuildContext context, AppLocalizations l10n, WidgetRef ref) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final importService = ref.read(importServiceProvider);

    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text(l10n.importing)),
    );

    try {
      final result = await importService.importFromFiles();
      scaffoldMessenger.hideCurrentSnackBar();

      if (result == null) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.importCancelled)),
        );
        return;
      }

      if (!result.hasData) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.noDataImported)),
        );
        return;
      }

      var message = l10n.importSuccess(
        result.workoutSetsImported,
        result.bodyRecordsImported,
        result.exercisesCreated,
      );
      if (result.hasErrors) {
        message += ' (${l10n.importWithErrors(result.errors.length)})';
      }
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.importFailed(e.toString()))),
      );
    }
  }

  void _showAboutDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/icons/app_icon.png',
                  width: 80,
                  height: 80,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.appName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${l10n.version} 0.1.0',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.aboutDescription,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 24),
              _buildInfoRow(Icons.person, l10n.developer, 'Haksoo Kim'),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _launchEmail(),
                child: _buildInfoRow(
                  Icons.email,
                  l10n.contact,
                  'crane1129@gmail.com',
                  isLink: true,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isLink = false}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isLink ? AppColors.primary : null,
              decoration: isLink ? TextDecoration.underline : null,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launchEmail() async {
    final uri = Uri(scheme: 'mailto', path: 'crane1129@gmail.com');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showResetDialog(BuildContext context, AppLocalizations l10n, WidgetRef ref) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.resetData),
        content: Text(l10n.resetDataWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                final repo = ref.read(workoutRepositoryProvider);
                await repo.deleteAllData();
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text(l10n.dataReset)),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text(l10n.resetFailed(e.toString()))),
                );
              }
            },
            child: Text(l10n.reset),
          ),
        ],
      ),
    );
  }
}
