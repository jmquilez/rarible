import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:eth_sig_util/model/typed_data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rarible_example/constants.dart';
import 'package:flutter_rarible_example/model/wallet_connect_registry.dart';
import 'package:flutter_rarible_example/widgets/wallet_connect_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:walletconnect_secure_storage/walletconnect_secure_storage.dart';

//* TODO: Find a way for your app to retrieve and handle private keys securely *
// NOTE: You never want a production private key packaged in your app.
// That said - for this example it is essentially hard coded in the binary (bad)
// Since I don't want to accidentally save a key to revision control I am
// using a command line flag to the flutter build command.
// e.g. --dart-define=MINTER_ADDRESS=SOME_VALUE --dart-define=MINTER_PRIVATE_KEY=OTHER_VALUE
class EnvironmentConfig {
  static const kExampleMinterAddress = String.fromEnvironment('MINTER_ADDRESS');
  static const kExampleMinterPrivateKey = String.fromEnvironment('MINTER_PRIVATE_KEY');
}

// The documents and API should avoid using high level terms such as 'contract' and 'uri' which are super ambiguous.
// Ideally the documentation should be as explicit as possible, and roles/usage should be as orthogonal as possible.
// It is easier when the minter is the creator, royalty recipient, and deploys on the rarible default collection, but
// then the documentation fails to show how to use the protocol when these roles differ. You can always add wording,
// if you don't have your own (collection etc.) you can just use the default rarible one instead...

// Asset Contract ERC-721- string (Address) - these are the blockchain specific addresses that define the rarible (RARI) collection.  These can be used as collection addresses when minting.
// Minter Address - string (Address) - the public wallet address of the user who is doing the minting.  This wallet needs funds for performing transactions such as signing etc.
// Minter Private Key - string (Address) - the cryptographic secret that is used for signing and other functions.  It should not be shared.
// Collection - string (Address) -  the ERC-721 contract address that defines the collection name and symbol etc.  Build from a Rarible TokenFactory
// Owner - string (Address) - the wallet address of the user who has the NFT assigned to them on the blockchain.  Not with lazy-minting there may not be an owner until sold.
// Chain Id -  - the integer assigned to the blockchain, it is used as a sanity check to ensure you are working on the proper chain (rinkeyby, robspten, mainnnet)
// Token Id - string (BigInteger) -
// URI- string - ??? context specific
// Account - string (Address) - this is a public wallet address.  Used to identify creators and revenue recipients for royalties.
//           creators account - The minter address is usually the first creator, and the address used for signing.
//           royalties account - any valid wallet that will receive royalties, (e.g. the minter address)
// Signature - string (Binary) - this is the 129 byte signed-typed-data signature as defined in https://eips.ethereum.org/EIPS/eip-712
//             Bytes 0…64 contain the r parameter, bytes 64…128 the s parameter and the last byte the v parameter.
//             Note that the v parameter includes the chain id as specified in EIP-155.

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Configure SDK Basic Settings
  init(blockchain: BlockchainFlavor.rinkeby);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget with WidgetsBindingObserver {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

// Global Settings
var logger = Logger(printer: SimpleLogPrinter(''));
late BlockchainFlavor blockchainFlavor;
late String basePath;
late int chainId;
late String collection;
late String minter;
late String tokenId;
late String mediaIpfsCID; // Primary NFT Image
late String nftMetadataIpfsCID; // NFT JSON Metadata with attributes in IPFS
late String raribleDotCom;
late String multichainBaseUrl;
late String multichainBlockchain;
late String blockExplorer;
late WalletConnect walletConnect;
late WalletConnectRegistryListing walletListing;
String? nftStoreUri;

/// Logging Formatter
/// Leveraged from:https://medium.com/flutter-community/a-guide-to-setting-up-better-logging-in-flutter-3db8bab2000e
class SimpleLogPrinter extends LogPrinter {
  final String className;
  SimpleLogPrinter(this.className);
  @override
  List<String> log(LogEvent event) {
    //var color = PrettyPrinter.levelColors[event.level];
    var emoji = PrettyPrinter.levelEmojis[event.level];
    return ['$emoji $className - ${event.message}'];
    //println(color('$emoji $className - ${event.message}'));
  }
}

/// Initialize Global Settings based on blockchain selected
///
/// [blockchain] User selected blockchain
Future<void> init({BlockchainFlavor blockchain = BlockchainFlavor.rinkeby, bool preserveMinterAddress = false}) async {
  blockchainFlavor = blockchain;
  basePath = basePathMap[blockchain] ?? '';
  chainId = chainIdMap[blockchain] ?? 0;
  collection = assetContractErc721Map[blockchain] ?? ''; // rarible.com default contract addresses
  multichainBaseUrl =
      ({BlockchainFlavor.rinkeby, BlockchainFlavor.ropsten, BlockchainFlavor.mumbai}.contains(blockchain))
          ? 'https://api-staging.rarible.org'
          : 'https://api.rarible.org';
  multichainBlockchain = multiChainBlockchainMap[blockchain] ?? '';

  // WalletConnect may have provided a updated minter address
  if (!preserveMinterAddress) {
    minter = EnvironmentConfig.kExampleMinterAddress;
  }
  raribleDotCom = raribleDotComMap[blockchain] ?? '';
  blockExplorer = blockExplorerMap[blockchain] ?? '';
  tokenId = 'Not Yet Requested\n\n';

  logger.d('Initialized Rarible on ${describeEnum(blockchain)} (chain ID: $chainId) with API basePath $basePath');
  logger.d('multichain baseUrl $multichainBaseUrl with blockchain $multichainBlockchain');
  // Poylygon collections have an additional path
  if (basePath.contains('polygon')) {
    logger.d('Collection Address: $collection - $raribleDotCom/collection/polygon/$collection}');
  } else {
    logger.d('Collection Address: $collection - $raribleDotCom/collection/$collection}');
  }
  logger.d('Minter Wallet address: $minter - $blockExplorer/$minter');
  logger.d('Faucet URL: ${faucetMap[blockchain] ?? 'unknown'}');
}

///  Query the WalletConnect Registry for compatibleWallets
///  [limit] specifies the total number of wallets to return
///
/// Example code does not support multiple requests across pages.
/// Registry API Documentation available here: https://docs.walletconnect.com/2.0/api/registry-api
Future<List<WalletConnectRegistryListing>> readWalletRegistry({int limit = 4}) async {
  List<WalletConnectRegistryListing> listings = [];

  var client = http.Client();
  try {
    http.Response response;

    final queryParameters = {
      'entries': '$limit',
      'page': '1',
    };

    logger.d('Requesting WalletConnect Registry for first $limit wallets.');
    response = await client.get(
      Uri.https(
        'registry.walletconnect.com',
        'api/v1/wallets',
        queryParameters,
      ),
      headers: {
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      //log(response.body);
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>?;

      if (decodedResponse != null && decodedResponse['listings'] != null) {
        // Present user with list of supported wallets (IOS)

        for (Map<String, dynamic> entry in decodedResponse['listings'].values) {
          listings.add(WalletConnectRegistryListing.fromJson(entry));
          //logger.d('Processing ${listings.last.name}');
        }
      }
      return listings;
    } else {
      logger.e('Unexpected server error: ${response.statusCode}: ${response.reasonPhrase}.');
    }
  } catch (e) {
    logger.e('Unexpected protocol error: $e');
  } finally {
    client.close();
  }
  return listings;
}

/// Updates global walletListing so subsequent requests can be directed to the wallet
void setWalletListing(WalletConnectRegistryListing listing) {
  walletListing = listing;
}

/// Calls the Rarible API to get the next tokenId for the given collection
///  [collection] the address of the Lazy Mint compatible ERC-721 contract
///  [minter] the address of the primary creator who will sign the later
///           Lazy Mint request
///
///  Ethereum API nft-collection-controller:generateNftTokenId
///  https://ethereum-api.rarible.org/v0.1/doc#operation/generateNftTokenId
Future<String> getNextTokenId({required String minter}) async {
  Stopwatch stopwatch = Stopwatch();
  String apiUrl = '${basePath}v0.1/nft/collections/$collection/generate_token_id';
  logger.d('Requesting next token if from $apiUrl.');

  var client = http.Client();
  final apiUri = Uri.parse(apiUrl);
  final hostname = apiUri.host;

  stopwatch.start();
  final ipAddress = await InternetAddress.lookup(hostname);
  stopwatch.stop();
  logger.i('${stopwatch.elapsedMilliseconds}ms for DNS lookup of hostname $hostname ($ipAddress)');

  try {
    var response = await client.get(
      Uri.https(apiUri.host.toString(), apiUri.path.toString(), {'minter': minter}),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      // logger.d('200 ok: $decodedResponse');
      tokenId = decodedResponse['tokenId'];
    } else {
      var decodedResponse = jsonDecode(response.body);
      logger.e('response: ${response.statusCode}: ${response.reasonPhrase} / ${response.body.toString()}.');
      return 'Error: ${response.statusCode}:${response.reasonPhrase} - ${decodedResponse['message']}.';
    }
  } on SocketException {
    logger.e('SocketException');
    return 'Error: We are unable to initiate communicate with our backend. (SocketException).';
  } on TimeoutException {
    logger.e('TimeoutException');
    return 'Error: Our rarible servers are taking too long to respond. (TimeoutException).';
  } catch (e) {
    logger.e('Error: Ok, we were not expecting this error: $e');
  } finally {
    client.close();
  }
  return tokenId;
}

/// Build Lazy Mint SignTypedData Form
TypedMessage createMint721TypedMessage({
  required int collectionChainId,
  required String collectionAddress,
  required Map<String, dynamic> lazyMintFormJson,
}) {
  // We need to present the user with a signing request that can be
  // rendered/presented properly by the signing wallets.  The TypedDataMessage
  // provides the structure definition followed by the message to be signed.
  final TypedMessage mint721TypedMessage = TypedMessage(
    // Define the types used below.  These should not change
    types: {
      // The HOW to understand and parse the data to sign.
      // node_modules/@rarible/protocol-ethereum-sdk/build/nft/eip712.d.ts
      "EIP712Domain": [
        TypedDataField(name: "name", type: "string"),
        TypedDataField(name: "version", type: "string"),
        TypedDataField(name: "chainId", type: "uint256"),
        TypedDataField(name: "verifyingContract", type: "address")
      ],
      // Part definition - not an array of Part[] like below
      "Part": [
        TypedDataField(name: "account", type: "address"),
        TypedDataField(name: "value", type: "uint96"),
      ],
      "Mint721": [
        TypedDataField(name: "tokenId", type: "uint256"),
        TypedDataField(name: "tokenURI", type: "string"),
        TypedDataField(name: "creators", type: "Part[]"), // This is an array[] of Part
        TypedDataField(name: "royalties", type: "Part[]"), // This is an array[] of Part
      ],
    },
    // This is the data that we will present to sign, a good UI will only show this
    // half in the signing request verification
    primaryType: "Mint721",
    domain: EIP712Domain(
      // Details of the form and where to find the contract to verify it
      name: "Mint721",
      version: "1",
      chainId: collectionChainId, //  must match the collection's chainId or the signature will not verify
      verifyingContract: collectionAddress, // the lazy mint enabled ERC-721 contract address
      salt: "0", // do better than this
    ),
    // The "WHAT" data we are asking to sign. This will later get the signature(s) appended to it.
    message: lazyMintFormJson,
  );

  //String jsonData = jsonEncode(rawTypedData);
  //prettyPrint = encoder.convert(rawTypedData);
  //log('SignTypedData---\n$prettyprint\n---');
  return mint721TypedMessage;
}

/// Rarible API call to perform the Lazy mint requested
/// [message] JSON lazy mint form with the creators' signature(s) appended
///           (from the SignedTypedData requests)
///
/// Ethereum API nft-lazy-mint-controller:mintNftAsset
/// https://ethereum-api.rarible.org/v0.1/doc#operation/mintNftAsset
Future<String?> requestLazyMint(Map<String, dynamic> message) async {
  Stopwatch stopwatch = Stopwatch();
  String apiUrl = '${basePath}v0.1/nft/mints';
  logger.d('Requesting NFT mint from $apiUrl.');

  String hostname = Uri.parse(apiUrl).host;
  stopwatch.start();
  final ipAddress = await InternetAddress.lookup(hostname);
  stopwatch.stop();
  logger.i('${stopwatch.elapsedMilliseconds}ms for DNS lookup of hostname $hostname ($ipAddress)');
  final statDnsLookup = stopwatch.elapsedMilliseconds;

  var client = http.Client();
  stopwatch.start();
  try {
    var response = await client.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(message),
    );
    stopwatch.stop();
    logger.i('${stopwatch.elapsedMilliseconds - statDnsLookup}ms for API: $apiUrl ($ipAddress)');
    if (response.statusCode == 200) {
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      logger.d('200 ok: $decodedResponse');
    } else {
      var decodedResponse = jsonDecode(response.body);
      logger.e('response: ${response.statusCode}: ${response.reasonPhrase} / ${response.body.toString()}.');
      return 'Error: ${response.statusCode}:${response.reasonPhrase} - ${decodedResponse['message']}.';
    }
  } on SocketException {
    logger.e('SocketException');
    return 'Error: We are unable to initiate communicate with our backend. (SocketException).';
  } on TimeoutException {
    logger.e('TimeoutException');
    return 'Error: Our backend servers are taking too long to respond. (TimeoutException).';
  } catch (e) {
    logger.e('Error: Ok, we were not expecting this error: $e');
  } finally {
    client.close();
  }
  logger.i('getNftLazyItemById -> ${basePath}v0.1/nft/items/$collection:$tokenId/lazy');
  return 'OK!';
}

/// Sign typedDataV4 form using eth_sig_util.dart
///
/// [privateKey] - Sensitive data you don't want to be keeping around
/// [typedMessage] - TypedMessage that contains the message to sign
String signTypedDataWithPrivateKey({required String privateKey, required TypedMessage typedMessage}) {
  String ethSigUtilSignature = '';

  try {
    ethSigUtilSignature = EthSigUtil.signTypedData(
      privateKey: privateKey,
      jsonData: jsonEncode(typedMessage),
      version: TypedDataVersion.V4,
      chainId: null, // Do not specify chainId for the signature function call.
    );

    logger.i('ethSigUtilSignature result: $ethSigUtilSignature');
  } catch (e) {
    logger.e('EthSigUtil.signTypedData returned $e');
  }
  return ethSigUtilSignature;
}

/// Sign typedDataV4 form using eth_sig_util.dart
///
/// [privateKey] - Sensitive data you don't want to be keeping around
/// [typedMessage] - TypedMessage that contains the message to sign
String personalSignWithPrivateKey({required String privateKey, required String message}) {
  // Convert from message String to U8intList
  List<int> codeUnits = message.codeUnits;
  Uint8List messageBytes = Uint8List.fromList(codeUnits);

  String ethSigUtilSignature = '';

  try {
    ethSigUtilSignature = EthSigUtil.signPersonalMessage(
      privateKey: privateKey,
      message: messageBytes,
      chainId: null, // Do not specify chainId for the signature function call.
    );

    logger.i('ethSigUtilSignature result: $ethSigUtilSignature');
  } catch (e) {
    logger.e('EthSigUtil.signTypedData returned $e');
  }
  return ethSigUtilSignature;
}

Future<String> signTypedDataWithWalletConnect(
    {required BuildContext context, required WalletConnect walletConnector, required TypedMessage typedMessage}) async {
  // For signing requests for a connected wallet, only provide the existing session id and version number.
  String walletConnectTopicVersion = 'wc:${walletConnect.session.handshakeTopic}@${walletConnect.session.version}';
  String walletConnectUri = '';
  String walletConnectSignature = '';

  if (Theme.of(context).platform == TargetPlatform.android) {
    // Android OS helps the user choose their wallet
    walletConnectUri = walletConnectTopicVersion;
  } else {
    // IOS has selected a wallet listing from the WalletConnect Registry to use
    logger
        .d('Launching configured wallet ${walletListing.name} using universal link ${walletListing.mobile.universal}');
    walletConnectUri = walletListing.mobile.universal + '/wc?uri=${Uri.encodeComponent(walletConnectTopicVersion)}';
  }
  bool result = await launch(walletConnectUri, universalLinksOnly: false, forceSafariVC: false);
  if (result == false) {
    // Application specific link didn't work, so we may redirect to the app store to get a wallet
    result = await launch(walletConnectUri, forceSafariVC: true);
    if (result == false) {
      logger.e('Could not launch $walletConnectUri');
    }
  }

  // If the wallet isn't already opened, give it a change to startup
  sleep(const Duration(milliseconds: 1000));

  // Ask WalletConnect wallet to sign the request
  try {
    dynamic requestResult = await walletConnector.sendCustomRequest(
      method: "eth_signTypedData",
      params: <dynamic>[
        minter,
        jsonEncode(typedMessage),
      ],
    );
    logger.d('WalletConnect signature = $requestResult');
    if (requestResult is String) {
      walletConnectSignature = requestResult; // as String;
    }
  } on Exception catch (e) {
    logger.e(e);
    if (e.toString().contains('User canceled')) {
      logger.e('User Cancelled Connection Request.');
    }
  }
  return walletConnectSignature;
}

Future<bool> lazyMintExample({
  required BuildContext context,
  Function? onProgress,
  required WalletConnect walletConnector,
}) async {
  // This is the json file that defines the NFT, hosted in IPFS
  // see https://docs.rarible.org/asset/creating-an-asset#creating-our-nfts-metadata
  String uri = "/ipfs/QmVUzkLxEoCRyit8uXAuUoVUgFw1c7Uvz7T4bkGgJUwxcf"; // buffalo metadata

  /// Get the next available token id
  onProgress?.call('-> Requesting next available token ID for collection $collection using minter address $minter');
  tokenId = await getNextTokenId(minter: minter);

  //I/flutter (15000): tokenId = 51853873187524799243313032258623492611584136611923237689466576623960428904484 (0x72a4408da42de870499c1841d0e4a49f864e34ba000000000000000000000024)
  if (tokenId.length < 3) {
    logger.e('First 20 bytes of a tokenId needs to match our minter address.');
    logger.e('* Was the collection contract address generated from a rarible TokenFactory?');
    logger.e(
        '* Is the collection contract address valid for this blockchain?  \n(${blockchainFlavor.name}) $blockExplorer/$collection');
    logger.e('* Does the minter have permissions to create tokens on this collection?');
    return false;
  }
  if (tokenId.startsWith('Error')) {
    // Server error getting a valid token
    return false;
  }
  // rarible.com store requires addresses to be lowercase #gotcha
  // and uses the path to indicate the chain (defaulting to ethereum if blank)
  nftStoreUri = raribleDotCom +
      '/token/' +
      (basePath.contains('polygon') ? 'polygon/' : '') +
      collection.toLowerCase() +
      ':' +
      tokenId.toLowerCase();

  onProgress?.call('tokenId = $tokenId (0x${BigInt.parse(tokenId).toRadixString(16)})');

  // Create lazyMintRequestBody part 1
  // This is the recipe for the NFT, so the contents are more dynamic
  Map<String, dynamic> lazyMintFormJson = {
    "@type": "ERC721",
    "contract": collection,
    "tokenURI": uri,
    "tokenId": tokenId,
    "uri": uri,
    // The end user/minter should verify they are listed as the first creator
    // so they have the ability to sell the Lazy Minted NFT
    "creators": [
      {"account": minter, "value": 10000} // value numbers are not in quotes
    ],
    // The artist and technology partners will likely be listed in royalties
    "royalties": [
      {"account": minter, "value": 2500} // value numbers are not in quotes
    ],
    // To be added after signing
    // "signatures": [signature]
  };

  onProgress?.call('Authoring lazyMintRequest Form.');
  JsonEncoder encoder = const JsonEncoder.withIndent('  ');
  String prettyPrint = encoder.convert(lazyMintFormJson);
  logger.i('lazyMintFormJson:\n$prettyPrint\n');

  // Package the form inside a signedTypeData message
  TypedMessage mint721TypedMessage = createMint721TypedMessage(
      collectionChainId: chainId, collectionAddress: collection, lazyMintFormJson: lazyMintFormJson);

  String signature = '';
  String minterPrivateKey = EnvironmentConfig.kExampleMinterPrivateKey;
  if (minterPrivateKey.isNotEmpty && minter == EnvironmentConfig.kExampleMinterAddress) {
    onProgress?.call('Calling EthSigUtils to have form signed.');
    logger.d('We have the private key for minter $minter, signing with EthSigUtils');
    signature = signTypedDataWithPrivateKey(privateKey: minterPrivateKey, typedMessage: mint721TypedMessage);
  } else {
    /// Sign the typed Data Structure of request
    onProgress?.call('Calling WalletConnect API to have form signed.');
    signature = await signTypedDataWithWalletConnect(
      context: context,
      walletConnector: walletConnector,
      typedMessage: mint721TypedMessage,
    );
  }

  /// Build final Lazy Mint Request - add list of signatures
  lazyMintFormJson['signatures'] = [signature];
  //lazyMintFormJson.remove('tokenURI'); // Example code does not include tokenURI

  prettyPrint = encoder.convert(lazyMintFormJson);
  log('lazyMintFormJson\n---\n$prettyPrint\n---');

  String mintStatus = await requestLazyMint(lazyMintFormJson) ?? 'Error: null response from API';

  onProgress?.call('LazyMint completed.  Store link: $nftStoreUri');
  if (basePath.contains('polygon')) {
    // rarible uses the path to indicate a Polygon address from Ethereum
    logger.d('getNftLazyItemById -> ${basePath}v0.1/nft/items/polygon/$collection:$tokenId/lazy');
  } else {
    logger.d('getNftLazyItemById -> ${basePath}v0.1/nft/items/$collection:$tokenId/lazy');
  }
  logger.d('$multichainBaseUrl/v0.1/items/$multichainBlockchain:$collection:$tokenId');
  logger.d('$multichainBaseUrl/v0.1/ownerships/byItem?itemId=$multichainBlockchain:$collection:$tokenId');

  // We are good unless there was an error message
  return (!mintStatus.contains('Error'));
}

/// Validate Lazy Mint Item
///
/// Check the NFT has completed processing and the metadata is visible
/// Verify the NFT is not for sale ( See https://github.com/rarible/protocol/issues/338 )
///
/// TODO:
/// https://api-staging.rarible.org/v0.1/items/ETHEREUM:0xf565108F208136B1AffD55d19A6236b6b6b9786D:57821959090642343791910250240090585543967286493013648175904625818401167638831
Future<void> validateLazyMint({required String collection, required String tokenId, required String minter}) async {
  logger.d('$multichainBaseUrl/v0.1/ownerships/byItem?itemId=$multichainBlockchain:$collection:$tokenId');
}

/// Delete Lazy Minted Item
///  [collection] the address of the Lazy Mint compatible ERC-721 contract
///  [minter] the address of the primary creator who will sign the later
///           Lazy Mint request
///
///  Ethereum API nft-collection-controller:generateNftTokenId
///  https://ethereum-api.rarible.org/v0.1/doc#operation/generateNftTokenId
Future<String> lazyDelete({required String collection, required String tokenId, required String minter}) async {
  Stopwatch stopwatch = Stopwatch();
  String apiUrl = '${basePath}v0.1/nft/items/$collection:$tokenId/lazy/delete';
  logger.d('Requesting deletion of tokenId: $tokenId from collection $collection using endpoint $apiUrl.');

  // We need to prove we are the owner of the NFT by using a personal signed note
  String lazyDeleteRequest = 'I would like to burn my $tokenId item.';
  String personalSignature = '';

  String minterPrivateKey = EnvironmentConfig.kExampleMinterPrivateKey;
  if (minterPrivateKey.isNotEmpty && minter == EnvironmentConfig.kExampleMinterAddress) {
    logger.d('We have the private key for minter $minter, signing with EthSigUtils');
    personalSignature = personalSignWithPrivateKey(privateKey: minterPrivateKey, message: lazyDeleteRequest);
  } else {
    // TO-DO wallet connect personal sign
  }

  Map<String, dynamic> lazyDeleteForm = {
    "creators": [minter],
    "signatures": [personalSignature]
  };

  logger.d(jsonEncode(lazyDeleteForm));

  var client = http.Client();
  final apiUri = Uri.parse(apiUrl);
  final hostname = apiUri.host;

  stopwatch.start();
  final ipAddress = await InternetAddress.lookup(hostname);
  stopwatch.stop();
  logger.i('${stopwatch.elapsedMilliseconds}ms for DNS lookup of hostname $hostname ($ipAddress)');

  try {
    var response = await client.post(Uri.https(apiUri.host.toString(), apiUri.path.toString()),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(lazyDeleteForm));
    log(response.body);
    if (response.statusCode == 204) {
      logger.d('successful delete. status code: ${response.statusCode}');
    } else {
      var decodedResponse = jsonDecode(response.body);
      logger.e('response: ${response.statusCode}: ${response.reasonPhrase} / ${response.body.toString()}.');
      return 'Error: ${response.statusCode}:${response.reasonPhrase} - ${decodedResponse['message']}.';
    }
  } on SocketException {
    logger.e('SocketException');
    return 'Error: We are unable to initiate communicate with our backend. (SocketException).';
  } on TimeoutException {
    logger.e('TimeoutException');
    return 'Error: Our rarible servers are taking too long to respond. (TimeoutException).';
    //} catch (e) {
    //  logger.e('Error: Ok, we were not expecting this error: $e');
  } finally {
    client.close();
  }
  return tokenId;
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  String statusMessage = 'Initialized';
  String _displayUri = ''; // QR Code for OpenConnect but not used

  Future<void> initWalletConnect() async {
    // Wallet Connect Session Storage - So we can persist connections
    final sessionStorage = WalletConnectSecureStorage();
    final session = await sessionStorage.getSession();

    // Create a connector
    walletConnect = WalletConnect(
      // TODO: V1 performance issues - consider rolling your own bridge
      bridge: 'https://bridge.walletconnect.org',
      session: session,
      sessionStorage: sessionStorage,
      clientMeta: PeerMeta(
        name: 'Flutter Rarible Demo',
        description: 'Flutter Rarible Protocol Demo App',
        url: 'https://www.rarible.org',
        icons: [(raribleDotCom + '/favicon.png')],
      ),
    );

    // Did we restore a session?
    if (session != null) {
      logger.d(
          "WalletConnect - Restored  v${session.version} session: ${session.accounts.length} account(s), bridge: ${session.bridge} connected: ${session.connected}, clientId: ${session.clientId}");

      if (session.connected) {
        logger.d(
            'WalletConnect - Attempting to reuse existing connection for chainId ${session.chainId} and wallet address ${session.accounts[0]}.');
        setState(() {
          minter = session.accounts[0];
          chainId = session.chainId;
          blockchainFlavor = BlockchainFlavorExtention.fromChainId(chainId);
        });
      }
    } else {
      logger.w('WalletConnect - No existing sessions.  User needs to connect to a wallet.');
    }

    walletConnect.registerListeners(
      onConnect: (status) {
        // What information is available?
        logger.d('WalletConnect - Connected session. $status');

        // Did the user select a new chain?
        if (chainId != status.chainId) {
          logger
              .d('WalletConnect - onConnect. Selected blockchain has changed: chainId: $chainId <- ${status.chainId})');
          setState(() {
            chainId = status.chainId;
            blockchainFlavor = BlockchainFlavorExtention.fromChainId(chainId);
          });
        }

        // Did the user select a new wallet address?
        if (minter != status.accounts[0]) {
          logger.d('WalletConnect - onConnect. Selected wallet has changed: minter: $minter <- ${status.accounts[0]}');
          setState(() {
            minter = status.accounts[0];
          });
        }
      },
      onSessionUpdate: (status) {
        // What information is available?
        //print('WalletConnect - Updated session. $status');

        // Did the user select a new chain?
        if (chainId != status.chainId) {
          logger.d(
              'WalletConnect - onSessionUpdate. Selected blockchain has changed: chainId: $chainId <- ${status.chainId}');
          setState(() {
            chainId = status.chainId;
            blockchainFlavor = BlockchainFlavorExtention.fromChainId(chainId);
          });
        }

        // Did the user select a new wallet address?
        if (minter != status.accounts[0]) {
          logger.d(
              'WalletConnect - onSessionUpdate. Selected wallet has changed: minter: $minter <- ${status.accounts[0]}');
          setState(() {
            minter = status.accounts[0];
          });
        }
      },
      onDisconnect: () async {
        logger.d('WalletConnect - onDisconnect. minter: $minter <- "Please Connect Wallet"');
        setState(() {
          minter = 'Please Connect Wallet';
        });
        await initWalletConnect();
      },
    );
  }

  Future<void> createWalletConnectSession(BuildContext context) async {
    // Create a new session
    if (walletConnect.connected) {
      logger.d(
          'createWalletConnectSession - WalletConnect Already connected minter: $minter, chainId $chainId. Ignored.');
      return;
    }

    // IOS users will need to be prompted which wallet to use.
    if (Platform.isIOS) {
      List<WalletConnectRegistryListing> listings = await readWalletRegistry(limit: 4);

      await showModalBottomSheet(
        context: context,
        builder: (context) {
          return showIOSWalletSelectionDialog(context, listings, setWalletListing);
        },
        isScrollControlled: true,
        isDismissible: false,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      );
    }

    logger.d('createWalletConnectSession');
    SessionStatus session;
    try {
      session = await walletConnect.createSession(
          chainId: 1,
          onDisplayUri: (uri) async {
            setState(() {
              _displayUri = uri;
              logger.d('_displayUri updated with $uri');
            });

            // Open any registered wallet via wc: intent
            bool? result;

            // IOS users have already chosen wallet, so customize the launcher
            if (Platform.isIOS) {
              uri = walletListing.mobile.universal + '/wc?uri=${Uri.encodeComponent(uri)}';
            }
            // Else
            // - Android users will choose their walled from the OS prompt

            logger.d('launching uri: $uri');
            try {
              result = await launch(uri, universalLinksOnly: true, forceSafariVC: false);
              if (result == false) {
                // launch alternative method
                logger.e('Initial launchuri failed. Fallback launch with forceSafariVC true');
                result = await launch(uri, forceSafariVC: true);
                if (result == false) {
                  logger.e('Could not launch $uri');
                }
              }
            } on PlatformException catch (e) {
              if (e.code == 'ACTIVITY_NOT_FOUND') {
                logger.w('No wallets available - do nothing!');
                setState(() {
                  statusMessage = 'ERROR - No WalletConnect compatible wallets found.';
                });
                return;
              }
              logger.e('launch returned $result');
              logger.e('Unexpected PlatformException error: ${e.message}, code: ${e.code}, details: ${e.details}');
            } on Exception catch (e) {
              logger.e('launch returned $result');
              logger.e('url launcher other error e: $e');
            }
          });
    } catch (e) {
      logger.e('Unable to connect - killing the session on our side.');
      walletConnect.killSession();
      return;
    }
    if (session.accounts.isEmpty) {
      // wc:f54c5bca-7712-4187-908c-9a92aa70d8db@1?bridge=https%3A%2F%2Fz.bridge.walletconnect.org&key=155ca05ffc2ab197772a5bd56a5686728f9fcc2b6eee5ffcb6fd07e46337888c
      logger.e('Failed to connect to wallet.  Bridge Overloaded? Could not Connect?');
    }
  }

  @override
  void initState() {
    super.initState();
    // Register observer so we can see app lifecycle changes.
    WidgetsBinding.instance!.addObserver(this);
    initWalletConnect();
  }

  /// The wallet connect client, sometimes loses the webSocket connection when the app is suspended
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    DateFormat dateFormat = DateFormat("HH:mm:ss");
    String dateString = dateFormat.format(DateTime.now());

    logger.d("$dateString AppLifecycleState: ${state.toString()}.");

    if (state == AppLifecycleState.resumed && mounted) {
      // If we have a configured connection but the websocket is down try once to reconnect
      if (walletConnect.connected && walletConnect.bridgeConnected == false) {
        logger.w('$dateString  Wallet connected, but transport is down.  Attempt to recover.');
        walletConnect.reconnect();
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    // Remove observer for app lifecycle changes.
    WidgetsBinding.instance!.removeObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Rarible example app'),
        ),
        body: Builder(builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(mainAxisAlignment: MainAxisAlignment.start, mainAxisSize: MainAxisSize.max, children: [
              Align(
                alignment: Alignment.topRight,
                child: DropdownButton(
                  dropdownColor: Theme.of(context).cardColor,
                  value: describeEnum(blockchainFlavor),
                  items: <String>['ropsten', 'rinkeby', 'ethMainNet', 'mumbai', 'polygonMainNet', 'unknown']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? value) async {
                    switch (value) {
                      case 'ropsten':
                        blockchainFlavor = BlockchainFlavor.ropsten;
                        break;
                      case 'rinkeby':
                        blockchainFlavor = BlockchainFlavor.rinkeby;
                        break;
                      case 'net':
                        blockchainFlavor = BlockchainFlavor.ethMainNet;
                        break;
                      case 'mumbai':
                        blockchainFlavor = BlockchainFlavor.mumbai;
                        break;
                    }
                    await init(blockchain: blockchainFlavor, preserveMinterAddress: true);
                    setState(() {
                      // // redundant - shouldn't need these
                      // blockchainFlavor = blockchainFlavor;
                      // chainId = chainId;
                      // basePath = basePath;
                      // collection = collection;
                    });
                  },
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Configured for ${describeEnum(blockchainFlavor)} (chain ID: $chainId) \nBasePath: $basePath'),
                    Text(
                      'Collection Address:  \n$collection',
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Minter Address: \n$minter',
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                    //Text('WalletConnect connected: ${walletConnect.connected}'),
                    Text('TokenId: $tokenId'),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                  flex: 1,
                  child: SingleChildScrollView(
                    child: Text(
                      'Status: $statusMessage',
                    ),
                  )),
              const Divider(),
              ElevatedButton(
                onPressed: () {
                  createWalletConnectSession(context);
                },
                child: const Text('Connect Wallet'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (walletConnect.connected) {
                    logger.d('Killing session');
                    walletConnect.killSession();
                  }
                },
                child: const Text('Disconnect Wallet'),
              ),
              Center(
                child: SizedBox(
                  width: 300,
                  child: ElevatedButton(
                    child: const Text('Mint'),
                    onPressed: (() async {
                      logger.d('Button Pressed');

                      if (!walletConnect.connected && EnvironmentConfig.kExampleMinterAddress.isEmpty) {
                        setState(() {
                          statusMessage = 'Connect to wallet first!';
                        });
                        return;
                      }
                      await lazyMintExample(
                          context: context,
                          walletConnector: walletConnect,
                          onProgress: ((String v) {
                            logger.d(v);
                            setState(() {
                              statusMessage = v;
                            });
                          }));
                    }),
                  ),
                ),
              ),
              Center(
                child: SizedBox(
                  width: 300,
                  child: ElevatedButton(
                    child: const Text('Delete'),
                    onPressed: (() async {
                      logger.d('Button Pressed');

                      if (!walletConnect.connected && EnvironmentConfig.kExampleMinterAddress.isEmpty) {
                        setState(() {
                          statusMessage = 'Connect to wallet first!';
                        });
                        return;
                      }
                      await lazyDelete(collection: collection, tokenId: tokenId, minter: minter);
                    }),
                  ),
                ),
              ),
              TextButton(
                  onPressed: () {
                    // TokenId's are big ints... but this is easier
                    if (nftStoreUri != null) {
                      logger.d('Launching uri: $nftStoreUri');
                      launch(nftStoreUri!);
                    }
                  },
                  child: const Text('Store Link'))
            ]),
          );
        }),
      ),
    );
  }
}
