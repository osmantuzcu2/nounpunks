//Functions
import 'package:flutter/material.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'package:get/get.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart' as web3;
import 'package:convert/convert.dart';

//Toast message
//Toast.show('Toast plugin app', context, duration: Toast.LENGTH_SHORT, gravity:  Toast.BOTTOM);
final Color koyu = HexColor('#241635');
final Color yesil = HexColor('#45ff83');
final Color yapeBlack = HexColor('#202020');
final Color yapeBack = HexColor('#E5E5E5');

class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF' + hexColor;
    }
    return int.parse(hexColor, radix: 16);
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}

//cihazın genişliğini al
double screenW(double wwidth, context) {
  return MediaQuery.of(context).size.width * wwidth;
}

double getScreenW(context) {
  return MediaQuery.of(context).size.width;
}

double getScreenH(context) {
  return MediaQuery.of(context).size.height;
}

//cihazın yüksekliğini al
double screenH(double hheight, context) {
  return MediaQuery.of(context).size.height * hheight;
}

//duration only hh:mm:nn
String formatDur(Duration d) => d.toString().split('.').first.padLeft(8, '0');

//exit
Widget areYouSure(context, String text, Function func) {
  return AlertDialog(
    title: Text('Emin misiniz?'),
    content: Text(text),
    actions: <Widget>[
      TextButton(
        onPressed: () => Get.back(),
        child: Text('Hayır'),
      ),
      TextButton(
        onPressed: () => func,
        child: Text('Evet'),
      ),
    ],
  );
}

class SmartContractBuilder {
  String nftContractAddress;
  String multiCallContractAddress;
  String rpcAddress;
  String contractAbi;
  String multCallAbi;

  SmartContractBuilder(
      {required this.nftContractAddress,
      required this.multiCallContractAddress,
      required this.rpcAddress,
      required this.contractAbi,
      required this.multCallAbi});

  Future<dynamic> contractCall(String callFunc, List<dynamic> params) async {
    final contract = Contract(
      nftContractAddress,
      contractAbi,
      provider!,
    );
    var response = await contract.call<dynamic>(callFunc, params);
    print(response.toString());
    return response;
  }

  contractCall2(String callFunc, List<dynamic> params) async {
    print("===========1==========");
    final contract = Contract(
      nftContractAddress,
      contractAbi,
      provider!,
    );

    print("===========2==========");
    var resp = await contract.call<dynamic>(callFunc);

    print(resp.toString());
  }

  web3.DeployedContract createDeployedContract() {
    return web3.DeployedContract(
        web3.ContractAbi.fromJson(contractAbi, nftContractAddress),
        web3.EthereumAddress.fromHex(nftContractAddress));
  }

  String createData(
      web3.DeployedContract contract, String func, List<dynamic> params) {
    return hex.encode(contract.function(func).encodeCall(params));
  }

  Future<TransactionReceipt> transection(
    String data,
    num value,
  ) async {
    final tx = await provider!.getSigner().sendTransaction(
          TransactionRequest(
            to: nftContractAddress,
            data: "0x" + data,
            value: BigInt.from(value),
          ),
        );

    return await tx.wait();
  }

  Future<List<dynamic>> multicall(String abi, List<Call> calls) async {
    String multicallAddress =
        multiCallContractAddress; //"0x5BA1e12693Dc8F9c48aAD8770482f4739bEeD696";
    var httpClient = new Client();
    var ethClient = new web3.Web3Client(
        rpcAddress, //"https://rinkeby.infura.io/v3/bc8e705aa911430ebd8dc6a63fb15efb",
        httpClient);

    final multicallContract = web3.DeployedContract(
        web3.ContractAbi.fromJson(multCallAbi, "multicall"),
        web3.EthereumAddress.fromHex(multicallAddress));

    final aggregateMethod = multicallContract.function("tryAggregate");

    final itf = web3.ContractAbi.fromJson(abi, "");
    var callData = calls
        .map((call) => [
              web3.EthereumAddress.fromHex(call.address),
              itf.functions
                  .firstWhere((element) => element.name == call.name)
                  .encodeCall(call.params!)
            ])
        .toList();
    //print("calls created");
    final returnData = await ethClient.call(
        contract: multicallContract,
        function: aggregateMethod,
        params: [false, callData]);
    //print("got response");
    //print(returnData);
    var callResponses = returnData[0] as List<dynamic>;
    var decodedCallResponses = calls
        .asMap()
        .map((key, value) => MapEntry(
            key,
            itf.functions
                .firstWhere((element) => element.name == value.name)
                .decodeReturnValues(hex.encode(callResponses[key][1]))))
        .values
        .toList();
    // print("response decoded");
    return decodedCallResponses;
  }
}

class Call {
  String address;
  String name;
  List<dynamic>? params;

  Call({this.address = "", this.name = "", this.params});
}
