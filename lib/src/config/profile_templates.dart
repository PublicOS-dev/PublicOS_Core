import 'dart:math';
import 'package:flutter/material.dart';
import 'package:publicos_core/src/models/record_model.dart';

/// Profile templates for testing purposes.
/// Contains hardcoded profile data used for development and testing.
class ProfileTemplates {
  static final _random = Random();

  /// Get profile records for a given username
  static List<Record> getProfileRecords(String username) {
    final expirationDate = Record.never;

    if (username.startsWith("jmsl")) {
      return _getJmslProfile(expirationDate);
    } else if (username.startsWith("prsl")) {
      return _getPrslProfile(expirationDate);
    } else {
      return _getDefaultProfile(expirationDate);
    }
  }

  /// JMSL profile template
  static List<Record> _getJmslProfile(DateTime expirationDate) {
    return [
      // Identity
      Record.asProfile(
        key: 'profile.avatar',
        value: 'https://pbs.twimg.com/profile_images/1874553021688123393/F1qTyZj5_400x400.jpg',
        expiration: expirationDate,
      ),
      Record.asProfile(
        key: 'profile.banner',
        value: 'https://feeds.publicos.dev/media/0fb9b500.1794777689.png',
        expiration: expirationDate,
      ),
      Record.asProfile(
        key: 'profile.color',
        value: const Color.fromARGB(255, 21, 66, 145).value.toString(),
        expiration: expirationDate,
      ),
      // Bio
      Record.asProfile(
        key: "profile.bio",
        value: """Engineer/Dev/Web3/ Daily Life

Failing constantly towards my goals""",
        expiration: expirationDate,
        customMetadataAttributes: {
          'bioTextColor': Colors.white.value,
          'bioBorderVisible': false,
          'bioBorderColor': Colors.grey.shade300.value,
          'bioBorderWidth': 1.0,
          'borderRadius': 8.0,
        },
        alignment: 'left',
      ),
      // Social links
      Record.asProfile(
        key: "com.twitter",
        value: "jmsl.xyz",
        expiration: expirationDate,
        link: "https://x.com/0xjmsl",
        color: const Color.fromARGB(255, 25, 55, 107).withOpacity(.3),
        alignment: 'center',
        customMetadataAttributes: {'name': 'Twitter'},
      ),
      Record.asProfile(
        key: "com.instagram",
        value: "jmslxyz",
        expiration: expirationDate,
        link: "https://www.instagram.com/jmslxyz/",
        color: const Color.fromARGB(255, 25, 55, 107).withOpacity(.3),
        alignment: 'center',
        customMetadataAttributes: {'name': 'Instagram'},
      ),
      Record.asProfile(
        key: "com.github",
        value: "0xjmsl",
        expiration: expirationDate,
        link: "https://github.com/0xjmsl",
        color: const Color.fromARGB(255, 25, 55, 107).withOpacity(.3),
        alignment: 'center',
        customMetadataAttributes: {'name': 'GitHub'},
      ),
      // Tabs (router records)
      Record.asRouter(
        key: "personal",
        value: "https://jmsl.xyz",
        name: "My site",
        routerSubtype: RouterSubtype.tab,
      ),
      Record.asRouter(
        key: "tnmt",
        value: "https://thenftmonkeytheorem.io/",
        name: "TnmT",
        routerSubtype: RouterSubtype.tab,
      ),
    ];
  }

  /// PRSL profile template
  static List<Record> _getPrslProfile(DateTime expirationDate) {
    return [
      // Identity
      Record.asProfile(
        key: 'profile.avatar',
        value: 'https://pbs.twimg.com/profile_images/1878201385550065664/5ga9xyx6_400x400.png',
        expiration: expirationDate,
      ),
      Record.asProfile(
        key: 'profile.banner',
        value: 'https://pbs.twimg.com/profile_banners/1463014810124111875/1736633081/1500x500',
        expiration: expirationDate,
      ),
      Record.asProfile(
        key: 'profile.color',
        value: Colors.green.shade400.value.toString(),
        expiration: expirationDate,
      ),
      // Bio
      Record.asProfile(
        key: "profile.bio",
        value: """"To develop foresight, you need to practice hindsight"
        My thoughts & opinions shall never be taken seriously as life advice.
        NFA""",
        expiration: expirationDate,
        customMetadataAttributes: {
          'bioTextColor': Colors.white.value,
          'bioBorderVisible': false,
          'bioBorderColor': Colors.grey.shade300.value,
          'bioBorderWidth': 1.0,
          'borderRadius': 8.0,
        },
        alignment: 'left',
      ),
      // Social links
      Record.asProfile(
        key: "com.twitter",
        value: "@Szera",
        link: "https://x.com/Szera",
        color: Colors.blueAccent.shade400.withOpacity(.3),
        expiration: expirationDate,
        alignment: 'left',
        customMetadataAttributes: {'name': 'Twitter'},
      ),
      Record.asProfile(
        key: "com.instagram",
        value: "peterszera",
        link: "https://www.instagram.com/peterszera/",
        color: Colors.blueAccent.shade400.withOpacity(.3),
        expiration: expirationDate,
        alignment: 'left',
        customMetadataAttributes: {'name': 'Instagram'},
      ),
      // Tabs (router records)
      Record.asRouter(
        key: "portfolio",
        value: "https://peterszera.com",
        name: "My Work",
        routerSubtype: RouterSubtype.tab,
      ),
      Record.asRouter(
        key: "contact",
        value: "https://peterszera.com/",
        name: "Get In Touch",
        routerSubtype: RouterSubtype.tab,
      ),
    ];
  }

  /// Default profile template
  static List<Record> _getDefaultProfile(DateTime expirationDate) {
    return [
      Record.asProfile(
        key: 'profile.color',
        value: Colors.primaries[_random.nextInt(Colors.primaries.length)].value.toString(),
        expiration: expirationDate,
      ),
      Record.asProfile(
        key: 'profile.avatar',
        value: 'https://feeds.publicos.dev/media/4c12b94b.1794777687.png',
        expiration: expirationDate,
      ),
      Record.asProfile(
        key: 'profile.banner',
        value: 'https://feeds.publicos.dev/media/a2239444.1794777687.png',
        expiration: expirationDate,
      ),
      Record.asProfile(
        key: "profile.bio",
        value: "Welcome to PublicOS! This is your space to connect and share.",
        expiration: expirationDate,
        customMetadataAttributes: {
          'bioTextColor': Colors.white.value,
          'bioBorderVisible': false,
          'bioBorderColor': Colors.grey.shade300.value,
          'bioBorderWidth': 1.0,
          'borderRadius': 8.0,
        },
        alignment: 'left',
      ),
    ];
  }
}
