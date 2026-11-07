import 'package:flutter/material.dart';

import '../app_session.dart';

/// 个人中心：昵称、头像、简介与常用起终点。
///
/// 资料只保存在本机会话中，不进入 did:key，也不参与签名。
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  static const nicknameFieldKey = Key('profile.nickname');
  static const saveButtonKey = Key('profile.save');

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _avatars = <String>[
    '🙂',
    '🚲',
    '📦',
    '🍜',
    '🧰',
    '🚗',
    '🌿',
    '✨',
  ];

  final _formKey = GlobalKey<FormState>();
  TextEditingController? _nickname;
  TextEditingController? _bio;
  TextEditingController? _origin;
  TextEditingController? _destination;
  String _avatar = _avatars.first;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) {
      return;
    }
    final profile = AppScope.of(context).profile;
    _nickname = TextEditingController(text: profile.nickname);
    _bio = TextEditingController(text: profile.bio);
    _origin = TextEditingController(text: profile.defaultOrigin);
    _destination = TextEditingController(text: profile.defaultDestination);
    _avatar = _avatars.contains(profile.avatar)
        ? profile.avatar
        : _avatars.first;
    _loaded = true;
  }

  @override
  void dispose() {
    _nickname?.dispose();
    _bio?.dispose();
    _origin?.dispose();
    _destination?.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final session = AppScope.of(context);
    session.updateProfile(
      UserProfile(
        nickname: _nickname!.text.trim(),
        avatar: _avatar,
        bio: _bio!.text.trim(),
        defaultOrigin: _origin!.text.trim(),
        defaultDestination: _destination!.text.trim(),
      ),
    );
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('个人资料已保存')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('个人中心')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      const Color(0xFF3F8A70),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      child: Text(
                        _avatar,
                        style: const TextStyle(fontSize: 34),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nickname?.text.trim().isEmpty ?? true
                                ? '本机用户'
                                : _nickname!.text.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '资料仅保存在本机 · 不进入身份标识',
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                key: ProfilePage.nicknameFieldKey,
                controller: _nickname,
                maxLength: 40,
                decoration: const InputDecoration(
                  labelText: '昵称',
                  counterText: '',
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请填写昵称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text('头像', style: textTheme.labelMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final avatar in _avatars)
                    ChoiceChip(
                      label: Text(avatar, style: const TextStyle(fontSize: 20)),
                      selected: _avatar == avatar,
                      onSelected: (_) => setState(() => _avatar = avatar),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text('首版使用内置头像；图片上传需要本地存储与权限，后续再加。', style: textTheme.bodySmall),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bio,
                maxLength: 200,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: '简介（可选）',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _origin,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: '常用起点（可选）',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _destination,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: '常用终点（可选）',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: ProfilePage.saveButtonKey,
                  onPressed: _save,
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
