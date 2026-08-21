import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import 'me_common_widgets.dart';

class MeAvatar extends StatelessWidget {
  const MeAvatar({
    super.key,
    required this.avatarUrl,
    required this.size,
    this.pickedAvatar,
    this.editable = false,
  });

  final String avatarUrl;
  final double size;
  final XFile? pickedAvatar;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final ImageProvider<Object> provider = switch ((pickedAvatar, avatarUrl)) {
      (final XFile file?, _) => FileImage(File(file.path)),
      (_, final String url) when url.isNotEmpty => NetworkImage(url),
      _ => const AssetImage('assets/common/default_avatar.png'),
    };

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFE3E6E7),
                shape: BoxShape.circle,
                image: DecorationImage(image: provider, fit: BoxFit.cover),
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
          if (editable)
            Positioned(
              right: 0,
              bottom: size * 0.1,
              child: Container(
                width: 27,
                height: 27,
                decoration: BoxDecoration(
                  color: meTeal,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.photo_camera_outlined,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MeProfileAvatarCard extends StatelessWidget {
  const MeProfileAvatarCard({
    super.key,
    required this.avatarUrl,
    required this.pickedAvatar,
    required this.onTap,
  });

  final String avatarUrl;
  final XFile? pickedAvatar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: MeCard(
        height: 160,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MeAvatar(
              avatarUrl: avatarUrl,
              pickedAvatar: pickedAvatar,
              size: 78,
              editable: true,
            ),
            const SizedBox(height: 12),
            const Text(
              '点击修改头像',
              style: TextStyle(
                color: meTeal,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MeProfileInfoCard extends StatelessWidget {
  const MeProfileInfoCard({
    super.key,
    required this.usernameController,
    required this.showUsernameError,
    required this.gender,
    required this.birthday,
    required this.onChanged,
    required this.onGenderChanged,
    required this.onBirthdayTap,
  });

  final TextEditingController usernameController;
  final bool showUsernameError;
  final String gender;
  final String birthday;
  final VoidCallback onChanged;
  final ValueChanged<String> onGenderChanged;
  final VoidCallback onBirthdayTap;

  @override
  Widget build(BuildContext context) {
    return MeCard(
      child: Column(
        children: [
          SizedBox(
            height: 52,
            child: Row(
              children: [
                const SizedBox(width: 16),
                const SizedBox(width: 78, child: _ProfileLabel('用户名')),
                Expanded(
                  child: TextField(
                    controller: usernameController,
                    onChanged: (_) => onChanged(),
                    textAlign: TextAlign.right,
                    maxLength: 32,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    decoration: InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorText: showUsernameError ? '' : null,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(
                      color: Color(0xFF666E72),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
          const MeHorizontalDivider(),
          SizedBox(
            height: 52,
            child: Row(
              children: [
                const SizedBox(width: 16),
                const Expanded(child: _ProfileLabel('性别')),
                _GenderPill(
                  label: '男',
                  selected: gender == 'male',
                  onTap: () => onGenderChanged('male'),
                ),
                const SizedBox(width: 8),
                _GenderPill(
                  label: '女',
                  selected: gender == 'female',
                  onTap: () => onGenderChanged('female'),
                ),
                const SizedBox(width: 8),
                _GenderPill(
                  label: '保密',
                  selected: gender == 'private' || gender.isEmpty,
                  onTap: () => onGenderChanged('private'),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
          const MeHorizontalDivider(),
          InkWell(
            onTap: onBirthdayTap,
            child: SizedBox(
              height: 52,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Expanded(child: _ProfileLabel('生日')),
                  Text(
                    birthday.isEmpty ? '未设置' : birthday,
                    style: TextStyle(
                      color: birthday.isEmpty
                          ? const Color(0xFFC4CECC)
                          : const Color(0xFF666E72),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileLabel extends StatelessWidget {
  const _ProfileLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: meText,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _GenderPill extends StatelessWidget {
  const _GenderPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? meTeal : const Color(0xFFF4F6F7),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF6D777B),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

MultipartFilePart avatarPart(XFile file) {
  final extension = file.path.split('.').last.toLowerCase();
  final contentType = switch (extension) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'heic' || 'heif' => 'image/heic',
    _ => 'image/jpeg',
  };
  return MultipartFilePart(
    fieldName: 'avatar',
    fileName: file.name,
    contentType: contentType,
    bytes: file.readAsBytes().then((bytes) => bytes.toList()),
  );
}
