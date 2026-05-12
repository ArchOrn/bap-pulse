/// The currently authenticated user's editable account record, sourced from
/// `GET /users/:id`. Nullable fields are the optional ones the admin BO sets
/// later (gender, ffbad rank, nickname).
class Account {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? nickname;
  final String? gender; // "MALE" | "FEMALE" | null
  final String? ffbadRank; // "NC" | "P12" | ... | "N1" | null

  const Account({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.nickname,
    required this.gender,
    required this.ffbadRank,
  });

  Account copyWith({String? nickname}) => Account(
        id: id,
        email: email,
        firstName: firstName,
        lastName: lastName,
        nickname: nickname,
        gender: gender,
        ffbadRank: ffbadRank,
      );

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] as String,
        email: json['email'] as String,
        firstName: json['first_name'] as String,
        lastName: json['last_name'] as String,
        nickname: json['nickname'] as String?,
        gender: json['gender'] as String?,
        ffbadRank: json['ffbad_rank'] as String?,
      );
}
