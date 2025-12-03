class AttendanceModel {
  final String date; // yyyy-MM-dd
  final String? checkIn; // ISO or readable string
  final String? checkOut;

  AttendanceModel({
    required this.date,
    this.checkIn,
    this.checkOut,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> m) => AttendanceModel(
        date: m['date'] as String,
        checkIn: m['checkIn'] as String?,
        checkOut: m['checkOut'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'date': date,
        'checkIn': checkIn,
        'checkOut': checkOut,
      };

  AttendanceModel copyWith({String? checkIn, String? checkOut}) => AttendanceModel(
        date: date,
        checkIn: checkIn ?? this.checkIn,
        checkOut: checkOut ?? this.checkOut,
      );
}
