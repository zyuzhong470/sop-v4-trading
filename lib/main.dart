import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart' as crypto; // 修复引用

// 安全读取模式
const String apiKey = String.fromEnvironment('API_KEY');
const String apiSecret = String.fromEnvironment('API_SECRET');
const String passphrase = String.fromEnvironment('PASSPHRASE');

void main() => runApp(MaterialApp(theme: ThemeData.dark(), home: const SopPage()));

class SopPage extends StatefulWidget {
  const SopPage({super.key});
  @override
  State<SopPage> createState() => _SopPageState();
}

class _SopPageState extends State<SopPage> {
  String log = "等待指令...";

  Future<void> _trade(String side) async {
    String ts = DateTime.now().toUtc().toIso8601String().split('.').first + "Z";
    // 修复 sha256 报错逻辑
    var sign = base64.encode(crypto.Hmac(crypto.sha256, utf8.encode(apiSecret)).convert(utf8.encode(ts + "POST" + "/api/v5/trade/order" + jsonEncode({"instId":"DOGE-USDT-SWAP","tdMode":"cross","side":side,"ordType":"market","sz":"100"}))).bytes);
    
    try {
      final res = await http.post(Uri.parse("https://www.okx.com/api/v5/trade/order"), headers: {"OK-ACCESS-KEY":apiKey,"OK-ACCESS-SIGN":sign,"OK-ACCESS-TIMESTAMP":ts,"OK-ACCESS-PASSPHRASE":passphrase,"Content-Type":"application/json"}, body: jsonEncode({"instId":"DOGE-USDT-SWAP","tdMode":"cross","side":side,"ordType":"market","sz":"100"}));
      setState(() => log = res.body);
    } catch (e) {
      setState(() => log = "错误: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SOP v4.0 28U终端")),
      body: Column(children: [
        Expanded(child: Container(color: Colors.black, width: double.infinity, padding: const EdgeInsets.all(10), child: SingleChildScrollView(child: Text(log, style: const TextStyle(color: Colors.greenAccent))))),
        Padding(padding: const EdgeInsets.all(20), child: Row(children: [
          Expanded(child: ElevatedButton(onPressed: () => _trade("buy"), child: const Text("买入"))),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton(onPressed: () => _trade("sell"), child: const Text("卖出"))),
        ])),
      ]),
    );
  }
}

