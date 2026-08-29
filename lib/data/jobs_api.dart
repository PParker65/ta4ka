import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../domain/work_map.dart';
import 'dto/job_dto.dart';

abstract class JobsApi {
  Future<JobDto> create(JobCreateRequest request);
  Future<List<JobDto>> list();
  Future<JobDto> getById(String id);
  Future<void> cancel(String id);
}

class RemoteJobsApi implements JobsApi {
  RemoteJobsApi(this._client);

  final ApiClient _client;

  @override
  Future<JobDto> create(JobCreateRequest request) async {
    final response = await _client.raw.post<Map<String, dynamic>>(
      '/v1/jobs',
      data: request.toJson(),
    );
    return JobDto.fromJson(response.data!);
  }

  @override
  Future<List<JobDto>> list() async {
    final response = await _client.raw.get<Map<String, dynamic>>('/v1/jobs');
    final items = response.data?['items'] as List<dynamic>? ?? [];
    return [
      for (final item in items) JobDto.fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<JobDto> getById(String id) async {
    final response = await _client.raw.get<Map<String, dynamic>>('/v1/jobs/$id');
    return JobDto.fromJson(response.data!);
  }

  @override
  Future<void> cancel(String id) async {
    await _client.raw.post<void>('/v1/jobs/$id/cancel');
  }
}

class MockJobsApi implements JobsApi {
  MockJobsApi();

  final Map<String, JobDto> _jobs = {};

  @override
  Future<JobDto> create(JobCreateRequest request) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final workId = workIdFor(want: request.wantId, symptom: request.symptomId);
    final job = JobDto(
      id: id,
      shopId: request.shopId,
      plate: request.plate,
      brand: request.brand,
      model: request.model,
      year: request.year,
      symptomId: request.symptomId,
      wantId: request.wantId,
      workId: workId,
      tier: request.tier,
      priceUah: 0,
      minutes: 0,
      status: 'booked',
      isEmergency: isEmergencySymptom(request.symptomId),
      createdAt: DateTime.now().toUtc(),
    );
    _jobs[id] = job;
    return job;
  }

  @override
  Future<List<JobDto>> list() async {
    final items = _jobs.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  @override
  Future<JobDto> getById(String id) async {
    final job = _jobs[id];
    if (job == null) {
      throw DioException(
        requestOptions: RequestOptions(path: '/v1/jobs/$id'),
        message: 'NOT_FOUND',
      );
    }
    return job;
  }

  @override
  Future<void> cancel(String id) async {
    final job = _jobs[id];
    if (job == null) {
      return;
    }
    _jobs[id] = JobDto(
      id: job.id,
      shopId: job.shopId,
      plate: job.plate,
      brand: job.brand,
      model: job.model,
      year: job.year,
      symptomId: job.symptomId,
      wantId: job.wantId,
      workId: job.workId,
      tier: job.tier,
      priceUah: job.priceUah,
      minutes: job.minutes,
      status: 'cancelled',
      isEmergency: job.isEmergency,
      createdAt: job.createdAt,
    );
  }
}

JobsApi createJobsApi(ApiClient client) {
  if (client.isConfigured) {
    return RemoteJobsApi(client);
  }
  return MockJobsApi();
}
