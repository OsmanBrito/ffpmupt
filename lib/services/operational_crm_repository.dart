import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ffpmupt/models/country.dart';
import 'package:ffpmupt/models/operational_crm.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OperationalCrmRepository {
  OperationalCrmRepository({FirebaseFirestore? firestore})
    : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _database {
    if (_firestore != null) {
      return _firestore;
    }
    if (Firebase.apps.isEmpty) {
      throw StateError('Firebase is not available.');
    }
    return FirebaseFirestore.instance;
  }

  Future<List<CountryOperationalSummary>> loadCountries({
    String? countryCode,
  }) async {
    final countriesSnapshot = countryCode == null
        ? await _database.collection('countries').get()
        : await _database
              .collection('countries')
              .where('code', isEqualTo: countryCode)
              .get();
    final countries =
        countriesSnapshot.docs
            .map((document) => CountryModel.fromMap(document.data()))
            .whereType<CountryModel>()
            .toList()
          ..sort((left, right) => left.name.compareTo(right.name));

    return Future.wait(countries.map(_loadSummary));
  }

  Future<CountryOperationalSummary> _loadSummary(CountryModel country) async {
    final countryRef = _database.collection('countries').doc(country.code);
    final results = await Future.wait([
      countryRef.collection('churches').get(),
      _database
          .collection('users')
          .where('countryCodes', arrayContains: country.code)
          .get(),
      countryRef.collection('promises').where('enabled', isEqualTo: true).get(),
      countryRef.collection('songs').where('enabled', isEqualTo: true).get(),
      countryRef.collection('settings').doc('payments').get(),
      countryRef.collection('settings').doc('weeklyVideos').get(),
      countryRef
          .collection('holyGrounds')
          .where('enabled', isEqualTo: true)
          .get(),
    ]);
    final churches = results[0] as QuerySnapshot<Map<String, dynamic>>;
    final admins = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final promises = results[2] as QuerySnapshot<Map<String, dynamic>>;
    final songs = results[3] as QuerySnapshot<Map<String, dynamic>>;
    final payments = results[4] as DocumentSnapshot<Map<String, dynamic>>;
    final videos = results[5] as DocumentSnapshot<Map<String, dynamic>>;
    final holyGrounds = results[6] as QuerySnapshot<Map<String, dynamic>>;
    final paymentMethods = payments.data()?['methods'];
    final videoData = videos.data();

    return CountryOperationalSummary(
      country: country,
      churchCount: churches.docs
          .where((doc) => doc.data()['enabled'] == true)
          .length,
      adminCount: admins.docs
          .where((doc) => doc.data()['enabled'] == true)
          .length,
      promiseLanguageCount: promises.docs.length,
      songCount: songs.docs.length,
      hasPayments: paymentMethods is List && paymentMethods.isNotEmpty,
      hasWeeklyVideos:
          videoData != null &&
          (videoData['youtube'] is Map || videoData['vimeo'] is Map),
      holyGroundCount: holyGrounds.docs.length,
    );
  }

  Stream<List<LocalChurch>> watchChurches(String countryCode) {
    return _database
        .collection('countries')
        .doc(countryCode)
        .collection('churches')
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) =>
                    LocalChurch.fromMap(id: document.id, map: document.data()),
              )
              .whereType<LocalChurch>()
              .toList(),
        );
  }

  Future<void> saveChurch(String countryCode, LocalChurch church) async {
    final collection = _database
        .collection('countries')
        .doc(countryCode)
        .collection('churches');
    final document = church.id.isEmpty
        ? collection.doc()
        : collection.doc(church.id);
    final existing = await document.get();
    await document.set({
      ...church.toMap(),
      if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<AdminProfile>> watchAdmins() {
    return _database
        .collection('users')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (document) => AdminProfile.fromMap(
                      uid: document.id,
                      map: document.data(),
                    ),
                  )
                  .whereType<AdminProfile>()
                  .toList()
                ..sort((left, right) {
                  final leftLabel = left.displayName.isEmpty
                      ? left.email
                      : left.displayName;
                  final rightLabel = right.displayName.isEmpty
                      ? right.email
                      : right.displayName;
                  return leftLabel.compareTo(rightLabel);
                }),
        );
  }

  Future<void> saveCountryAdmin(AdminProfile profile) async {
    if (profile.role != 'admin') {
      throw ArgumentError('Only country administrators can be saved here.');
    }
    final document = _database.collection('users').doc(profile.uid);
    final existing = await document.get();
    await document.set({
      ...profile.toMap(),
      if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<AdminInvite> createAdminInvite({
    required String email,
    required String displayName,
    required String countryCode,
    required String createdBy,
  }) async {
    final document = _database.collection('adminInvites').doc();
    final invite = AdminInvite(
      id: document.id,
      email: email.trim().toLowerCase(),
      displayName: displayName.trim(),
      countryCodes: [countryCode],
      createdBy: createdBy,
      expiresAt: DateTime.now().toUtc().add(const Duration(days: 7)),
      enabled: true,
      acceptedBy: '',
    );
    await document.set({
      ...invite.toMap(),
      'expiresAt': Timestamp.fromDate(invite.expiresAt),
      'createdAt': FieldValue.serverTimestamp(),
      'acceptedAt': null,
    });
    return invite;
  }

  Stream<List<AdminInvite>> watchInvites(String countryCode) {
    return _database
        .collection('adminInvites')
        .where('countryCodes', arrayContains: countryCode)
        .snapshots()
        .map((snapshot) {
          final invites =
              snapshot.docs
                  .map((document) {
                    final data = Map<String, Object?>.from(document.data());
                    final expiresAt = data['expiresAt'];
                    data['expiresAt'] = expiresAt is Timestamp
                        ? expiresAt.toDate()
                        : expiresAt;
                    return AdminInvite.fromMap(id: document.id, map: data);
                  })
                  .whereType<AdminInvite>()
                  .toList()
                ..sort(
                  (left, right) => right.expiresAt.compareTo(left.expiresAt),
                );
          return invites;
        });
  }

  Future<void> cancelInvite(String inviteId) {
    return _database.collection('adminInvites').doc(inviteId).update({
      'enabled': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<AdminInvite> loadInviteForUser(String inviteId) async {
    final snapshot = await _database
        .collection('adminInvites')
        .doc(inviteId)
        .get();
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Convite não encontrado.');
    }
    final converted = Map<String, Object?>.from(data);
    final expiresAt = converted['expiresAt'];
    converted['expiresAt'] = expiresAt is Timestamp
        ? expiresAt.toDate()
        : expiresAt;
    final invite = AdminInvite.fromMap(id: snapshot.id, map: converted);
    if (invite == null) {
      throw StateError('Convite inválido.');
    }
    return invite;
  }

  Future<void> acceptInvite({
    required AdminInvite invite,
    required User user,
  }) async {
    final userEmail = user.email?.trim().toLowerCase();
    if (!user.emailVerified) {
      throw StateError('Confirme o email antes de aceitar o convite.');
    }
    if (userEmail == null || userEmail != invite.email) {
      throw StateError('O email da conta não corresponde ao convite.');
    }

    final inviteRef = _database.collection('adminInvites').doc(invite.id);
    final userRef = _database.collection('users').doc(user.uid);
    await _database.runTransaction((transaction) async {
      final currentInviteSnapshot = await transaction.get(inviteRef);
      final currentInviteData = currentInviteSnapshot.data();
      if (currentInviteData == null ||
          currentInviteData['enabled'] != true ||
          currentInviteData['acceptedBy'] != '') {
        throw StateError('Este convite já foi utilizado ou cancelado.');
      }
      final expiresAt = currentInviteData['expiresAt'];
      if (expiresAt is! Timestamp ||
          expiresAt.toDate().isBefore(DateTime.now())) {
        throw StateError('Este convite expirou.');
      }

      final currentUserSnapshot = await transaction.get(userRef);
      final currentUserData = currentUserSnapshot.data();
      final existingCountries = currentUserData?['countryCodes'];
      final countries = {
        if (existingCountries is List) ...existingCountries.whereType<String>(),
        ...invite.countryCodes,
      }.toList()..sort();

      transaction.set(userRef, {
        'email': invite.email,
        'displayName': invite.displayName,
        'role': 'admin',
        'enabled': true,
        'countryCodes': countries,
        'lastInviteId': invite.id,
        if (!currentUserSnapshot.exists)
          'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      transaction.update(inviteRef, {
        'enabled': false,
        'acceptedBy': user.uid,
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
