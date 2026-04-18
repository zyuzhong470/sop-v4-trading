import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;

void main() => runApp(MaterialApp(theme: ThemeData.dark(), home: const SopPage()));

class SopPage extends StatefulWidget {
  const SopPage({super.key});
  @override
  State<SopPage> createState() => _SopPageState();
}

class _SopPageState extends State<SopPage> {
  String log = "等待指令...";
  
  // 安全读取环境变量
  final String apiKey = const String.fromEnvironment('API_KEY');
  final String apiSecret = const String.fromEnvironment('API_SECRET');
  final String passphrase = const String.fromEnvironment('PASSPHRASE');

  Future<void> _trade(String side) async {
    setState(() => log = "正在发送 $side 指令...");
    
    try {
      // 构造符合 OKX 标准的 ISO 时间戳
      String ts = DateTime.now().toUtc().toIso8601String();
      String method = "POST";
      String requestPath = "/api/v5/trade/order";
      
      // 构造交易参数
      Map<String, String> bodyMap = {
        "instId": "DOGE-USDT-SWAP",
        "tdMode": "cross",
        "side": side,
        "ordType": "market",
        "sz": "100"
      };
      String body = jsonEncode(bodyMap);

      // 生成签名
      String message = ts + method + requestPath + body;
      var hmac = crypto.Hmac(crypto.sha256, utf8.encode(apiSecret));
      String sign = base64.encode(hmac.convert(utf8.encode(message)).bytes);

      // 发送请求
      final res = await http.post(
        Uri.parse("https://aws.okx.com$requestPath"),
        headers: {
          "OK-ACCESS-KEY": apiKey,
          "OK-ACCESS-SIGN": sign,
          "OK-ACCESS-TIMESTAMP": ts,
          "OK-ACCESS-PASSPHRASE": passphrase,
          "Content-Type": "application/json",
        },
        body: body,
      );

      setState(() => log = "结果: ${res.body}");
    } catch (e) {
      setState(() => log = "错误: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SOP v4.0 28U终端")),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              child: SingleChildScrollView(child: Text(log, style: const TextStyle(color: Colors.greenAccent))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: () => _trade("buy"), child: const Text("买入"))),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(onPressed: () => _trade("sell"), child: const Text("卖出"))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
