import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/brand.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/services/app_version.dart';
import '../../../core/widgets/common.dart';
import '../domain/app_settings.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider);
    final version = ref.watch(appVersionProvider).value;
    final controller = ref.read(settingsProvider.notifier);
    void update(AppSettings Function(AppSettings) change) =>
        controller.update(change);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ScreenFrame(
        maxWidth: 640,
        child: ListView(
          children: [
            _Section(l10n.settingsSectionDisplay),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(l10n.settingsLanguage),
              subtitle: Text(
                settings.language == null
                    ? l10n.languageSystem
                    : nativeLanguageName(settings.language!),
              ),
              onTap: () => _chooseLanguage(context, ref, settings.language),
            ),
            ListTile(
              leading: const Icon(Icons.brightness_6_outlined),
              title: Text(l10n.settingsTheme),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text(l10n.themeSystem),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text(l10n.themeLight),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text(l10n.themeDark),
                    ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (selection) =>
                      update((s) => s.copyWith(themeMode: selection.single)),
                ),
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.grid_on),
              title: Text(l10n.settingsCoordinates),
              value: settings.showCoordinates,
              onChanged: (value) =>
                  update((s) => s.copyWith(showCoordinates: value)),
            ),
            _Section(l10n.settingsSectionGame),
            SwitchListTile(
              secondary: const Icon(Icons.lightbulb_outline),
              title: Text(l10n.settingsHints),
              value: settings.showMoveHints,
              onChanged: (value) =>
                  update((s) => s.copyWith(showMoveHints: value)),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.animation),
              title: Text(l10n.settingsAnimations),
              subtitle: Text(l10n.settingsAnimationsDescription),
              value: settings.animationsEnabled,
              onChanged: (value) =>
                  update((s) => s.copyWith(animationsEnabled: value)),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.volume_up_outlined),
              title: Text(l10n.settingsSound),
              value: settings.soundEnabled,
              onChanged: (value) =>
                  update((s) => s.copyWith(soundEnabled: value)),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.vibration),
              title: Text(l10n.settingsHaptics),
              value: settings.hapticsEnabled,
              onChanged: (value) =>
                  update((s) => s.copyWith(hapticsEnabled: value)),
            ),
            _Section(l10n.settingsSectionPrivacy),
            SwitchListTile(
              secondary: const Icon(Icons.insights_outlined),
              title: Text(l10n.settingsAnalytics),
              subtitle: Text(l10n.settingsAnalyticsDescription),
              value: settings.analyticsConsent,
              onChanged: (value) =>
                  update((s) => s.copyWith(analyticsConsent: value)),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(l10n.settingsPrivacyPolicy),
              onTap: () => _showPrivacyPolicy(context),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.settingsAbout),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: '${Brand.nameArabic} — ${Brand.nameLatin}',
                applicationVersion: version,
                applicationIcon: const BrandLogo(size: 48),
                children: [Text(l10n.aboutBody)],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Future<void> _showPrivacyPolicy(BuildContext context) {
    final l10n = context.l10n;
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsPrivacyPolicy),
        content: SingleChildScrollView(child: Text(l10n.privacyPolicyBody)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).closeButtonLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseLanguage(
    BuildContext context,
    WidgetRef ref,
    AppLanguage? current,
  ) async {
    final l10n = context.l10n;
    final options = <(AppLanguage?, String)>[
      (null, l10n.languageSystem),
      for (final language in AppLanguage.values)
        (language, nativeLanguageName(language)),
    ];
    final chosen = await showDialog<(AppLanguage?,)>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.settingsLanguage),
        children: [
          for (final (language, name) in options)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop((language,)),
              child: ListTile(
                title: Text(name),
                trailing: language == current ? const Icon(Icons.check) : null,
              ),
            ),
        ],
      ),
    );
    if (chosen == null) return;
    await ref
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(language: () => chosen.$1));
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.lg,
      AppSpacing.md,
      AppSpacing.xs,
    ),
    child: Semantics(
      header: true,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    ),
  );
}
