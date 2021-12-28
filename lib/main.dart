import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'package:flutter_web3_example/abi.dart';
import 'package:flutter_web3_example/fcnp.dart';
import 'package:flutter_web3_example/multiCallAbi.dart';
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
      GetMaterialApp(title: 'Flip Your Crypto Nouns', home: Home());
}

class HomeController extends GetxController {
  bool get isInOperatingChain => currentChain == OPERATING_CHAIN;

  bool get isConnected => Ethereum.isSupported && currentAddress.isNotEmpty;

  String currentAddress = '';

  int currentChain = -1;

  bool wcConnected = false;

  bool isLoading = false;

  static const OPERATING_CHAIN = 4;

  final wc = WalletConnectProvider.binance();

  String tokenURI = "";
  String tokenURI2 = "";
  bool showedNouns = false;

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

  var cnpContract;
  var fcnpContract;
  init() {
    if (Ethereum.isSupported) {
      connectProvider();

      ethereum!.onAccountsChanged((accs) {
        clear();
      });

      ethereum!.onChainChanged((chain) {
        clear();
      });
      cnpContract = SmartContractBuilder(
          nftContractAddress: "0x0B51220AB29a78792e7A46Ca294416C93d6A0B6F",
          multiCallContractAddress:
              "0x5BA1e12693Dc8F9c48aAD8770482f4739bEeD696",
          rpcAddress:
              "https://rinkeby.infura.io/v3/bc8e705aa911430ebd8dc6a63fb15efb",
          contractAbi: youngApesContractAbi,
          multCallAbi: multCallAbi);

      fcnpContract = SmartContractBuilder(
          nftContractAddress: "0x0B51220AB29a78792e7A46Ca294416C93d6A0B6F",
          multiCallContractAddress:
              "0x5BA1e12693Dc8F9c48aAD8770482f4739bEeD696",
          rpcAddress:
              "https://rinkeby.infura.io/v3/bc8e705aa911430ebd8dc6a63fb15efb",
          contractAbi: youngApesContractAbi,
          multCallAbi: multCallAbi);
    }
  }

  toggleSelected(index) {
    isLoading = true;
    update();
    if (allPictures[index].cnpPicture!.selected == true) {
      //print(index.toString() + "false");
      allPictures[index].cnpPicture!.selected = false;
      update();
    } else {
      // print(index.toString() + "true");
      allPictures[index].cnpPicture!.selected = true;
    }
    isLoading = false;
    update();
  }

  getSymbol() async {
    try {
      String resp = await cnpContract.contractCall("symbol", []);
      Get.snackbar("Token Symbol", resp);
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  ownerOf() async {
    try {
      String resp = await cnpContract.contractCall("ownerOf", [1]);
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

        if (contrat == cnpContract) {
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
      Get.snackbar("Error", "Any minted NFT");
    }
  }

  Future<int> totalSupply() async {
    try {
      var resp = await cnpContract.contractCall("totalSupply", []);
      return int.parse(resp.toString());
    } catch (e) {
      Get.snackbar("Error", e.toString());
      return 0;
    }
  }

  Future<List<dynamic>> whitelistedIdsOfWallet() async {
    try {
      var resp = await cnpContract
          .contractCall("whitelistedIdsOfWallet", [currentAddress]);
      return resp;
    } catch (e) {
      Get.snackbar("Error", e.toString());
      return [BigInt.zero];
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
    var contract = fcnpContract.createDeployedContract();

    //print("____nft id___");

    print(id!);
    var data = fcnpContract.createData(contract, "mintOne", [BigInt.from(id)]);

    var receipt = await fcnpContract.transection(data, 0);
    Get.snackbar("Recipt", receipt.blockHash);
    for (var item in allPictures) {
      item.cnpPicture?.selected = false;
    }
    await fetchAllPictures();
    isLoading = false;
    update();
  }

  mintBulk({List<Pictures>? idList}) async {
    isLoading = true;
    update();
    var contract = fcnpContract.createDeployedContract();

    //print("____Bulk nft ids___");
    List<BigInt>? array = [];
    for (var item in idList!) {
      array.add(BigInt.from(item.cnpPicture!.id!));
    }

    var data = fcnpContract.createData(contract, "mintBulk", [array]);
    //print("data");
    //print(data);

    var receipt = await fcnpContract.transection(data, 0);
    Get.snackbar("Recipt", receipt.blockHash);
    for (var item in allPictures) {
      item.cnpPicture?.selected = false;
    }
    await fetchAllPictures();
    isLoading = false;
    update();
  }

  List<Picture> cnpNftPictures = [];
  List<Picture> fcnpNftPictures = [];
  List<Pictures> allPictures = [];
  Future<void> fetchAddresses(
      dynamic contract, String contractabi, List<Picture> pictures) async {
    isLoading = true;
    update();
    ipfsCall(contract);
    int totalSupp = await totalSupply();
    if (totalSupp != 0) {
      pictures.clear();
      List<int> nftS = List<int>.generate(totalSupp, (i) => i + 1);
      List<Call> masterChefCalls = [];
      //print(totalSupp);
      //print("numbers : " + nftS[0].toString());
      for (var item in nftS) {
        masterChefCalls.add(Call(
            address: contract.nftContractAddress,
            name: 'ownerOf',
            params: [BigInt.from(item)]));
      }
      //print("NFT piece : " + masterChefCalls.length.toString());
      List<dynamic> masterChefCallResponseList =
          (await contract.multicall(contractabi, masterChefCalls))
              .map((e) => e[0] as EthereumAddress)
              .toList();
      // print("owned NFTs");
      //yeni
      if (contract == fcnpContract) {
        //print("this is a fcnp contract");
        for (var item in cnpNftPictures) {
          //print("fora giriyor mu?");
          int i = 0;

          if (item.id != null) {
            //print("there is a id for cnp contract");
            i = item.id! - 1;
            String owner = await masterChefCallResponseList[i].hex;
            //print("owner" + owner);
            if (owner == currentAddress ||
                owner == "0x0000000000000000000000000000000000000000") {
              if (owner == "0x0000000000000000000000000000000000000000") {
                print("fcnp 00000 address founded");
                pictures
                    .add(Picture(id: item.id, selected: false, minted: false));
                print(pictures.last.minted);
              } else
                pictures.add(Picture(id: item.id, selected: false));
              //print("owner == currentAddress");
            } else {
              cnpNftPictures
                  .where((element) => element.id == item.id)
                  .first
                  .transferred = true;
              print("removed: " + item.id.toString());
            }
          } else {
            //print("ne oluyor " + item.address.toString());
          }
        }
      } else
        //print("this is a cnp contract");
        for (var i = 0; i < masterChefCallResponseList.length; i++) {
          if (currentAddress == masterChefCallResponseList[i].hex) {
            // print("id:" + (i + 1).toString());
            //print("address:" + masterChefCallResponseList[i].hex);
            pictures.add(Picture(id: i + 1, selected: false));
          }
        }
      /*  print("****************AllPictures******************");
      for (var all in allPictures) {
        print("cnp" + all.cnpPicture!.id.toString());
        if (all.fcnpPicture != null)
          print("fcnp" + all.fcnpPicture!.id.toString());
        else
          print(" fcnpnull");
      }
 */
      showedNouns = true;
      isLoading = false;
      update();
    }
  }

  matchNfts(List<Picture> cnp, List<Picture> fcnp) {
    if (cnp.isNotEmpty) {
      for (var item in cnp) {
        if (item.id != null && item.transferred != true) {
          var isHaveFcnp = fcnp.where((element) {
            return element.id == item.id;
          });
          if (isHaveFcnp.isNotEmpty) {
            allPictures.add(Pictures(
                cnpPicture: Picture(
                    id: item.id, name: item.name, selected: item.selected),
                fcnpPicture: Picture(
                    id: isHaveFcnp.first.id,
                    name: isHaveFcnp.first.name,
                    selected: isHaveFcnp.first.selected,
                    minted: isHaveFcnp.first.minted)));
          } else {
            allPictures.add(Pictures(
              cnpPicture: Picture(
                  id: item.id, name: item.name, selected: item.selected),
            ));
          }
        }
      }
      print("****************AllPictures******************");
      print("all pics piece:" + allPictures.length.toString());
      for (var all in allPictures) {
        print("cnp" + all.cnpPicture!.id.toString());
        if (all.fcnpPicture != null) {
          print("fcnp" + all.fcnpPicture!.id.toString());
          print("fcnp minted: " + all.fcnpPicture!.minted.toString());
        } else
          print(" fcnpnull");
      }
    }
  }

  Future<void> fetchAllPictures() async {
    await fetchAddresses(cnpContract, youngApesContractAbi, cnpNftPictures);

    for (var item in cnpNftPictures) {
      print(item.id);
    }

    await fetchAddresses(fcnpContract, fcnpAbi, fcnpNftPictures);
    allPictures.clear();
    matchNfts(cnpNftPictures, fcnpNftPictures);
  }

  flipMyNouns() {
    var selectedPics =
        allPictures.where((i) => i.cnpPicture?.selected == true).toList();
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
        //print("mintone running");
        mintOneNFT(id: selectedPics.first.cnpPicture?.id);
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
            /* Container(
              width: screenW(1, context),
              height: screenH(1, context),
              child: Center(
                child: mintBox(
                    "Welcome to Crypto Noun Punk's flip page. Please Connect your wallet."),
              ),
            ), */
            SingleChildScrollView(
              child: Container(
                child: Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(height: 10),
                        Builder(builder: (_) {
                          var shown = '';
                          if (h.isConnected && h.isInOperatingChain) {
                            Iterable<Pictures> isSelected = h.allPictures.where(
                                (element) =>
                                    element.cnpPicture!.selected == true);
                            if (h.showedNouns == true &&
                                isSelected.isNotEmpty) {
                              return mintBox(
                                  h.currentAddress.toString(),
                                  "Flip My Crypto Nouns",
                                  h.flipMyNouns,
                                  Colors.yellow.shade900,
                                  context);
                            } else {
                              return mintBox(
                                  h.currentAddress.toString(),
                                  "whitelistedIdsOfWallet",
                                  h.whitelistedIdsOfWallet,
                                  Colors.green,
                                  context);
                            }
                          } else if (h.isConnected && !h.isInOperatingChain)
                            shown =
                                'Wrong chain! Please connect to Rinkeby Ethereum Network. (4)';
                          else if (Ethereum.isSupported)
                            return mintBox(
                                "Please Connect Your Wallet",
                                "Connect Wallet",
                                h.connectProvider,
                                Colors.red,
                                context);
                          else
                            shown =
                                "Your browser is not supported or you haven't got crypto wallet.";
                          return mintBox(shown, "Connect Wallet", () {},
                              Colors.red, context);
                        }),
                        Container(height: 40),
                        if (h.isConnected && h.isInOperatingChain) ...[
                          h.cnpNftPictures.length == 0
                              ? Container()
                              : Container(
                                  width: screenW(
                                      getScreenW(context) < 720 ? 0.9 : 0.75,
                                      context),
                                  child: GridView.count(
                                    shrinkWrap: true,
                                    crossAxisSpacing: 4,
                                    primary: false,
                                    crossAxisCount:
                                        getScreenW(context) < 720 ? 1 : 3,
                                    childAspectRatio: 10 / 6,
                                    children: List.generate(
                                        h.allPictures.length, (index) {
                                      return Container(
                                        margin: EdgeInsets.all(2),
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: screenW(
                                                  getScreenW(context) < 720
                                                      ? 0.35
                                                      : 0.1,
                                                  context),
                                              height: screenW(
                                                  getScreenW(context) < 720
                                                      ? 0.45
                                                      : 0.15,
                                                  context),
                                              child: InkWell(
                                                onTap: () {
                                                  if (h
                                                          .allPictures[index]
                                                          .fcnpPicture!
                                                          .minted ==
                                                      false)
                                                    h.toggleSelected(index);
                                                },
                                                child: Container(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            4.0),
                                                    child: h.allPictures.isEmpty
                                                        ? Container()
                                                        : h
                                                                    .allPictures[
                                                                        index]
                                                                    .cnpPicture
                                                                    ?.selected ==
                                                                true
                                                            ? Stack(
                                                                children: [
                                                                  Column(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      CachedNetworkImage(
                                                                        imageUrl: h.tokenURI +
                                                                            h.allPictures[index].cnpPicture!.id.toString() +
                                                                            ".png",
                                                                        placeholder:
                                                                            (context, url) =>
                                                                                new CircularProgressIndicator(),
                                                                      ),
                                                                      Padding(
                                                                        padding:
                                                                            const EdgeInsets.all(8.0),
                                                                        child: Text(
                                                                            "CNP#" +
                                                                                h.allPictures[index].cnpPicture!.id.toString(),
                                                                            style: scaleable(context)),
                                                                      )
                                                                    ],
                                                                  ),
                                                                  Row(
                                                                    children: [
                                                                      Expanded(
                                                                        child:
                                                                            Container(
                                                                          color: Colors
                                                                              .white
                                                                              .withOpacity(0.5),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  Icon(
                                                                    Icons
                                                                        .add_task_sharp,
                                                                    color: Colors
                                                                        .yellow,
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
                                                                        imageUrl: h.tokenURI +
                                                                            h.allPictures[index].cnpPicture!.id.toString() +
                                                                            ".png",
                                                                        placeholder:
                                                                            (context, url) =>
                                                                                new CircularProgressIndicator(),
                                                                      ),
                                                                      Padding(
                                                                        padding:
                                                                            const EdgeInsets.all(8.0),
                                                                        child:
                                                                            Text(
                                                                          "CNP#" +
                                                                              h.allPictures[index].cnpPicture!.id.toString(),
                                                                          style:
                                                                              scaleable(context),
                                                                        ),
                                                                      )
                                                                    ],
                                                                  ),
                                                                  if (h
                                                                          .allPictures[
                                                                              index]
                                                                          .fcnpPicture!
                                                                          .minted !=
                                                                      false)
                                                                    Row(
                                                                      children: [
                                                                        Expanded(
                                                                          child:
                                                                              Container(
                                                                            color:
                                                                                Colors.white.withOpacity(0.5),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    )
                                                                ],
                                                              ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            h.allPictures.isEmpty ||
                                                    h
                                                            .allPictures[index]
                                                            .fcnpPicture!
                                                            .minted ==
                                                        false
                                                ? Icon(
                                                    Icons.change_circle,
                                                    color: Colors.green,
                                                    size: 36,
                                                  )
                                                : Icon(
                                                    Icons.change_circle,
                                                    color: Colors.grey,
                                                    size: 36,
                                                  ),
                                            h.tokenURI2 == ""
                                                ? secret()
                                                : h.allPictures.isEmpty ||
                                                        h
                                                                .allPictures[
                                                                    index]
                                                                .fcnpPicture!
                                                                .minted ==
                                                            false
                                                    ? secret()
                                                    : Container(
                                                        width: screenW(
                                                            getScreenW(context) <
                                                                    720
                                                                ? 0.35
                                                                : 0.1,
                                                            context),
                                                        height: screenW(
                                                            getScreenW(context) <
                                                                    720
                                                                ? 0.45
                                                                : 0.15,
                                                            context),
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            InkWell(
                                                              onTap: () {
                                                                print("https://opensea.io/assets/0x88525c2c15328c3fe20def1868c3a7e8702b06b3/" +
                                                                    h
                                                                        .allPictures[
                                                                            index]
                                                                        .fcnpPicture!
                                                                        .id
                                                                        .toString());
                                                                h.openURL("https://opensea.io/assets/0x88525c2c15328c3fe20def1868c3a7e8702b06b3/" +
                                                                    h
                                                                        .allPictures[
                                                                            index]
                                                                        .fcnpPicture!
                                                                        .id
                                                                        .toString());
                                                              },
                                                              child:
                                                                  CachedNetworkImage(
                                                                imageUrl: h
                                                                        .tokenURI2 +
                                                                    h
                                                                        .allPictures[
                                                                            index]
                                                                        .fcnpPicture!
                                                                        .id
                                                                        .toString() +
                                                                    ".png",
                                                                placeholder: (context,
                                                                        url) =>
                                                                    new CircularProgressIndicator(),
                                                              ),
                                                            ),
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(8.0),
                                                              child: Text(
                                                                "FCNP#" +
                                                                    h
                                                                        .allPictures[
                                                                            index]
                                                                        .fcnpPicture!
                                                                        .id
                                                                        .toString(),
                                                                style: scaleable(
                                                                    context),
                                                              ),
                                                            )
                                                          ],
                                                        ),
                                                      )
                                          ],
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                        ],
                        Container(height: 30),
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
    return Container(
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
