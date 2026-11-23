import os
import re
import csv
import json

# 读取 valid_icons 确保每个替换都真实有效
valid_icons = set()
with open(r'apps/flutter/app/lib/ui/common/icons/material_icons.g.dart', 'r', encoding='utf-8') as f:
    for line in f:
        m = re.search(r"'([a-zA-Z0-9_]+)':\s*Icons\.([a-zA-Z0-9_]+)", line)
        if m:
            valid_icons.add(m.group(2))

# 核心映射表：精准匹配 ChatGPT PC 端设计风格
icon_mapping = {
    # 核心发送与聊天交互 (ChatGPT PC 标志性)
    'send': 'arrow_upward_rounded',
    'stop': 'stop_rounded',
    'segment': 'view_sidebar_outlined',
    'add_comment': 'edit_note_rounded',
    'add_comment_outlined': 'edit_note_rounded',
    'rate_review': 'edit_note_rounded',
    'rate_review_outlined': 'edit_note_rounded',
    'assistant': 'auto_awesome_rounded',
    'auto_awesome': 'auto_awesome_rounded',
    'auto_fix_high': 'auto_awesome_rounded',
    'psychology': 'psychology_outlined',
    'mic': 'mic_none_rounded',
    'mic_outlined': 'mic_none_rounded',
    'attach_file': 'attach_file_rounded',
    'graphic_eq': 'graphic_eq_rounded',
    'chat_bubble_outline': 'chat_bubble_outline_rounded',
    'chat_outlined': 'chat_bubble_outline_rounded',
    'chat': 'chat_bubble_outline_rounded',

    # 消息操作与上下文
    'content_copy': 'content_copy_outlined',
    'copy': 'content_copy_outlined',
    'copy_outlined': 'content_copy_outlined',
    'copy_rounded': 'content_copy_outlined',
    'content_cut': 'content_cut_rounded',
    'content_paste': 'content_paste_outlined',
    'refresh': 'refresh_rounded',
    'edit': 'edit_outlined',
    'edit_note': 'edit_note_rounded',
    'delete': 'delete_outline_rounded',
    'delete_outline': 'delete_outline_rounded',
    'delete_sweep': 'delete_sweep_outlined',
    'reply': 'reply_rounded',
    'reply_all': 'reply_all_rounded',
    'summarize': 'summarize_outlined',
    'account_tree': 'account_tree_outlined',
    'info': 'info_outline_rounded',
    'info_outline': 'info_outline_rounded',
    'check_circle': 'check_circle_outline_rounded',
    'check_circle_outline': 'check_circle_outline_rounded',
    'volume_up': 'volume_up_outlined',
    'volume_off': 'volume_off_outlined',
    'volume_mute': 'volume_mute_rounded',
    'ios_share': 'ios_share_rounded',
    'share': 'share_outlined',
    'save_alt': 'download_rounded',
    'save': 'save_outlined',

    # 侧边栏与组织结构
    'folder': 'folder_outlined',
    'folder_open': 'folder_open_outlined',
    'create_new_folder': 'create_new_folder_outlined',
    'folder_special': 'folder_special_outlined',
    'push_pin': 'push_pin_outlined',
    'lock': 'lock_outline_rounded',
    'lock_open': 'lock_open_rounded',
    'lock_rounded': 'lock_outline_rounded',
    'lock_outline': 'lock_outline_rounded',
    'link_off': 'link_off_rounded',
    'vertical_align_top': 'vertical_align_top_rounded',
    'more_vert': 'more_horiz_rounded',
    'more_vert_outlined': 'more_horiz_rounded',
    'more_vert_rounded': 'more_horiz_rounded',
    'more_horiz': 'more_horiz_rounded',
    'search': 'search_rounded',
    'search_off_outlined': 'search_off_rounded',

    # 控制器与箭头导航
    'close': 'close_rounded',
    'clear': 'close_rounded',
    'add': 'add_rounded',
    'check': 'check_rounded',
    'chevron_right': 'chevron_right_rounded',
    'chevron_left': 'chevron_left_rounded',
    'arrow_back': 'arrow_back_rounded',
    'arrow_forward': 'arrow_forward_rounded',
    'arrow_upward': 'arrow_upward_rounded',
    'arrow_drop_down': 'keyboard_arrow_down_rounded',
    'keyboard_arrow_down': 'keyboard_arrow_down_rounded',
    'keyboard_arrow_up': 'keyboard_arrow_up_rounded',
    'keyboard_arrow_right': 'chevron_right_rounded',
    'keyboard_arrow_left': 'chevron_left_rounded',
    'expand_more': 'expand_more_rounded',
    'expand_less': 'expand_less_rounded',
    'unfold_more': 'unfold_more_rounded',
    'unfold_less': 'unfold_less_rounded',
    'play_arrow': 'play_arrow_rounded',
    'pause': 'pause_rounded',
    'fullscreen': 'fullscreen_rounded',
    'fullscreen_exit': 'fullscreen_exit_rounded',
    'tune': 'tune_rounded',
    'terminal': 'terminal_rounded',
    'code': 'code_rounded',
    'language': 'language_rounded',
    'link': 'link_rounded',
    'link_outlined': 'link_rounded',
    'open_in_new': 'open_in_new_rounded',
    'open_in_browser': 'open_in_browser_rounded',
    'open_in_full': 'open_in_full_rounded',
    'person': 'person_outline_rounded',
    'person_outline': 'person_outline_rounded',
    'star': 'star_outline_rounded',
    'star_border': 'star_outline_rounded',
    'radio_button_checked': 'radio_button_checked_rounded',
    'radio_button_unchecked': 'radio_button_unchecked_rounded',
    'download': 'download_rounded',
    'schedule': 'schedule_rounded',
    'history': 'history_rounded',
    'sync': 'sync_rounded',
    'restart_alt': 'restart_alt_rounded',
    'restore': 'restore_rounded',
    'system_update_alt': 'system_update_alt_rounded',
    'update': 'update_rounded',
    'undo': 'undo_rounded',
    'redo': 'redo_rounded',
    'login': 'login_rounded',
    'logout': 'logout_rounded',
    'error': 'error_outline_rounded',
    'error_outline': 'error_outline_rounded',
    'tag': 'tag_rounded',
    'text_fields': 'text_fields_outlined',
    'title': 'title_rounded',
    'widgets': 'widgets_outlined',
    'fit_screen': 'fit_screen_rounded',
    'zoom_in': 'zoom_in_rounded',
    'zoom_out': 'zoom_out_rounded',
    'devices': 'devices_outlined',
    'public': 'public_rounded',
    'travel_explore': 'travel_explore_outlined',
    'extension': 'extension_outlined',
    'store': 'storefront_outlined',
    'ads_click': 'ads_click_outlined',
    'alt_route': 'alt_route_rounded',
    'block': 'block_rounded',
    'bookmark': 'bookmark_outline_rounded',
    'circle': 'circle_outlined',
    'data_object': 'data_object_outlined',
    'device_unknown': 'device_unknown_rounded',
    'favorite_border': 'favorite_border_rounded',
    'hub': 'hub_outlined',
    'image': 'image_outlined',
    'location_on': 'location_on_outlined',
    'notifications': 'notifications_none_rounded',
    'photo_camera': 'photo_camera_outlined',
    'playlist_add': 'playlist_add_rounded',
    'screenshot_monitor': 'desktop_windows_outlined',
    'speed': 'speed_rounded',
    'swap_horiz': 'swap_horiz_rounded',
    'work_outline': 'work_outline_rounded',
    'workspaces_outline': 'workspaces_outlined',
    'view_agenda': 'view_agenda_outlined',
    'view_column': 'view_column_outlined',
    'description': 'description_outlined',
    'notes': 'notes_outlined',
    'music_off': 'music_off_outlined',
    'remove': 'remove_rounded',
    'settings': 'settings_outlined',
    'help_outline': 'help_outline_rounded',
    'help': 'help_outline_rounded',
    'add_circle_outline': 'add_circle_outline_rounded',
    'add_to_home_screen': 'add_to_home_screen_outlined',
    'deselect': 'deselect_rounded',
    'select_all': 'select_all_rounded',
    'web': 'web_outlined',
    'crop_free': 'crop_free_outlined',
    'play_circle_outline': 'play_circle_outline_rounded',
}

# 验证所有目标图标存在
for orig, dest in icon_mapping.items():
    assert dest in valid_icons, f"Target icon '{dest}' does not exist in Flutter SDK!"

# 扫描文件
scan_dirs = [
    r'apps/flutter/app/lib',
    r'apps/flutter/packages/operit_ui/lib'
]

files_to_process = []
for d in scan_dirs:
    for root, dirs, files in os.walk(d):
        for f in files:
            if f.endswith('.dart') and f != 'material_icons.g.dart':
                files_to_process.append(os.path.join(root, f))

# 匹配正则：严格匹配 \bIcons\.([a-zA-Z0-9_]+)\b
icon_regex = re.compile(r'\bIcons\.([a-zA-Z0-9_]+)\b')

changes_log = []
files_modified = set()

def process_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    lines = content.split('\n')
    new_lines = []
    file_changed = False

    for line_idx, line in enumerate(lines, start=1):
        def repl(match):
            nonlocal file_changed
            icon_name = match.group(1)
            if icon_name in icon_mapping:
                target = icon_mapping[icon_name]
                if target != icon_name:
                    file_changed = True
                    changes_log.append({
                        'file': os.path.relpath(file_path, os.getcwd()).replace('\\', '/'),
                        'line': line_idx,
                        'original': icon_name,
                        'replacement': target,
                        'code_snippet': line.strip()
                    })
                    return f"Icons.{target}"
            return match.group(0)

        new_line = icon_regex.sub(repl, line)
        new_lines.append(new_line)

    if file_changed:
        files_modified.add(file_path)
        with open(file_path, 'w', encoding='utf-8', newline='\n') as f:
            f.write('\n'.join(new_lines))

for fp in files_to_process:
    process_file(fp)

print(f"Total files modified: {len(files_modified)}")
print(f"Total icon occurrences replaced: {len(changes_log)}")

# 保存变更清单为 JSON 和 CSV
with open('tools/icon_replacement_manifest.json', 'w', encoding='utf-8') as f:
    json.dump(changes_log, f, ensure_ascii=False, indent=2)

with open('tools/icon_replacement_manifest.csv', 'w', encoding='utf-8', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=['file', 'line', 'original', 'replacement', 'code_snippet'])
    writer.writeheader()
    writer.writerows(changes_log)

# 汇总按图标维度的替换统计
icon_stats = {}
for item in changes_log:
    pair = f"Icons.{item['original']} -> Icons.{item['replacement']}"
    icon_stats[pair] = icon_stats.get(pair, 0) + 1

print("\nTop 30 Icon replacements summary:")
for k, v in sorted(icon_stats.items(), key=lambda x: -x[1])[:30]:
    print(f"  {k}: {v} 次")
