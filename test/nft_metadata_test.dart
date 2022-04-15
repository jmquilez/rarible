import 'dart:convert';

import 'package:flutter_rarible_example/model/nft_metadata.dart';
import 'package:test/test.dart';

void main() {
  test('Create NftAttribute from constructor', () {
    NftAttribute creatorName = NftAttribute(traitType: 'Creator', value: 'Bill Grogan');
    String jsonString = json.encode(creatorName);
    //print('jsonString: $jsonString');
    expect(jsonString, equals('{"trait_type":"Creator","value":"Bill Grogan"}'));
  });

  test('Create NftAttribute from json', () {
    NftAttribute creatorName = NftAttribute.fromJson(
        json.decode('{"key":null,"trait_type":"Creator","value":"Bill Grogan","display_type":null}'));

    expect(creatorName.value, equals('Bill Grogan'));
  });

  test('Create NftIpfsMetadata from constructor', () {
    NftIpfsMetadata metadata = NftIpfsMetadata(
        name: "Oh no!",
        image: "/ipfs/Qma4JKf69UEJPBBej4HXP3d5zGBAJ1idzg94iLZ67iknog",
        description: "Looks like a 500 service error!",
        externalUrl: "https://www.graflr.com",
        attributes: [
          NftAttribute(traitType: "MessageColor", value: "Red"),
          NftAttribute(traitType: "MessageType", value: "Uncommon"),
          NftAttribute(traitType: "Signing Method", value: "Self"),
          NftAttribute(traitType: "Series", value: "2021"),
        ]);

    String jsonString = json.encode(metadata);
    // print('jsonString: $jsonString');

    String expectedJsonString =
        '{"name":"Oh no!","description":"Looks like a 500 service error!","image":"/ipfs/Qma4JKf69UEJPBBej4HXP3d5zGBAJ1idzg94iLZ67iknog","external_url":"https://www.graflr.com","attributes":[{"trait_type":"MessageColor","value":"Red"},{"trait_type":"MessageType","value":"Uncommon"},{"trait_type":"Signing Method","value":"Self"},{"trait_type":"Series","value":"2021"}]}';

    expect(jsonString, equals(expectedJsonString));
  });

  test('Create item from json', () {
    String jsonString =
        '{"id":"POLYGON:0x83cbfcd64fb31b4efafece4385ad0c99da8b180f:57821959090642343791910250240090585543967286493013648175904625818401167638564","blockchain":"POLYGON","collection":"POLYGON:0x83cbfcd64fb31b4efafece4385ad0c99da8b180f","contract":"POLYGON:0x83cbfcd64fb31b4efafece4385ad0c99da8b180f","tokenId":"57821959090642343791910250240090585543967286493013648175904625818401167638564","creators":[{"account":"ETHEREUM:0x7fd611af09befb5f47abb19fcc25a22997aeb0b1","value":10000}],"owners":[],"royalties":[],"lazySupply":"1","pending":[],"mintedAt":"2022-03-28T21:35:30.365Z","lastUpdatedAt":"2022-03-07T23:46:13.895Z","supply":"1","meta":{"name":"Johnny Love","description":"keep rockin it Atlanta!","attributes":[{"key":"Message Color","value":"purple"},{"key":"Message Type","value":"Common"},{"key":"Signing Method","value":"Nearby"},{"key":"Series","value":"2022 Beta"}],"content":[{"@type":"IMAGE","url":"https://rarible.mypinata.cloud/ipfs/QmbfsAhCsAdYqdhFYWXkUFpS7QsHUPWFAirZiVgGiw9GvV","representation":"ORIGINAL"}],"restrictions":[]},"deleted":false,"auctions":[],"totalStock":"0","sellers":0}';
    Item item = Item.fromJson(json.decode(jsonString));
    expect(
        item.id,
        equals(
            'POLYGON:0x83cbfcd64fb31b4efafece4385ad0c99da8b180f:57821959090642343791910250240090585543967286493013648175904625818401167638564'));
  });
  //List<NftCreator> creators = [];
}
