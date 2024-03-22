import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme(bool isOn) {
    setState(() {
      _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto Trends',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      themeMode: _themeMode,
      home: CryptoDataScreen(toggleTheme: toggleTheme),
    );
  }
}

class CryptoDataScreen extends StatefulWidget {
  final Function(bool) toggleTheme;

  const CryptoDataScreen({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  State<CryptoDataScreen> createState() => _CryptoDataScreenState();
}

class _CryptoDataScreenState extends State<CryptoDataScreen> {
  late Future<List<CryptoCategory>> cryptoCategoriesFuture;
  String lastRefreshed = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  Future<void> refreshData() async {
    setState(() {
      lastRefreshed = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      cryptoCategoriesFuture = fetchCryptoData(forceRefresh: true);
    });
  }

  Future<List<CryptoCategory>> fetchCryptoData({bool forceRefresh = false}) async {
    const String url = "https://api.bybit.com/derivatives/v3/public/tickers";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['retCode'] == 0) {
        final List<dynamic> items = data['result']['list'];
        final cryptoList = items.map((item) => CryptoData.fromJson(item))
            .where((item) => item.volume24h > 100000000) // Filter by volume
            .toList();
        return categorizeAndSortCryptoData(cryptoList);
      } else {
        throw Exception('Failed to load data: ${data['retMsg']}');
      }
    } else {
      throw Exception('Failed to fetch data');
    }
  }


  List<CryptoCategory> categorizeAndSortCryptoData(List<CryptoData> data) {
    // Sort allCoins list by price24hPcnt from highest to lowest
    List<CryptoData> allCoins = List.from(data);
    allCoins.sort((a, b) => b.price24hChange.compareTo(a.price24hChange));

    // Initialize lists for different categories
    List<CryptoData> bullishDips = [];
    List<CryptoData> bearishRebounds = [];
    List<CryptoData> bullishTrends = [];
    List<CryptoData> bearishTrends = [];

    // Iterate through sorted allCoins list to categorize
    for (var item in allCoins) {
      if (item.price24hChange > 0 && item.price1hChange > 0) {
        bullishTrends.add(item);
      } else if (item.price24hChange < 0 && item.price1hChange < 0) {
        bearishTrends.add(item);
      } else if (item.price24hChange > 0 && item.price1hChange < 0) {
        bullishDips.add(item);
      } else if (item.price24hChange < 0 && item.price1hChange > 0) {
        bearishRebounds.add(item);
      }
    }

    // Sort bearishTrends list by price24hPcnt from most negative to least negative
    bearishTrends.sort((a, b) => a.price24hChange.compareTo(b.price24hChange));
    bearishRebounds.sort((a, b) => a.price24hChange.compareTo(b.price24hChange));

    // Order categories according to the specified order
    List<CryptoCategory> categories = [
      CryptoCategory(name: 'Bullish Dips', data: bullishDips),
      CryptoCategory(name: 'Bearish Rebounds', data: bearishRebounds),
      CryptoCategory(name: 'Bullish Trends', data: bullishTrends),
      CryptoCategory(name: 'Bearish Trends', data: bearishTrends),
      CryptoCategory(name: 'All Coins', data: allCoins),
    ];

    return categories;
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crypto Trends'),
        actions: [
          Switch(
            value: Theme.of(context).brightness == Brightness.dark,
            onChanged: (value) {
              widget.toggleTheme(value);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refreshData,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Last refreshed: $lastRefreshed"),
            ),
            Expanded(
              child: FutureBuilder<List<CryptoCategory>>(
                future: cryptoCategoriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    return ListView(
                      children: snapshot.data!.map((category) => CryptoCategoryCard(category: category)).toList(),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CryptoCategoryCard extends StatelessWidget {
  final CryptoCategory category;

  const CryptoCategoryCard({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              category.name,
              style: Theme.of(context).textTheme.headline6,
            ),
            const SizedBox(height: 8.0),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(2),
                4: FlexColumnWidth(3),
              },
              children: [
                const TableRow(
                  children: [
                    Padding(padding: EdgeInsets.all(8.0), child: SelectableText('Symbol')),
                    Padding(padding: EdgeInsets.all(8.0), child: SelectableText('Price')),
                    Padding(padding: EdgeInsets.all(8.0), child: SelectableText('24h Change')),
                    Padding(padding: EdgeInsets.all(8.0), child: SelectableText('1h Change')),
                    Padding(padding: EdgeInsets.all(8.0), child: SelectableText('24h Volume')),
                  ],
                ),
                ...category.data.map((crypto) => TableRow(
                  children: [
                    Padding(padding: const EdgeInsets.all(8.0), child: SelectableText(crypto.symbol)),
                    Padding(padding: const EdgeInsets.all(8.0), child: SelectableText('\$${crypto.lastPrice.toStringAsFixed(2)}')),
                    Padding(padding: const EdgeInsets.all(8.0), child: SelectableText('${crypto.price24hChange.toStringAsFixed(2)}%')),
                    Padding(padding: const EdgeInsets.all(8.0), child: SelectableText('${crypto.price1hChange.toStringAsFixed(2)}%')),
                    Padding(padding: const EdgeInsets.all(8.0), child: SelectableText('\$${NumberFormat("#,##0", "en_US").format(crypto.volume24h)}')),
                  ],
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class CryptoCategory {
  final String name;
  final List<CryptoData> data;

  CryptoCategory({required this.name, required this.data});
}

class CryptoData {
  final String symbol;
  final double lastPrice;
  final double price24hChange;
  final double price1hChange;
  final String indexPrice;
  final double volume24h;

  CryptoData({
    required this.symbol,
    required this.lastPrice,
    required this.price24hChange,
    required this.price1hChange,
    required this.indexPrice,
    required this.volume24h,
  });

  factory CryptoData.fromJson(Map<String, dynamic> json) {
    final lastPrice = double.tryParse(json['lastPrice']) ?? 0.0;
    final prevPrice1h = double.tryParse(json['prevPrice1h'] ?? json['lastPrice']) ?? lastPrice;
    final price24hChange = (double.tryParse(json['price24hPcnt']) ?? 0.0) * 100;
    final price1hChange = ((lastPrice - prevPrice1h) / (prevPrice1h != 0 ? prevPrice1h : 1)) * 100;
    final volume24h = double.tryParse(json['turnover24h']) ?? 0.0;

    return CryptoData(
      symbol: json['symbol'],
      lastPrice: lastPrice,
      price24hChange: price24hChange,
      price1hChange: price1hChange,
      indexPrice: json['indexPrice'],
      volume24h: volume24h,
    );
  }

}
