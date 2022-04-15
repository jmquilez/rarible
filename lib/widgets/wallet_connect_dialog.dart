import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rarible_example/model/wallet_connect_registry.dart';

/// BottomSheet Dialog for IOS users to select their wallet
/// [wallets] provides the listing data for the wallets to present
/// [setWalletListing] is the callback function that receives the selected listing.
Widget showIOSWalletSelectionDialog(
    BuildContext context, List<WalletConnectRegistryListing> wallets, Function setWalletListing) {
  return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
    List<Widget> walletEntries = [];

    for (WalletConnectRegistryListing listing in wallets) {
      walletEntries.add(Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 20, right: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              listing.name,
              style: Theme.of(context).textTheme.headline5!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            IconButton(
              icon: Image.network(
                listing.image_url.sm,
                height: 40,
              ),
              iconSize: 40,
              onPressed: () {
                if (kDebugMode) {
                  print('user selected ${listing.name} as their wallet!');
                }
                setWalletListing(listing);
                Navigator.pop(context);
              },
            ),
            IconButton(
              alignment: Alignment.centerLeft,
              icon: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 32,
                color: Colors.grey.shade500,
              ),
              iconSize: 32,
              onPressed: () {
                if (kDebugMode) {
                  print('user selected ${listing.name} as their wallet!');
                }
                setWalletListing(listing);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ));
    }

    return IntrinsicHeight(
      child: Container(
        color: Colors.black87,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/img/walletconnect-banner.png',
                      height: 40,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.cancel,
                        size: 32,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        if (kDebugMode) {
                          print('user cancelled!');
                        }
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 16,
                      ),
                      Text('Choose your preferred wallet',
                          style: Theme.of(context).textTheme.headline6!.copyWith(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                              )),
                      const SizedBox(height: 16.0),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: walletEntries,
                        ),
                      ),
                      // TODO: Add QR Code

                      const SizedBox(
                        height: 16.0,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  });
}
