/// 로컬 데이터 소스 아웃바운드 포트 (Infrastructure 내부 Secondary Port)
///
/// [DiaryRepositoryAdapter]가 실제 데이터 소스 구현(SQLite 등)에
/// 직접 의존하지 않도록 추상화한다.
/// Infrastructure 레이어 내부에서 Adapter → DataSource 의존을
/// 역전시키기 위한 포트다.
abstract interface class DiaryDataSourcePort {
    /// [map]의 일기 데이터를 삽입한다.
    Future<void> insert(Map<String, dynamic> map);

    /// [map]의 일기 데이터를 수정한다.
    Future<void> update(Map<String, dynamic> map);

    /// 'yyyy-MM-dd' 형식의 [date]에 해당하는 행을 반환한다. 없으면 null.
    Future<Map<String, dynamic>?> queryByDate(String date);

    /// [year]년 [month]월의 모든 행을 반환한다.
    Future<List<Map<String, dynamic>>> queryByMonth(int year, int month);
}
