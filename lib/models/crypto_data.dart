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
    return CryptoData(
      symbol: json['symbol'],
      lastPrice: double.tryParse(json['lastPrice'].toString()) ?? 0.0,
      price24hChange: double.tryParse(json['price24hPcnt'].toString()) ?? 0.0,
      price1hChange: (double.tryParse(json['lastPrice'].toString()) ?? 0.0) - (double.tryParse(json['prevPrice1h'].toString()) ?? 0.0),
      indexPrice: json['indexPrice'].toString(),
      volume24h: double.tryParse(json['turnover24h'].toString()) ?? 0.0,
    );
  }
}
