import 'package:open_chat/models/organization.dart';
import 'package:sqlite3/sqlite3.dart';

/// 插入对应的属性和数据
/// attribute 需要插入的属性
/// 对应的值
/// 检测冲突的值
/// 如果冲突，需要更新的值
void updateOrganization(List<Organization> valueSet) {
  final db = sqlite3.open('./lib/store/db/general.db');
  final stmt = db.prepare(
      'INSERT OR REPLACE INTO organization (id, name, md5_avatar, avatar_path,ex) VALUES (?,?,?,?,?) ');
  for (var element in valueSet) {
    var json = element.toJson();
    stmt.execute([
      json['id'],
      json['name'],
      json['md5Avatar'],
      json['avatarPath'],
      json['ex'],
    ]);
  }
}

void updateUserName(int id, String newName) async {
  final db = sqlite3.open('./lib/store/db/general.db');
  final stmt = db.prepare('UPDATE organization SET name=? WHERE id=?;');
  stmt.execute([newName, id]);
  stmt.dispose();
  db.dispose();
}

void main() {
  updateUserName(100000001, '怪小叔_Mggt');
}
