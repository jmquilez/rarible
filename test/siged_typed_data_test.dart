import 'dart:convert';

import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:eth_sig_util/model/typed_data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  JsonEncoder encoder = const JsonEncoder.withIndent('  ');
  String? prettyprint;

  // Keys for unit testing only
  String walletAddress = '0xbdB75073F7bC2E2fe26F846975b3ff64fd30D3b4';
  String walletPrivateKey = 'dcb9f84b32289b5079d58d0c8231d10e8c8cef7034493a91aa1b185068fdd6c8';

  //  Create lazyMintRequestBody (pre-signature)
  Map<String, dynamic> messageToSign = <String, dynamic>{
    "@type": "ERC721",
    "contract": "0xB0EA149212Eb707a1E5FC1D2d3fD318a8d94cf05",
    "tokenURI": "/ipfs/Qmc9hvaC9EUK7efbCfJc2QESB9NxW84jbPiTvz1p6Lh91d",
    "tokenId": "85811016661282950678352305265629525770441762754136673725069232823650475835401",
    "uri": "/ipfs/Qmc9hvaC9EUK7efbCfJc2QESB9NxW84jbPiTvz1p6Lh91d",
    "creators": [
      {"account": walletAddress, "value": 10000}
    ],
    "royalties": <int>[],
  };

  prettyprint = encoder.convert(messageToSign);
  if (kDebugMode) {
    print('message content to sign---\n$prettyprint\n---');
  }

  final TypedMessage typedMessage = TypedMessage(
    types: {
      "EIP712Domain": [
        TypedDataField(name: "name", type: "string"),
        TypedDataField(name: "version", type: "string"),
        TypedDataField(name: "chainId", type: "uint256"),
        TypedDataField(name: "verifyingContract", type: "address")
      ],
      "Part": [
        TypedDataField(name: "account", type: "address"),
        TypedDataField(name: "value", type: "uint96"),
      ],
      "Mint721": [
        TypedDataField(name: "tokenId", type: "uint256"),
        TypedDataField(name: "tokenURI", type: "string"),
        TypedDataField(name: "creators", type: "Part[]"),
        TypedDataField(name: "royalties", type: "Part[]")
      ],
    },
    primaryType: "Mint721",
    domain: EIP712Domain(
      name: "Mint721",
      version: "1",
      chainId: 3,
      verifyingContract: "0xB0EA149212Eb707a1E5FC1D2d3fD318a8d94cf05",
      salt: null,
    ),
    message: messageToSign,
  );

  prettyprint = encoder.convert(typedMessage);
  if (kDebugMode) {
    print(
        '-- BEGIN signed type data request --->\n$prettyprint\n<--- END full signing request. NOTE: Newlines added. ---');
  }

  /// Sign the typed Data Structure of request
  test('signedTypedData signature with private key and Mint721 form.', () {
    String signature = EthSigUtil.signTypedData(
      privateKey: walletPrivateKey,
      jsonData: jsonEncode(typedMessage),
      version: TypedDataVersion.V4,
      chainId: null, // Do not specify chainId for the signature function call.
    );
    if (kDebugMode) {
      print(' Signature result: $signature');
    }
    expect(signature,
        '0x6b689436d89f6a479fd2b95a731f4a33e6c3aa6f97abdc7e6df0c5b977d561c02ee6bc224c713631bd7dad82b6c6f7c74ff17f25220112acc8bd29e57d2801b11c');
  });
}

// Metamask test output to match behavior
// form to sign: {"types":{"EIP712Domain":[{"type":"string","name":"name"},{"type":"string","name":"version"},{"type":"uint256","name":"chainId"},{"type":"address","name":"verifyingContract"}],"Part":[{"name":"account","type":"address"},{"name":"value","type":"uint96"}],"Mint721":[{"name":"tokenId","type":"uint256"},{"name":"tokenURI","type":"string"},{"name":"creators","type":"Part[]"},{"name":"royalties","type":"Part[]"}]},"domain":{"name":"Mint721","version":"1","chainId":3,"verifyingContract":"0xB0EA149212Eb707a1E5FC1D2d3fD318a8d94cf05"},"primaryType":"Mint721","message":{"@type":"ERC721","contract":"0xB0EA149212Eb707a1E5FC1D2d3fD318a8d94cf05","tokenId":"85811016661282950678352305265629525770441762754136673725069232823650475835401","uri":"/ipfs/Qmc9hvaC9EUK7efbCfJc2QESB9NxW84jbPiTvz1p6Lh91d","creators":[{"account":"0xbdB75073F7bC2E2fe26F846975b3ff64fd30D3b4","value":10000}],"royalties":[],"tokenURI":"/ipfs/Qmc9hvaC9EUK7efbCfJc2QESB9NxW84jbPiTvz1p6Lh91d"}}
// sig : 0x6b689436d89f6a479fd2b95a731f4a33e6c3aa6f97abdc7e6df0c5b977d561c02ee6bc224c713631bd7dad82b6c6f7c74ff17f25220112acc8bd29e57d2801b11c EIP712.js:38
// r: 0x6b689436d89f6a479fd2b95a731f4a33e6c3aa6f97abdc7e6df0c5b977d561c0 , s:  0x2ee6bc224c713631bd7dad82b6c6f7c74ff17f25220112acc8bd29e57d2801b1 , v: 28
