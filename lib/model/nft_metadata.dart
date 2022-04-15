import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'nft_metadata.g.dart';

///
/// Rarible Models
///

/// To rebuild JSON annotation run
/// flutter pub run build_runner build --delete-conflicting-outputs

/// NFT Creator Part
/// [address] Creator account - will need to sign/approvals
/// [value] Values are specified in basis points. For example, 2000 means 20%.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class NftCreator {
  String address;
  int value;

  NftCreator({required this.address, this.value = 10000});

  factory NftCreator.fromJson(Map<String, dynamic> json) {
    // As usual Rarible has a slightly different implementation on their Items controller
    if (json.containsKey('account') && (!json.containsKey('address'))) {
      if (kDebugMode) {
        print('setting address to the same as account for Items parsing.');
      }
      json['address'] = json['account'];
    }
    return _$NftCreatorFromJson(json);
  }
  Map<String, dynamic> toJson() => _$NftCreatorToJson(this);
}

/// NFT Royalty Part
///
/// [address] Payable account
/// [value] Values are specified in basis points. For example, 2000 means 20%.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class NftRoyalty {
  String address;
  int value;

  NftRoyalty({required this.address, this.value = 5000});

  factory NftRoyalty.fromJson(Map<String, dynamic> json) => _$NftRoyaltyFromJson(json);

  Map<String, dynamic> toJson() => _$NftRoyaltyToJson(this);
}

// IPFS Format for Erc-721 Item description and attributes
// https://docs.rarible.org/asset/creating-an-asset#creating-our-nfts-metadata
// Also see https://docs.opensea.io/docs/metadata-standards
/// Optional NFT Attributes [key] [traitType] [value]
///
/// * [key] Key name
/// * [traitType] Trait name
/// * [value] Key Value
/// * [displayType] Optional parameter used on OpenSea for alternate indicators
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class NftAttribute {
  NftAttribute({
    this.key,
    required this.traitType,
    required this.value,
    this.displayType,
  });

  String? key;
  String traitType;
  String value;

  // OpenSea display types "number","date","boost_percentage","boost_number"
  String? displayType;

  // Future also see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1155.md#erc-1155-metadata-uri-json-schema

  factory NftAttribute.fromJson(Map<String, dynamic> json) => _$NftAttributeFromJson(json);

  Map<String, dynamic> toJson() => _$NftAttributeToJson(this);

  @override
  String toString() {
    return "{"
            "traitType: $traitType, "
            "value: $value" +
        ((key != null) ? ", key: $key" : "") +
        ((displayType != null) ? ", displayType: $displayType" : "") +
        "}";
  }
}

/// Rarible Protocol IPFS Metadata format
///
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class NftIpfsMetadata {
  String name;
  String? description;
  String image;
  String? imageData; // OpenSea
  String? externalUrl;
  String? animationUrl;
  String? youtubeUrl; // OpenSea
  String? backgroundColor; // OpenSea

  List<NftAttribute>? attributes;

  /// Rarible Protocol IPFS Metadata format
  ///
  /// * [image]
  /// * [name] Name of the NFT
  /// * [description] Description of the NFT
  /// * [image] IPFS Hash to our content, this must be prefixed with "ipfs://ipfs/{{ IPFS_HASH ))"
  /// * [externalUrl] This is the link to the collections web page. Could be a branded store, or simple website.
  /// rarible.com uses the <collection address> ":" <the bottom 12 bytes of the token id as an integer>
  /// for the external url of a given item.  e.g.:
  ///  "external_url": "https://app.rarible.com/0x60f80121c31a0d46b5279700f9df786054aa5ee5:123913"
  /// * [animationUrl] IPFS Hash just as image field, but it allows every type of multimedia files. Like mp3, mp4 etc
  NftIpfsMetadata({
    required this.name,
    required this.image,
    this.description,
    this.externalUrl,
    this.animationUrl,
    this.backgroundColor,
    this.attributes,
    this.youtubeUrl,
  });

  factory NftIpfsMetadata.fromJson(Map<String, dynamic> json) => _$NftIpfsMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$NftIpfsMetadataToJson(this);

  @override
  String toString() {
    String attributeString = "";
    if (attributes != null) {
      for (var element in attributes!) {
        attributeString += "$element ";
      }
    }

    return "{\n"
            "  name: $name,\n"
            "  image: $image,\n" +
        ((description != null) ? "  description: $description,\n" : "") +
        ((externalUrl != null) ? "  externalUrl: $externalUrl,\n" : "") +
        ((backgroundColor != null) ? "  backgroundColor: $backgroundColor,\n" : "") +
        ((animationUrl != null) ? "  animationUrl: $animationUrl,\n" : "") +
        ((youtubeUrl != null) ? "  youtubeUrl: $youtubeUrl,\n" : "") +
        ((attributes != null) ? "  attributes: [ $attributeString]\n" : "") +
        "}";
  }
}

/// Rarible Item from API calls

/// NFT Creator Part
/// [address] Creator account - will need to sign/approvals
/// [value] Values are specified in basis points. For example, 2000 means 20%.
@JsonSerializable()
class BlockchainAddress {
  String blockchain;
  String address;

  BlockchainAddress({required this.address, required this.blockchain});

  factory BlockchainAddress.fromJson(Map<String, dynamic> json) => _$BlockchainAddressFromJson(json);

  Map<String, dynamic> toJson() => _$BlockchainAddressToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class Item {
  String id;
  String blockchain;
  String collection;
  String contract;
  String tokenId;
  List<NftCreator> creators;
  List<NftCreator> owners;
  List<NftRoyalty> royalties;
  String? lazySupply;
  List<dynamic> pending;
  @JsonKey(ignore: true)
  DateTime? mintedAt;
  @JsonKey(ignore: true)
  DateTime? lastUpdatedAt;
  @JsonKey(ignore: true)
  List<dynamic>? meta;
  bool deleted;
  List<dynamic> auctions;
  String totalStock;
  int sellers;

  Item(
      this.id,
      this.blockchain,
      this.collection,
      this.contract,
      this.tokenId,
      this.creators,
      this.owners,
      this.royalties,
      this.lazySupply,
      this.pending,
      // this.mintedAt,
      // this.lastUpdatedAt,
      // this.meta,
      this.deleted,
      this.auctions,
      this.totalStock,
      this.sellers);

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);

  Map<String, dynamic> toJson() => _$ItemToJson(this);
}
