class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.companyId,
    required this.departmentId,
    required this.jobRoleId,
    required this.jobRoleName,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String companyId;
  final String departmentId;
  final String jobRoleId;
  final String jobRoleName;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      companyId: json['companyId']?.toString() ?? '',
      departmentId: json['departmentId']?.toString() ?? '',
      jobRoleId: json['jobRoleId']?.toString() ?? '',
      jobRoleName: json['jobRoleName']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'companyId': companyId,
      'departmentId': departmentId,
      'jobRoleId': jobRoleId,
      'jobRoleName': jobRoleName,
    };
  }
}

class UserSession {
  const UserSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final AppUser user;

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      user: AppUser.fromJson((json['user'] as Map?)?.cast<String, dynamic>() ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'user': user.toJson(),
    };
  }
}

class DashboardStats {
  const DashboardStats({
    required this.totalTramites,
    required this.totalWorkflows,
    required this.totalUsers,
    required this.byStatus,
  });

  final int totalTramites;
  final int totalWorkflows;
  final int totalUsers;
  final Map<String, int> byStatus;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['byStatus'] as Map?)?.cast<String, dynamic>() ?? {};
    return DashboardStats(
      totalTramites: (json['totalTramites'] as num?)?.toInt() ?? 0,
      totalWorkflows: (json['totalWorkflows'] as num?)?.toInt() ?? 0,
      totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
      byStatus: rawStatus.map(
        (key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0),
      ),
    );
  }
}

class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.action,
    required this.stageName,
    required this.departmentName,
    required this.jobRoleName,
    required this.comment,
    required this.changedAt,
    required this.isCurrent,
  });

  final String id;
  final String action;
  final String stageName;
  final String departmentName;
  final String jobRoleName;
  final String comment;
  final DateTime? changedAt;
  final bool isCurrent;

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      final raw = value?.toString();
      if (raw == null || raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    }

    return HistoryEntry(
      id: json['id']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      stageName: json['stageName']?.toString() ?? json['nodoName']?.toString() ?? '',
      departmentName: json['departmentName']?.toString() ?? '',
      jobRoleName: json['jobRoleName']?.toString() ?? '',
      comment: json['comment']?.toString() ?? '',
      changedAt: parseDate(json['changedAt']),
      isCurrent: json['isCurrent'] == true,
    );
  }
}

class TramiteDetail {
  const TramiteDetail({
    required this.id,
    required this.code,
    required this.title,
    required this.status,
    required this.history,
  });

  final String id;
  final String code;
  final String title;
  final String status;
  final List<HistoryEntry> history;

  factory TramiteDetail.fromJson(Map<String, dynamic> json) {
    final rawHistory = (json['history'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return TramiteDetail(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      history: rawHistory.map(HistoryEntry.fromJson).toList(),
    );
  }
}

class TramiteItem {
  const TramiteItem({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.clientName,
    required this.requestType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String code;
  final String title;
  final String description;
  final String clientName;
  final String requestType;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory TramiteItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      final raw = value?.toString();
      if (raw == null || raw.isEmpty) {
        return null;
      }
      return DateTime.tryParse(raw);
    }

    return TramiteItem(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      clientName: json['clientName']?.toString() ?? json['requestedByName']?.toString() ?? '',
      requestType: json['requestType']?.toString() ?? json['workflowName']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }
}
