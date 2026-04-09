import 'package:maeum_diary/infrastructure/port/diary_data_source_port.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// [DiaryDataSourcePort]의 SQLite 어댑터 구현체
///
/// 싱글턴 패턴으로 앱 전체에서 단일 DB 인스턴스를 공유한다.
final class DiaryLocalDataSource implements DiaryDataSourcePort {
  static const String _dbName = 'maeum_diary.db';
  // v3: activities 컬럼 추가 (오늘 한 일)
  static const int _dbVersion = 3;
  static const String _tableName = 'diary_entries';

  static DiaryLocalDataSource? _instance;
  Database? _db;

  DiaryLocalDataSource._();

  static DiaryLocalDataSource get instance {
    _instance ??= DiaryLocalDataSource._();
    return _instance!;
  }

  /// 데이터베이스 연결을 반환한다. 필요 시 초기화한다.
  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
            CREATE TABLE $_tableName (
                id         TEXT PRIMARY KEY,
                date       TEXT NOT NULL UNIQUE,
                emotions   TEXT NOT NULL,
                activities TEXT NOT NULL DEFAULT '[]',
                memo       TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
            )
        ''');
    await db.execute('CREATE INDEX idx_diary_date ON $_tableName (date)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 기존 테이블을 삭제하고 새로 생성해 오염된 데이터를 초기화한다.
    // 실제 서비스에서는 ALTER TABLE 등 데이터 보존 마이그레이션을 사용한다.
    await db.execute('DROP TABLE IF EXISTS $_tableName');
    await _onCreate(db, newVersion);
  }

  // ─── CRUD ────────────────────────────────────────────────────────────────

  /// 일기를 삽입한다.
  @override
  Future<void> insert(Map<String, dynamic> map) async {
    final db = await database;
    await db.insert(_tableName, map, conflictAlgorithm: ConflictAlgorithm.fail);
  }

  /// 기존 일기를 수정한다.
  @override
  Future<void> update(Map<String, dynamic> map) async {
    final db = await database;
    await db.update(_tableName, map, where: 'id = ?', whereArgs: [map['id']]);
  }

  /// 'yyyy-MM-dd' 형식의 [date]에 해당하는 일기를 조회한다.
  @override
  Future<Map<String, dynamic>?> queryByDate(String date) async {
    final db = await database;
    final rows = await db.query(
      _tableName,
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  /// [year]년 [month]월의 모든 일기를 조회한다.
  @override
  Future<List<Map<String, dynamic>>> queryByMonth(int year, int month) async {
    final db = await database;
    final prefix =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
    return db.query(
      _tableName,
      where: 'date LIKE ?',
      whereArgs: ['$prefix-%'],
      orderBy: 'date ASC',
    );
  }

  /// 테스트 등에서 DB를 닫을 때 사용한다.
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
