class SurveyData {
  String userName;
  String? selectedReason; // brain_training, travel, job, others
  String? selectedDuration; // 5min, 10min, 20min
  String? selectedLevel; // a_help, a_me

  SurveyData({
    required this.userName,
    this.selectedReason,
    this.selectedDuration,
    this.selectedLevel,
  });

  bool get isComplete =>
      userName.isNotEmpty &&
      selectedReason != null &&
      selectedDuration != null &&
      selectedLevel != null;
}

class ReasonOption {
  final String id;
  final String titleEn;
  final String titleVi;
  final String icon; // Emoji or asset path

  ReasonOption({
    required this.id,
    required this.titleEn,
    required this.titleVi,
    required this.icon,
  });
}

class DurationOption {
  final String id;
  final String titleEn;
  final String titleVi;

  DurationOption({
    required this.id,
    required this.titleEn,
    required this.titleVi,
  });
}

class LevelOption {
  final String id;
  final String titleEn;
  final String titleVi;

  LevelOption({
    required this.id,
    required this.titleEn,
    required this.titleVi,
  });
}
