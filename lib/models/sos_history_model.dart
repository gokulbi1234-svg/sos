class SOSHistory {
  final String action;   // "SMS" or "CALL"
  final String location;
  final DateTime time;

  SOSHistory({
    required this.action,
    required this.location,
    required this.time,
  });
}