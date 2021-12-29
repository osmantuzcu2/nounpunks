import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'package:flutter_web3_example/abi.dart';
import 'package:flutter_web3_example/fcnp.dart';
import 'package:flutter_web3_example/multiCallAbi.dart';
import 'package:flutter_web3_example/picture_model.dart';
import 'package:flutter_web3_example/youngapeAbi.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

import 'helper.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      GetMaterialApp(title: 'Flip Your Crypto Nouns', home: Home());
}

class HomeController extends GetxController {
  bool get isInOperatingChain => currentChain == OPERATING_CHAIN;

  bool get isConnected => Ethereum.isSupported && currentAddress.isNotEmpty;

  String currentAddress = '';

  int currentChain = -1;

  bool wcConnected = false;

  bool isLoading = false;

  static const OPERATING_CHAIN = 1;

  final wc = WalletConnectProvider.binance();
  String? wallets = "";

  connectProvider() async {
    if (Ethereum.isSupported) {
      final accs = await ethereum!.requestAccount();
      if (accs.isNotEmpty) {
        currentAddress = accs.first;
        currentChain = await ethereum!.getChainId();
      }

      update();
    }
  }

  clear() {
    currentAddress = '';
    currentChain = -1;
    wcConnected = false;

    update();
  }

  var youngapeContract;
  init() {
    if (Ethereum.isSupported) {
      connectProvider();

      ethereum!.onAccountsChanged((accs) {
        clear();
      });

      ethereum!.onChainChanged((chain) {
        clear();
      });

      youngapeContract = SmartContractBuilder(
          nftContractAddress: "0xAa4c5486769D14c8e3C618BF2d2764E6Be5d0cF1",
          multiCallContractAddress:
              "0x5BA1e12693Dc8F9c48aAD8770482f4739bEeD696",
          rpcAddress:
              "https://mainnet.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161",
          contractAbi: youngApeAbi,
          multCallAbi: multCallAbi);
    }
  }

  getSymbol() async {
    try {
      String resp = await youngapeContract.contractCall("symbol", []);
      Get.snackbar("Token Symbol", resp);
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  ownerOf() async {
    try {
      String resp = await youngapeContract.contractCall("ownerOf", [1]);
      Get.snackbar("Owner Address", resp);
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  Future<int> totalSupply() async {
    try {
      var resp = await youngapeContract.contractCall("totalSupply", []);
      return int.parse(resp.toString());
    } catch (e) {
      Get.snackbar("Error", e.toString());
      return 0;
    }
  }

  snapshot() async {
    List<Call> masterChefCalls = [];
    for (var i = 1; i < 696; i++) {
      masterChefCalls.add(Call(
          address: youngapeContract.nftContractAddress,
          name: 'ownerOf',
          params: [BigInt.from(i)]));
    }

    List<dynamic> masterChefCallResponseList =
        (await youngapeContract.multicall(youngApeAbi, masterChefCalls))
            .map((e) => e[0] as EthereumAddress)
            .toList();

    for (var i = 0; i < masterChefCallResponseList.length; i++) {
      print(masterChefCallResponseList[i].hex);
      wallets =
          wallets! + '"' + masterChefCallResponseList[i].hex.toString() + '",';
    }
    update();
  }

  @override
  void onInit() {
    init();
    super.onInit();
  }
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      init: HomeController(),
      builder: (h) => Scaffold(
        body: Stack(
          children: [
            Container(
              width: screenW(1, context),
              height: screenH(1, context),
              child: Image.network(
                "https://i.hizliresim.com/2a27s61.jpg",
                fit: BoxFit.fill,
              ),
            ),
            SingleChildScrollView(
              child: Container(
                child: Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(height: 40),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              MaterialButton(
                                onPressed: () {
                                  h.snapshot();
                                },
                                child: Container(
                                  color: Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text("Print Snapshot"),
                                  ),
                                ),
                              ),
                              MaterialButton(
                                onPressed: () {
                                  Clipboard.setData(
                                      ClipboardData(text: h.wallets));
                                  Get.snackbar("Copy", "Copied clipboard");
                                },
                                child: Container(
                                  color: Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text("Copy"),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 8.0, left: 100, right: 100),
                          child: Container(
                            child: SelectableText(
                              h.wallets ?? "wallets comes here",
                              style: fstylew(),
                            ),
                          ),
                        ),
                      ]),
                ),
              ),
            ),
            h.isLoading == true
                ? Container(
                    width: screenW(1, context),
                    height: screenH(1, context),
                    color: Colors.white.withOpacity(0.4),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          Text(
                            "This might take a while, please don't close this page.",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }

  TextStyle fstylew() => TextStyle(color: Colors.white, fontSize: 14);
  TextStyle fstyleb() => TextStyle(color: Colors.black, fontSize: 14);
  TextStyle scaleable(context) => TextStyle(
      color: Colors.black,
      fontSize: screenW(getScreenW(context) < 720 ? 0.035 : 0.01, context));
}

class secret extends StatelessWidget {
  const secret({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: screenW(getScreenW(context) < 720 ? 0.35 : 0.07, context),
          height: screenW(getScreenW(context) < 720 ? 0.45 : 0.07, context),
          child: Image.asset("assets/secret.png"),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(""),
        )
      ],
    );
  }
}
