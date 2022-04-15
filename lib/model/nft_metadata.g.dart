// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nft_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NftCreator _$NftCreatorFromJson(Map<String, dynamic> json) => NftCreator(
      address: json['address'] as String,
      value: json['value'] as int? ?? 10000,
    );

Map<String, dynamic> _$NftCreatorToJson(NftCreator instance) =>
    <String, dynamic>{
      'address': instance.address,
      'value': instance.value,
    };

NftRoyalty _$NftRoyaltyFromJson(Map<String, dynamic> json) => NftRoyalty(
      address: json['address'] as String,
      value: json['value'] as int? ?? 5000,
    );

Map<String, dynamic> _$NftRoyaltyToJson(NftRoyalty instance) =>
    <String, dynamic>{
      'address': instance.address,
      'value': instance.value,
    };

NftAttribute _$NftAttributeFromJson(Map<String, dynamic> json) => NftAttribute(
      key: json['key'] as String?,
      traitType: json['trait_type'] as String,
      value: json['value'] as String,
      displayType: json['display_type'] as String?,
    );

Map<String, dynamic> _$NftAttributeToJson(NftAttribute instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('key', instance.key);
  val['trait_type'] = instance.traitType;
  val['value'] = instance.value;
  writeNotNull('display_type', instance.displayType);
  return val;
}

NftIpfsMetadata _$NftIpfsMetadataFromJson(Map<String, dynamic> json) =>
    NftIpfsMetadata(
      name: json['name'] as String,
      image: json['image'] as String,
      description: json['description'] as String?,
      externalUrl: json['external_url'] as String?,
      animationUrl: json['animation_url'] as String?,
      backgroundColor: json['background_color'] as String?,
      attributes: (json['attributes'] as List<dynamic>?)
          ?.map((e) => NftAttribute.fromJson(e as Map<String, dynamic>))
          .toList(),
      youtubeUrl: json['youtube_url'] as String?,
    )..imageData = json['image_data'] as String?;

Map<String, dynamic> _$NftIpfsMetadataToJson(NftIpfsMetadata instance) {
  final val = <String, dynamic>{
    'name': instance.name,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('description', instance.description);
  val['image'] = instance.image;
  writeNotNull('image_data', instance.imageData);
  writeNotNull('external_url', instance.externalUrl);
  writeNotNull('animation_url', instance.animationUrl);
  writeNotNull('youtube_url', instance.youtubeUrl);
  writeNotNull('background_color', instance.backgroundColor);
  writeNotNull('attributes', instance.attributes);
  return val;
}

BlockchainAddress _$BlockchainAddressFromJson(Map<String, dynamic> json) =>
    BlockchainAddress(
      address: json['address'] as String,
      blockchain: json['blockchain'] as String,
    );

Map<String, dynamic> _$BlockchainAddressToJson(BlockchainAddress instance) =>
    <String, dynamic>{
      'blockchain': instance.blockchain,
      'address': instance.address,
    };

Item _$ItemFromJson(Map<String, dynamic> json) => Item(
      json['id'] as String,
      json['blockchain'] as String,
      json['collection'] as String,
      json['contract'] as String,
      json['tokenId'] as String,
      (json['creators'] as List<dynamic>)
          .map((e) => NftCreator.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['owners'] as List<dynamic>)
          .map((e) => NftCreator.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['royalties'] as List<dynamic>)
          .map((e) => NftRoyalty.fromJson(e as Map<String, dynamic>))
          .toList(),
      json['lazySupply'] as String?,
      json['pending'] as List<dynamic>,
      json['deleted'] as bool,
      json['auctions'] as List<dynamic>,
      json['totalStock'] as String,
      json['sellers'] as int,
    );

Map<String, dynamic> _$ItemToJson(Item instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'blockchain': instance.blockchain,
    'collection': instance.collection,
    'contract': instance.contract,
    'tokenId': instance.tokenId,
    'creators': instance.creators,
    'owners': instance.owners,
    'royalties': instance.royalties,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('lazySupply', instance.lazySupply);
  val['pending'] = instance.pending;
  val['deleted'] = instance.deleted;
  val['auctions'] = instance.auctions;
  val['totalStock'] = instance.totalStock;
  val['sellers'] = instance.sellers;
  return val;
}
