import 'package:flutter/material.dart';

import 'device_playlist_draft.dart';

class PlaylistManagementPage extends StatefulWidget {
  const PlaylistManagementPage({super.key});

  @override
  State<PlaylistManagementPage> createState() => _PlaylistManagementPageState();
}

class _PlaylistManagementPageState extends State<PlaylistManagementPage> {
  var _kind = DevicePlaylistKind.startup;
  late var _startup = const DevicePlaylistDraft(
    kind: DevicePlaylistKind.startup,
    enabled: true,
    loopMode: PlaylistLoopMode.listLoop,
    videoNames: ['PET_WELCOME.MP4', 'FAMILY_HOST.MP4', 'AMBIENT_LOOP.MP4'],
  );
  late var _bluetooth = const DevicePlaylistDraft(
    kind: DevicePlaylistKind.bluetooth,
    enabled: true,
    loopMode: PlaylistLoopMode.listLoop,
    videoNames: ['MUSIC_JELLYFISH.MP4', 'NEON_EARTH.MP4'],
  );

  DevicePlaylistDraft get _draft =>
      _kind == DevicePlaylistKind.startup ? _startup : _bluetooth;

  void _update(DevicePlaylistDraft value) {
    setState(() {
      if (_kind == DevicePlaylistKind.startup) {
        _startup = value;
      } else {
        _bluetooth = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('设备播放列表')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const _ProtocolNotice(),
            const SizedBox(height: 16),
            SegmentedButton<DevicePlaylistKind>(
              segments: const [
                ButtonSegment(
                  value: DevicePlaylistKind.startup,
                  icon: Icon(Icons.power_settings_new),
                  label: Text('开机播放'),
                ),
                ButtonSegment(
                  value: DevicePlaylistKind.bluetooth,
                  icon: Icon(Icons.bluetooth_audio),
                  label: Text('蓝牙播放'),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (selection) {
                setState(() => _kind = selection.single);
              },
            ),
            const SizedBox(height: 18),
            Text(
              _kind == DevicePlaylistKind.startup
                  ? '设备开机且未连接蓝牙时自动播放'
                  : '蓝牙音源连接后由硬件自动切换播放',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _draft.enabled,
              onChanged: (value) => _update(_draft.copyWith(enabled: value)),
              title: Text(
                _kind == DevicePlaylistKind.startup ? '开机自动播放' : '连接蓝牙后播放画面',
              ),
              subtitle: const Text('当前修改仅保存在交互草案中'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<PlaylistLoopMode>(
              initialValue: _draft.loopMode,
              decoration: const InputDecoration(
                labelText: '循环方式',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: PlaylistLoopMode.listLoop,
                  child: Text('列表循环'),
                ),
                DropdownMenuItem(
                  value: PlaylistLoopMode.singleLoop,
                  child: Text('单曲循环'),
                ),
                DropdownMenuItem(
                  value: PlaylistLoopMode.playOnce,
                  child: Text('播放一次'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  _update(_draft.copyWith(loopMode: value));
                }
              },
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('播放顺序', style: Theme.of(context).textTheme.titleLarge),
                Text('${_draft.videoNames.length} 个视频'),
              ],
            ),
            const SizedBox(height: 8),
            for (var index = 0; index < _draft.videoNames.length; index++)
              Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(_draft.videoNames[index]),
                  subtitle: index == 0 ? const Text('默认首条') : null,
                  trailing: Wrap(
                    children: [
                      IconButton(
                        tooltip: '上移',
                        onPressed: index == 0
                            ? null
                            : () => _update(_draft.move(index, index - 1)),
                        icon: const Icon(Icons.keyboard_arrow_up),
                      ),
                      IconButton(
                        tooltip: '下移',
                        onPressed: index == _draft.videoNames.length - 1
                            ? null
                            : () => _update(_draft.move(index, index + 1)),
                        icon: const Icon(Icons.keyboard_arrow_down),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.sync_disabled),
              label: const Text('保存到设备 · 等待新版协议'),
            ),
            if (_kind == DevicePlaylistKind.bluetooth) ...[
              const SizedBox(height: 12),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.settings_backup_restore),
                  title: Text('蓝牙断开后的恢复策略'),
                  subtitle: Text('建议：恢复蓝牙连接前正在播放的普通视频；等待协议确认'),
                ),
              ),
            ],
          ],
        ),
      );
}

class _ProtocolNotice extends StatelessWidget {
  const _ProtocolNotice();

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '两套播放列表的交互已经规划。当前协议只能读取设备统一视频列表，以下调整不会写入硬件。',
                ),
              ),
            ],
          ),
        ),
      );
}
