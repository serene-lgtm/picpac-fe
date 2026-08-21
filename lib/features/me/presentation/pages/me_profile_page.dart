import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/me.dart';
import '../../data/me_repository.dart';
import '../widgets/me_widgets.dart';

class MeProfilePage extends StatefulWidget {
  const MeProfilePage({
    super.key,
    required this.meRepository,
    this.initialUser,
  });

  final MeRepository meRepository;
  final MeUser? initialUser;

  @override
  State<MeProfilePage> createState() => _MeProfilePageState();
}

class _MeProfilePageState extends State<MeProfilePage> {
  final _usernameController = TextEditingController();
  final _picker = ImagePicker();
  late Future<MeUser> _meFuture;
  String _gender = 'private';
  String _birthday = '';
  XFile? _pickedAvatar;
  bool _usernameTouched = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initialUser = widget.initialUser;
    if (initialUser == null) {
      _meFuture = _loadMe();
    } else {
      _applyUser(initialUser);
      _meFuture = Future<MeUser>.value(initialUser);
    }
  }

  Future<MeUser> _loadMe() async {
    final user = await widget.meRepository.getMe();
    _applyUser(user);
    return user;
  }

  void _applyUser(MeUser user) {
    _usernameController.text = effectiveUsername(user);
    _gender = user.profile.gender.isEmpty ? 'private' : user.profile.gender;
    _birthday = user.profile.birthday;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _openAvatarActions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7D7D7),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('从相册选择'),
                  onTap: () => _pickAvatar(ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('拍照'),
                  onTap: () => _pickAvatar(ImageSource.camera),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAvatar(ImageSource source) async {
    Navigator.of(context).pop();
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1200,
    );
    if (image == null || !mounted) return;
    setState(() => _pickedAvatar = image);
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final parsedBirthday = DateTime.tryParse(_birthday);
    final date = await showDatePicker(
      context: context,
      initialDate: parsedBirthday ?? DateTime(now.year - 18, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (date == null) return;
    setState(() => _birthday = formatMeDate(date));
  }

  Future<void> _save() async {
    setState(() => _usernameTouched = true);
    final username = _usernameController.text.trim();
    if (username.isEmpty || _saving) return;

    setState(() => _saving = true);
    try {
      final updated = await widget.meRepository.updateProfile(
        username: username,
        gender: _gender,
        birthday: _birthday,
        avatar: _pickedAvatar == null ? null : avatarPart(_pickedAvatar!),
      );
      if (mounted) Navigator.of(context).pop(updated);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUsername = _usernameController.text.trim().isNotEmpty;
    return MeGradientScaffold(
      child: FutureBuilder<MeUser>(
        future: _meFuture,
        builder: (context, snapshot) {
          final profile = snapshot.data?.profile ?? widget.initialUser?.profile;
          return Column(
            children: [
              const MeSimpleTopBar(title: '个人资料'),
              Expanded(
                child:
                    snapshot.connectionState == ConnectionState.waiting &&
                        profile == null
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : snapshot.hasError && profile == null
                    ? MeErrorState(
                        message: snapshot.error.toString(),
                        onRetry: () {
                          setState(() => _meFuture = _loadMe());
                        },
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final inset = meContentInset(constraints.maxWidth);
                          return ListView(
                            padding: EdgeInsets.fromLTRB(inset, 4, inset, 34),
                            children: [
                              MeProfileAvatarCard(
                                avatarUrl: profile?.avatarUrl ?? '',
                                pickedAvatar: _pickedAvatar,
                                onTap: _openAvatarActions,
                              ),
                              const SizedBox(height: 16),
                              MeProfileInfoCard(
                                usernameController: _usernameController,
                                showUsernameError:
                                    _usernameTouched && !hasUsername,
                                gender: _gender,
                                birthday: _birthday,
                                onChanged: () => setState(() {}),
                                onGenderChanged: (value) {
                                  setState(() => _gender = value);
                                },
                                onBirthdayTap: _pickBirthday,
                              ),
                              const SizedBox(height: 16),
                              MePrimaryButton(
                                label: '保存修改',
                                loading: _saving,
                                onPressed: _save,
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
