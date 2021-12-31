import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'package:flutter_web3_example/abi.dart';
import 'package:flutter_web3_example/fcnp.dart';
import 'package:flutter_web3_example/multiCallAbi.dart';
import 'package:flutter_web3_example/newui.dart';
import 'package:flutter_web3_example/picture_model.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;

import 'helper.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      GetMaterialApp(title: 'Claim Page', home: Home());
}

class HomeController extends GetxController {
  bool get isInOperatingChain => currentChain == OPERATING_CHAIN;

  bool get isConnected => Ethereum.isSupported && currentAddress.isNotEmpty;

  String currentAddress = '';

  int currentChain = -1;

  bool wcConnected = false;

  bool isLoading = false;

  final wc = WalletConnectProvider.binance();

  String tokenURI = "";
  String tokenURI2 = "";
  bool showedNouns = false;

  List<Picture> youngApesNftPictures = [];
  List<Picture> fyoungApesNftPictures = [];
  List<Pictures> allPictures = [];

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

  static const OPERATING_CHAIN = 1;
  String chainError =
      'Wrong chain! Please connect to Main Ethereum Network. (1)';
  var youngApesContract;
  init() {
    if (Ethereum.isSupported) {
      connectProvider();

      ethereum!.onAccountsChanged((accs) {
        clear();
      });

      ethereum!.onChainChanged((chain) {
        clear();
      });
      youngApesContract = SmartContractBuilder(
          nftContractAddress: "0xC5aE96eF99832E0Cb8409877F47FbFed97004B79",
          //rink
          //0x0B51220AB29a78792e7A46Ca294416C93d6A0B6F
          //main
          //0xC5aE96eF99832E0Cb8409877F47FbFed97004B79
          multiCallContractAddress:
              "0x5BA1e12693Dc8F9c48aAD8770482f4739bEeD696",
          rpcAddress: ethereumRpcAddress,
          contractAbi: youngApesContractAbi,
          multCallAbi: multCallAbi);
    }
  }

  toggleSelected(index) {
    isLoading = true;
    update();
    if (youngApesNftPictures[index].selected == true) {
      //print(index.toString() + "false");
      youngApesNftPictures[index].selected = false;
      update();
    } else {
      // print(index.toString() + "true");
      youngApesNftPictures[index].selected = true;
    }
    isLoading = false;
    update();
  }

  getSymbol() async {
    try {
      String resp = await youngApesContract.contractCall("symbol", []);
      Get.snackbar("Token Symbol", resp);
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  ownerOf() async {
    try {
      String resp = await youngApesContract.contractCall("ownerOf", [1]);
      Get.snackbar("Owner Address", resp);
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  ipfsCall(dynamic contrat) async {
    try {
      String resp = await contrat.contractCall("baseURI", []);

      // String url = "https://ipfs.io/ipfs/" + resp.split("ipfs://")[1];
      var client = http.Client();
      try {
        print("url:");
        print('ipfs.io/ipfs/' + resp.split("ipfs://")[1] + "/1");
        var response = await client.get(
          Uri.https('ipfs.io', "/ipfs/" + resp.split("ipfs://")[1] + "/1"),
        );
        var decodedResponse =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map;
        for (var item in decodedResponse["image"].split("/")) {
          //print(item);
        }

        if (contrat == youngApesContract) {
          //print("CNP Contrat");
          tokenURI = "https://ipfs.io/ipfs/" +
              decodedResponse["image"].split("/")[2] +
              "/";
        } else {
          tokenURI2 = "https://ipfs.io/ipfs/" +
              decodedResponse["image"].split("/")[2] +
              "/";
          // print("FCNP Contrat");
        }
        // print("tokenUri Address: " + tokenURI + ".png");
        update();
      } finally {
        client.close();
      }
    } catch (e) {
      Get.snackbar("Error", "There is no Base Url");
    }
  }

  Future<int> totalSupply() async {
    try {
      var resp = await youngApesContract.contractCall("totalSupply", []);
      return int.parse(resp.toString());
    } catch (e) {
      Get.snackbar("Error", e.toString());
      return 0;
    }
  }

  Future<List<int>> whitelistedIdsOfWallet() async {
    try {
      var resp = await youngApesContract
          .contractCall("whitelistedIdsOfWallet", [currentAddress]);
      List<int> converted = [];
      for (var item in resp) {
        converted.add(int.parse(item.toString()));
      }
      return converted;
    } catch (e) {
      Get.snackbar("Error", e.toString());
      return [0];
    }
  }

  openURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  mintOneNFT({int? id}) async {
    isLoading = true;
    update();
    var contract = youngApesContract.createDeployedContract();

    print("____nft id___");

    print(id!);
    var data = youngApesContract
        .createData(contract, "claimYungApe", [BigInt.from(id)]);
    print("data created");
    var receipt = await youngApesContract.transection(data, 0);
    Get.snackbar("Recipt", receipt.blockHash);
    for (var item in allPictures) {
      item.cnpPicture?.selected = false;
    }
    await fetchAllPictures2();
    isLoading = false;
    update();
  }

  mintBulk({List<Picture>? idList}) async {
    isLoading = true;
    update();
    var contract = youngApesContract.createDeployedContract();

    //print("____Bulk nft ids___");
    List<BigInt>? array = [];
    for (var item in idList!) {
      array.add(BigInt.from(item.id!));
    }

    var data =
        youngApesContract.createData(contract, "claimYungApeMultiple", [array]);
    //print("data");
    //print(data);

    var receipt = await youngApesContract.transection(data, 0);
    Get.snackbar("Recipt", receipt.blockHash);
    for (var item in allPictures) {
      item.cnpPicture?.selected = false;
    }
    await fetchAllPictures2();
    isLoading = false;
    update();
  }

  Future<void> fetchAllPictures2() async {
    isLoading = true;
    update();
    List<int> tokenIds = await whitelistedIdsOfWallet();

    //ipfscall
    ipfsCall(youngApesContract);
    //multicall

    List<Call> masterChefCalls = [];
    for (var i in tokenIds) {
      masterChefCalls.add(Call(
          address: youngApesContract.nftContractAddress,
          name: 'isClaimed',
          params: [BigInt.from(i)]));
    }

    List<dynamic> masterChefCallResponseList = (await youngApesContract
            .multicall(youngApesContractAbi, masterChefCalls))
        .map((e) => e[0] as bool)
        .toList();

    for (var i = 0; i < masterChefCallResponseList.length; i++) {
      youngApesNftPictures.add(Picture(
          id: tokenIds[i],
          minted: masterChefCallResponseList[i],
          selected: false));
    }

    isLoading = false;
    update();
  }

  mintMyYoungApes() {
    var selectedPics =
        youngApesNftPictures.where((i) => i.selected == true).toList();
    //print("____");
    //print(selectedPics.length);
    for (var item in selectedPics) {
      //print("aa");
      //print(item.id);
    }
    if (selectedPics.isNotEmpty) {
      if (selectedPics.length > 1) {
        mintBulk(idList: selectedPics);
      } else if (selectedPics.length == 1) {
        print("mintone running " + selectedPics.first.id.toString());
        mintOneNFT(id: selectedPics.first.id);
      } else {
        Get.snackbar("Warning", "There is no selected Crypto Nouns");
      }
    }
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
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Container(
                margin: EdgeInsets.all(screenH(0.05, context)),
                width: screenW(0.995, context),
                padding: EdgeInsets.all(screenH(0.05, context)),
                constraints: BoxConstraints(minHeight: screenH(0.9, context)),
                decoration: BoxDecoration(
                    color: Colors.white,
                    image: DecorationImage(
                        image: AssetImage("assets/apeback.png"),
                        fit: BoxFit.cover),
                    borderRadius: BorderRadius.circular(40)),
                child: Center(
                  child: Column(children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                            onTap: () {
                              h.openURL("https://yungapesquad.com/");
                            },
                            child: Image.asset("assets/logo3.png")),
                      ],
                    ),
                    Container(height: 30),
                    Builder(builder: (_) {
                      var shown = '';
                      if (h.isConnected && h.isInOperatingChain) {
                        var isSelected = h.youngApesNftPictures
                            .where((element) => element.selected == true);
                        if (isSelected.isNotEmpty) {
                          return mintBox(
                              h.currentAddress.toString(),
                              "Mint My Yung Apes",
                              h.mintMyYoungApes,
                              sari,
                              context);
                        } else {
                          return mintBox(
                              h.currentAddress.toString(),
                              "Get My Mintable Yung Apes",
                              h.fetchAllPictures2,
                              mor,
                              context);
                        }
                      } else if (h.isConnected && !h.isInOperatingChain)
                        shown = h.chainError;
                      else if (Ethereum.isSupported)
                        return mintBox(
                            "Please Connect Your Wallet",
                            "Connect Wallet",
                            h.connectProvider,
                            kirmizi,
                            context);
                      else
                        shown =
                            "Your browser is not supported or you haven't got crypto wallet.";
                      return mintBox(
                          shown, "Connect Wallet", () {}, Colors.red, context);
                    }),
                    Container(height: 40),
                    if (h.isConnected && h.isInOperatingChain) ...[
                      h.youngApesNftPictures.length == 0
                          ? Container()
                          : Container(
                              width: screenW(
                                  getScreenW(context) < 720 ? 0.9 : 0.75,
                                  context),
                              child: GridView.count(
                                shrinkWrap: true,
                                crossAxisSpacing: 0,
                                primary: false,
                                crossAxisCount:
                                    getScreenW(context) < 720 ? 1 : 8,
                                childAspectRatio: 8 / 10,
                                children: List.generate(
                                    h.youngApesNftPictures.length, (index) {
                                  return Container(
                                    margin: EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                        //kirmizi
                                        //color: Colors.red,
                                        ),
                                    child: Container(
                                      width: screenW(
                                          getScreenW(context) < 720
                                              ? 0.1
                                              : 0.05,
                                          context),
                                      child: InkWell(
                                        onTap: () {
                                          if (h.youngApesNftPictures[index]
                                                  .minted ==
                                              false) h.toggleSelected(index);
                                        },
                                        child: Container(
                                          child: Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child: h.youngApesNftPictures
                                                    .isEmpty
                                                ? Container()
                                                : h.youngApesNftPictures[index]
                                                                .selected ==
                                                            true ||
                                                        h.youngApesNftPictures[index]
                                                                .minted ==
                                                            true
                                                    ? Stack(
                                                        children: [
                                                          Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              CachedNetworkImage(
                                                                imageUrl: h
                                                                        .tokenURI +
                                                                    h
                                                                        .youngApesNftPictures[
                                                                            index]
                                                                        .id
                                                                        .toString() +
                                                                    ".png",
                                                                placeholder: (context,
                                                                        url) =>
                                                                    new CircularProgressIndicator(),
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                            .all(
                                                                        8.0),
                                                                child: Text(
                                                                    "YungApes#" +
                                                                        h.youngApesNftPictures[index].id
                                                                            .toString(),
                                                                    style: scaleable(
                                                                        context)),
                                                              )
                                                            ],
                                                          ),
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child:
                                                                    Container(
                                                                  color: Colors
                                                                      .black
                                                                      .withOpacity(
                                                                          0.5),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          if (h
                                                                  .youngApesNftPictures[
                                                                      index]
                                                                  .minted ==
                                                              false)
                                                            Icon(
                                                              Icons
                                                                  .add_task_sharp,
                                                              color:
                                                                  Colors.yellow,
                                                              size: 48,
                                                            )
                                                        ],
                                                      )
                                                    : Stack(
                                                        children: [
                                                          Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              CachedNetworkImage(
                                                                imageUrl: h
                                                                        .tokenURI +
                                                                    h
                                                                        .youngApesNftPictures[
                                                                            index]
                                                                        .id
                                                                        .toString() +
                                                                    ".png",
                                                                placeholder: (context,
                                                                        url) =>
                                                                    new CircularProgressIndicator(),
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                            .all(
                                                                        8.0),
                                                                child: Text(
                                                                  "YungApes#" +
                                                                      h.youngApesNftPictures[index]
                                                                          .id
                                                                          .toString(),
                                                                  style: scaleable(
                                                                      context),
                                                                ),
                                                              )
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                    ],
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 16,
                            child: Container(),
                          ),
                          Expanded(
                              flex: 1,
                              child: InkWell(
                                  onTap: () {
                                    h.openURL(
                                        "https://twitter.com/yungapesquad");
                                  },
                                  child: Image.asset("assets/tw3.png"))),
                          Expanded(
                              flex: 2,
                              child: InkWell(
                                  onTap: () {
                                    h.openURL("https://discord.gg/yungapes");
                                  },
                                  child: Image.asset("assets/discord2.png"))),
                          Expanded(
                            flex: 16,
                            child: Container(),
                          )
                        ],
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
                : Container()
          ],
        ),
      ),
    );
  }

  Widget mintBox(
      String maintext, String buttonText, func, Color buttonColor, context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          margin: EdgeInsets.symmetric(
              horizontal:
                  screenW(getScreenW(context) < 1000 ? 0.04 : 0.2, context)),
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              maintext,
              style: TextStyle(
                  color: Colors.black,
                  fontSize: getScreenW(context) < 1000 ? 11 : 16),
            ),
          ),
        ),
        Container(
          height: 10,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: func,
              child: Container(
                color: buttonColor,
                margin: EdgeInsets.symmetric(
                    horizontal: screenW(
                        getScreenW(context) < 1000 ? 0.2 : 0.2, context)),
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    buttonText,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: getScreenW(context) < 1000 ? 11 : 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    /*   Container(
      width: screenW(getScreenW(context) < 720 ? 1 : 0.6, context),
      height: screenW(getScreenW(context) < 720 ? 0.4 : 0.18, context),
      decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(20))),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                  width:
                      screenW(getScreenW(context) < 720 ? 0.1 : 0.1, context),
                  child: Image.asset("assets/punk.png")),
              Container(
                color: Colors.white,
                width: screenW(getScreenW(context) < 720 ? 0.88 : 0.5, context),
                height: screenW(0.1, context),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      maintext,
                      style: fstyleb(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Container(
            width: 300,
            height: 80,
            child: Center(
              child: InkWell(
                onTap: func,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: 40,
                    constraints: BoxConstraints(minWidth: 120),
                    decoration: BoxDecoration(
                        color: buttonColor,
                        borderRadius: BorderRadius.circular(10)),
                    child: Center(
                      child: Text(
                        buttonText,
                        style: fstylew(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
   */
  }

  TextStyle fstylew() => TextStyle(color: Colors.white, fontSize: 14);
  TextStyle fstyleb() => TextStyle(color: Colors.black, fontSize: 14);
  TextStyle scaleable(context) => TextStyle(
      color: Colors.white,
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
