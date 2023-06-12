class Organization {
  int id;
  String? name;
  String? md5AvatarName;
  String? avatarPath;
  String? ex;

  Organization({
    required this.id,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'md5Avatar': md5AvatarName,
      'avatarPath': avatarPath,
      'ex': ex,
    };
  }
}

Organization organizationFromJson(Map<String, dynamic> json) {
  return Organization(id: json['id'])
    ..name = json['name']
    ..md5AvatarName = json['avatar'];
}
