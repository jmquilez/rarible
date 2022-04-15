// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_connect_registry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WcRegImageUrl _$WcRegImageUrlFromJson(Map<String, dynamic> json) =>
    WcRegImageUrl(
      sm: json['sm'] as String? ?? '',
      md: json['md'] as String? ?? '',
      lg: json['lg'] as String? ?? '',
    );

Map<String, dynamic> _$WcRegImageUrlToJson(WcRegImageUrl instance) =>
    <String, dynamic>{
      'sm': instance.sm,
      'md': instance.md,
      'lg': instance.lg,
    };

WcRegApp _$WcRegAppFromJson(Map<String, dynamic> json) => WcRegApp(
      browser: json['browser'] as String? ?? '',
      ios: json['ios'] as String? ?? '',
      android: json['android'] as String? ?? '',
      mac: json['mac'] as String? ?? '',
      windows: json['windows'] as String? ?? '',
      linux: json['linux'] as String? ?? '',
    );

Map<String, dynamic> _$WcRegAppToJson(WcRegApp instance) => <String, dynamic>{
      'browser': instance.browser,
      'ios': instance.ios,
      'android': instance.android,
      'mac': instance.mac,
      'windows': instance.windows,
      'linux': instance.linux,
    };

WcRegDesktop _$WcRegDesktopFromJson(Map<String, dynamic> json) => WcRegDesktop(
      native: json['native'] as String? ?? '',
      universal: json['universal'] as String? ?? '',
    );

Map<String, dynamic> _$WcRegDesktopToJson(WcRegDesktop instance) =>
    <String, dynamic>{
      'native': instance.native,
      'universal': instance.universal,
    };

WcRegMobile _$WcRegMobileFromJson(Map<String, dynamic> json) => WcRegMobile(
      native: json['native'] as String? ?? '',
      universal: json['universal'] as String? ?? '',
    );

Map<String, dynamic> _$WcRegMobileToJson(WcRegMobile instance) =>
    <String, dynamic>{
      'native': instance.native,
      'universal': instance.universal,
    };

WcRegMetadata _$WcRegMetadataFromJson(Map<String, dynamic> json) =>
    WcRegMetadata(
      shortName: json['shortName'] as String? ?? '',
      colors: (json['colors'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$WcRegMetadataToJson(WcRegMetadata instance) =>
    <String, dynamic>{
      'shortName': instance.shortName,
      'colors': instance.colors,
    };

WalletConnectRegistryListing _$WalletConnectRegistryListingFromJson(
        Map<String, dynamic> json) =>
    WalletConnectRegistryListing(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      homepage: json['homepage'] as String? ?? '',
      chains: (json['chains'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      versions: (json['versions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      image_id: json['image_id'] as String? ?? '',
      image_url: json['image_url'] == null
          ? null
          : WcRegImageUrl.fromJson(json['image_url'] as Map<String, dynamic>),
      app: json['app'] == null
          ? null
          : WcRegApp.fromJson(json['app'] as Map<String, dynamic>),
      mobile: json['mobile'] == null
          ? null
          : WcRegMobile.fromJson(json['mobile'] as Map<String, dynamic>),
      desktop: json['desktop'] == null
          ? null
          : WcRegDesktop.fromJson(json['desktop'] as Map<String, dynamic>),
      metadata: json['metadata'] == null
          ? null
          : WcRegMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$WalletConnectRegistryListingToJson(
    WalletConnectRegistryListing instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'name': instance.name,
    'description': instance.description,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('homepage', instance.homepage);
  writeNotNull('chains', instance.chains);
  writeNotNull('versions', instance.versions);
  val['image_id'] = instance.image_id;
  val['image_url'] = instance.image_url;
  val['app'] = instance.app;
  val['mobile'] = instance.mobile;
  val['desktop'] = instance.desktop;
  val['metadata'] = instance.metadata;
  return val;
}
