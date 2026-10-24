import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/model_parsing.dart';
import '../model/report.dart';

class ReportRepository {
  ReportRepository(this._client);

  final SupabaseClient _client;

  Future<List<ReportCategoryStatus>> getCategories(String farmId) async {
    final rows = await _client
        .from('report_category_status')
        .select()
        .eq('farm_id', farmId)
        .order('sort_order');
    return List<JsonRow>.from(rows).map(ReportCategoryStatus.fromJson).toList();
  }

  Future<ReportRecord> generate({
    required String farmId,
    required String categoryCode,
    String? periodStart,
    String? periodEnd,
  }) async {
    final response = await _client.rpc(
      'generate_report',
      params: {
        'p_farm_id': farmId,
        'p_category': categoryCode,
        if (periodStart != null) 'p_period_start': periodStart,
        if (periodEnd != null) 'p_period_end': periodEnd,
      },
    );
    if (response is Map) {
      return ReportRecord.fromJson(Map<String, dynamic>.from(response));
    }
    if (response is List && response.isNotEmpty && response.first is Map) {
      return ReportRecord.fromJson(
        Map<String, dynamic>.from(response.first as Map),
      );
    }
    throw StateError('The report procedure returned no report record.');
  }

  Future<ReportRecord> getReport(String reportId) async {
    final row = await _client
        .from('report')
        .select()
        .eq('report_id', reportId)
        .single();
    return ReportRecord.fromJson(Map<String, dynamic>.from(row));
  }

  Future<List<ReportRecord>> getHistory({
    required String farmId,
    required String categoryId,
    int limit = 20,
  }) async {
    if (limit < 1) throw ArgumentError.value(limit, 'limit');
    final rows = await _client
        .from('report')
        .select()
        .eq('farm_id', farmId)
        .eq('category_id', categoryId)
        .order('generated_at', ascending: false)
        .limit(limit);
    return List<JsonRow>.from(rows).map(ReportRecord.fromJson).toList();
  }

  Future<ReportSummary> getSummary(
    String reportId, {
    required String categoryCode,
  }) async {
    final record = await getReport(reportId);
    return ReportSummary.fromJson(categoryCode, record.summary);
  }
}
