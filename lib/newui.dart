import 'package:flutter/material.dart';
import 'package:flutter_web3_example/helper.dart';

class Home2 extends StatelessWidget {
  const Home2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade400,
      body: Stack(
        children: [
          Container(
            margin: EdgeInsets.all(screenH(0.05, context)),
            width: screenW(0.995, context),
            height: screenH(0.995, context),
            padding: EdgeInsets.all(screenH(0.05, context)),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(40)),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(flex: 1, child: Image.asset("assets/logo2.png")),
                    Expanded(flex: 2, child: Image.asset("assets/logo1.png")),
                    Expanded(
                      flex: getScreenW(context) < 720 ? 5 : 16,
                      child: Container(),
                    )
                  ],
                ),
                Container(
                  color: yapeBlack,
                  margin: EdgeInsets.symmetric(
                      horizontal: screenW(
                          getScreenW(context) < 1000 ? 0.04 : 0.2, context)),
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      "Connected : 0x5181afAb9adBBb4F8bF77AE1f749d6F5D52d15ee",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: getScreenW(context) < 1000 ? 11 : 16),
                    ),
                  ),
                ),
                Container(
                  height: 10,
                ),
                Container(
                  color: yapeBlack,
                  margin: EdgeInsets.symmetric(
                      horizontal: screenW(
                          getScreenW(context) < 1000 ? 0.2 : 0.4, context)),
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      "Connect Wallet",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: getScreenW(context) < 1000 ? 11 : 16),
                    ),
                  ),
                ),
                Container(
                  height: 10,
                ),
                Container(
                  height: screenH(0.4, context),
                  child: SingleChildScrollView(
                    child: Container(
                      child: GridView.count(
                        shrinkWrap: true,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        crossAxisCount: getScreenW(context) < 1000 ? 4 : 12,
                        childAspectRatio: 1,
                        children: [
                          Container(
                            color: Colors.grey,
                          ),
                          Container(
                            color: Colors.grey,
                          ),
                          Container(
                            color: Colors.grey,
                          ),
                          Container(
                            color: Colors.grey,
                          ),
                          Container(
                            color: Colors.grey,
                          ),
                          Container(
                            color: Colors.grey,
                          ),
                          Container(
                            color: Colors.grey,
                          ),
                          Container(
                            color: Colors.grey,
                          ),
                          Container(
                            color: Colors.grey,
                          ),
                          Container(
                            color: Colors.grey,
                          ),
                          Container(
                            color: Colors.grey,
                          ),
                          Container(
                            color: Colors.grey,
                          ),
                          Container(
                            color: Colors.grey,
                          ),
                          Container(
                            color: Colors.grey,
                          ),
                          Container(
                            color: Colors.grey,
                          ),
                          Container(
                            color: Colors.grey,
                          ),
                          Container(
                            color: Colors.grey,
                          ),
                          Container(
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 16,
                        child: Container(),
                      ),
                      Expanded(flex: 1, child: Image.asset("assets/tw.png")),
                      Expanded(
                          flex: 2, child: Image.asset("assets/discord.png")),
                      Expanded(
                        flex: 16,
                        child: Container(),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
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
        ],
      ),
    );
  }
}
