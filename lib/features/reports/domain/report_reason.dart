class ReportReasonOption {
  final String value;
  final String label;

  const ReportReasonOption(this.value, this.label);
}

const List<ReportReasonOption> reportReasons = [
  ReportReasonOption('spam', 'Spamo'),
  ReportReasonOption('harassment', 'Ĉikanado'),
  ReportReasonOption('hate', 'Malama parolo'),
  ReportReasonOption('nudity', 'Seksa enhavo'),
  ReportReasonOption('violence', 'Perforto'),
  ReportReasonOption('misinformation', 'Misinformo'),
  ReportReasonOption('other', 'Alia'),
];
