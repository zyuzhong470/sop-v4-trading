import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: const TradingTerminal(),
    );
  }
}

class TradingTerminal extends StatefulWidget {
  const TradingTerminal({super.key});

  @override
  State<TradingTerminal> createState() => _TradingTerminalState();
}

class _TradingTerminalState extends State<TradingTerminal> {
  // 从环境变量读取密钥 (保持 GitHub Actions 安全性)
  final String apiKey = const String.fromEnvironment('API_KEY');
  final String apiSecret = const String.fromEnvironment('API_SECRET');
  
  // 币安亚太加速域名
  final String baseUrl = "https://api1.binance.com"; 
  String statusMessage = "等待指令 (DOGEUSDT)";

  // 币安签名算法 (HMAC SHA256)
  String generateSignature(String queryString) {
    var key = utf8.encode(apiSecret);
    var bytes = utf8.encode(queryString);
    var hmac = crypto.Hmac(crypto.sha256, key);
    return hmac.convert(bytes).toString();
  }

  Future<void> placeOrder(String side) async {
    setState(() => statusMessage = "正在发送 $side 指令...");

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      
      // 币安市价单参数：交易对、方向、类型、数量、时间戳
      // 注意：quantity 100 代表 100 个 DOGE，请确保 30U 够用
      String queryString = "symbol=DOGEUSDT&side=$side&type=MARKET&quantity=100&timestamp=$timestamp";
      String signature = generateSignature(queryString);
      
      final url = Uri.parse("$baseUrl/api/v3/order?$queryString&signature=$signature");

      final response = await http.post(
        url,
        headers: {
          'X-MBX-APIKEY': apiKey,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        setState(() => statusMessage = "交易成功！订单ID: ${data['orderId']}");
      } else {
        setState(() => statusMessage = "失败: ${data['msg']}");
      }
    } catch (e) {
      setState(() => statusMessage = "网络错误: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SOP v4.0 币安版")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
              child: Text(statusMessage, style: const TextStyle(color: Colors.greenAccent, fontSize: 16)),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => placeOrder("BUY"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20)),
                  child: const Text("买入 (DOGE)"),
                ),
                ElevatedButton(
                  onPressed: () => placeOrder("SELL"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20)),
                  child: const Text("卖出 (DOGE)"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
