import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(Currency360App());

class Currency360App extends StatelessWidget {
  final ValueNotifier<ThemeMode> _themeNotifier =
      ValueNotifier(ThemeMode.system);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeNotifier,
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'Currency360',
          theme: ThemeData(
            primaryColor: Color(0xFF003F5C),
            scaffoldBackgroundColor: Color(0xFFFFFFFF),
            textTheme: TextTheme(bodyText1: TextStyle(color: Colors.black87)),
            buttonTheme: ButtonThemeData(
              buttonColor: Color(0xFF003F5C),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            dividerColor: Color(0xFFD9D9D9),
          ),
          darkTheme: ThemeData(
            primaryColor: Color(0xFF003F5C),
            scaffoldBackgroundColor: Color(0xFF303030),
            textTheme: TextTheme(bodyText1: TextStyle(color: Colors.white)),
            buttonTheme: ButtonThemeData(
              buttonColor: Color(0xFF003F5C),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            dividerColor: Color(0xFF555555),
          ),
          themeMode: themeMode,
          home: CurrencyConverterPage(themeNotifier: _themeNotifier),
        );
      },
    );
  }
}

class CurrencyConverterPage extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  CurrencyConverterPage({required this.themeNotifier});

  @override
  _CurrencyConverterPageState createState() => _CurrencyConverterPageState();
}

class _CurrencyConverterPageState extends State<CurrencyConverterPage> {
  final TextEditingController _amountController = TextEditingController();
  final List<String> _currencies = [
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'AUD',
    'CAD',
    'CHF',
    'CNY',
    'SEK',
    'NZD',
    'MXN',
    'SGD',
    'HKD',
    'NOK',
    'KRW',
    'TRY',
    'INR',
    'RUB',
    'BRL',
    'ZAR',
    'DKK',
    'PLN',
    'THB',
    'IDR',
    'HUF',
    'CZK',
    'ILS',
    'CLP',
    'PHP',
    'AED',
    'COP',
    'SAR',
    'MYR',
    'RON'
  ];
  final List<String> _banks = [
    'Bank A',
    'Bank B',
    'Money Exchange A',
    'Money Exchange B'
  ];
  String _sourceCurrency = 'USD';
  String _targetCurrency = 'EUR';
  String _selectedBank = 'Bank A'; // Default bank selected
  String? _result;
  bool _isLoading = false;
  String? _errorMessage;
  List<String> _conversionHistory = [];
  Map<String, double> _liveRates = {}; // To store live exchange rates

  @override
  void initState() {
    super.initState();
    _fetchLiveRates(); // Fetch live exchange rates when the app starts
  }

  Future<void> _fetchLiveRates() async {
    try {
      final url = Uri.parse('https://api.exchangerate-api.com/v4/latest/USD');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'];

        setState(() {
          _liveRates = Map<String, double>.from(rates);
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch live rates';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    }
  }

  Future<void> _convertCurrency() async {
    final amountText = _amountController.text;
    if (amountText.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an amount';
      });
      return;
    }

    final double? amount = double.tryParse(amountText);
    if (amount == null) {
      setState(() {
        _errorMessage = 'Invalid amount';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      final url = Uri.parse(
          'https://api.exchangerate-api.com/v4/latest/$_sourceCurrency');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'];

        if (rates[_targetCurrency] != null) {
          final rate = rates[_targetCurrency];
          final convertedAmount = amount * rate;

          // Apply the conversion fee based on selected provider
          double feePercentage = 0.0;
          if (_selectedBank == 'Bank A') {
            feePercentage = 2.0; // Bank A takes 2% fee
          } else if (_selectedBank == 'Bank B') {
            feePercentage = 1.5; // Bank B takes 1.5% fee
          } else if (_selectedBank == 'Money Exchange A') {
            feePercentage = 1.0; // Money Exchange A takes 1% fee
          } else if (_selectedBank == 'Money Exchange B') {
            feePercentage = 0.5; // Money Exchange B takes 0.5% fee
          }

          final fee = (convertedAmount * feePercentage / 100);
          final finalAmount = convertedAmount - fee;

          setState(() {
            _result =
                'Converted Amount: ${convertedAmount.toStringAsFixed(2)} $_targetCurrency\n'
                'Fee: ${fee.toStringAsFixed(2)} $_targetCurrency\n'
                'Amount Received: ${finalAmount.toStringAsFixed(2)} $_targetCurrency';
            _conversionHistory.add(_result!);
          });
        } else {
          setState(() {
            _errorMessage = 'Conversion rate not available';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch exchange rates';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Currency360'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter Amount',
                labelStyle: TextStyle(color: Colors.black54),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(Icons.money),
              ),
            ),
            SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _sourceCurrency,
                    items: _currencies.map((currency) {
                      return DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _sourceCurrency = value!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'From',
                      labelStyle: TextStyle(color: Colors.black54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 16.0),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _targetCurrency,
                    items: _currencies.map((currency) {
                      return DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _targetCurrency = value!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'To',
                      labelStyle: TextStyle(color: Colors.black54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              value: _selectedBank,
              items: _banks.map((bank) {
                return DropdownMenuItem(
                  value: bank,
                  child: Text(bank),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBank = value!;
                });
              },
              decoration: InputDecoration(
                labelText: 'Select Provider',
                labelStyle: TextStyle(color: Colors.black54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _isLoading ? null : _convertCurrency,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                backgroundColor: Color(0xFF003F5C),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Convert', style: TextStyle(fontSize: 16)),
            ),
            SizedBox(height: 16.0),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            if (_result != null)
              Text(
                _result!,
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            SizedBox(height: 16.0),
            Divider(color: Color(0xFFD9D9D9)),
            Text(
              'Real-time Currency Rates (from USD):',
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0),
            if (_liveRates.isNotEmpty)
              Column(
                children: _currencies.map((currency) {
                  return ListTile(
                    title: Text(
                        '$currency: ${_liveRates[currency]?.toStringAsFixed(4) ?? 'Loading...'} USD'),
                  );
                }).toList(),
              ),
            SizedBox(height: 16.0),
            Text(
              'Conversion History:',
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
            Divider(color: Color(0xFFD9D9D9)),
            Container(
              height: 200,
              child: ListView.builder(
                itemCount: _conversionHistory.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_conversionHistory[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
