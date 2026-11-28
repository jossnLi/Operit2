// ignore_for_file: file_names

import 'package:operit2/ui/common/icons/operit_icons.dart';

/// Semantic icons for the model and AI surfaces.
///
/// Pages should depend on this catalog instead of picking raw icons ad hoc.
/// Provider brand marks stay in `ProviderLogo`; this file only covers UI
/// affordances and runtime concepts.
abstract final class ModelAiIcons {
  static const back = OperitIcons.chevron_left_rounded;
  static const close = OperitIcons.close_rounded;
  static const chevron = OperitIcons.chevron_right_rounded;
  static const expandMore = OperitIcons.keyboard_arrow_down_rounded;
  static const expandLess = OperitIcons.keyboard_arrow_up_rounded;
  static const add = OperitIcons.add_rounded;
  static const search = OperitIcons.search_rounded;

  /// Metadata used by model cards.
  static const context = OperitIcons.data_usage_rounded;
  static const spark = OperitIcons.auto_awesome_rounded;

  /// A configured provider account, not a credential.
  static const account = OperitIcons.account_circle_outlined;
  static const signIn = OperitIcons.login_rounded;
  static const signOut = OperitIcons.logout_rounded;

  /// An API key or credential field. A fingerprint reads as a secret owned by
  /// the user; the old key/lock glyph made every field look like a password
  /// reset action.
  static const apiKey = OperitIcons.badge_outlined;

  /// A model or model layer.
  static const model = OperitIcons.psychology_outlined;
  static const modelLibrary = OperitIcons.layers_outlined;

  /// Generation and runtime preferences.
  static const preferences = OperitIcons.tune_outlined;
  static const functionMapping = OperitIcons.route_outlined;

  /// Connectivity, endpoints and diagnostics.
  static const endpoint = OperitIcons.link_rounded;
  static const rateLimit = OperitIcons.speed_rounded;
  static const diagnostics = OperitIcons.cable_rounded;
  static const runTest = OperitIcons.play_arrow_rounded;

  static const settings = OperitIcons.settings_outlined;
  static const info = OperitIcons.info_outline_rounded;
  static const refresh = OperitIcons.refresh_rounded;
  static const visibility = OperitIcons.visibility_outlined;

  /// Status and result feedback.
  static const check = OperitIcons.check_rounded;
  static const selection = OperitIcons.check_box_rounded;
  static const success = OperitIcons.check_circle_rounded;
  static const error = OperitIcons.error_outline_rounded;
  static const warning = OperitIcons.warning_amber_rounded;

  /// Authorization actions.
  static const copy = OperitIcons.content_copy_rounded;
  static const paste = OperitIcons.content_paste_outlined;
  static const externalLink = OperitIcons.open_in_new_rounded;
  static const deviceCode = OperitIcons.devices_outlined;
  static const waiting = OperitIcons.hourglass_top_rounded;

  /// Function mapping roles.
  static const chatFunction = OperitIcons.chat_bubble_outline_rounded;
  static const summaryFunction = OperitIcons.description_outlined;
  static const titleFunction = OperitIcons.edit_note_outlined;
  static const memoryFunction = OperitIcons.memory_outlined;
  static const uiControlFunction = OperitIcons.dashboard_customize_outlined;
  static const translationFunction = OperitIcons.language_outlined;
  static const retrievalFunction = OperitIcons.search_rounded;
  static const rolePlannerFunction = OperitIcons.person_outline_rounded;
  static const imageFunction = OperitIcons.image_outlined;
  static const audioFunction = OperitIcons.audiotrack_outlined;
  static const videoFunction = OperitIcons.movie_creation_outlined;
}
