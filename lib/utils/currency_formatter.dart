import 'package:intl/intl.dart';

class CurrencyFormatter {
  // Get currency symbol from currency code
  static String getCurrencySymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'INR':
        return '₹';
      case 'JPY':
        return '¥';
      case 'CAD':
        return 'C\$';
      case 'AUD':
        return 'A\$';
      case 'CNY':
        return '¥';
      case 'CHF':
        return 'CHF';
      case 'SEK':
        return 'kr';
      case 'NOK':
        return 'kr';
      case 'DKK':
        return 'kr';
      case 'PLN':
        return 'zł';
      case 'SGD':
        return 'S\$';
      case 'HKD':
        return 'HK\$';
      case 'NZD':
        return 'NZ\$';
      case 'ZAR':
        return 'R';
      case 'BRL':
        return 'R\$';
      case 'MXN':
        return '\$';
      case 'AED':
        return 'AED';
      default:
        return currencyCode; // Return code if symbol not found
    }
  }

  // Format price with currency symbol
  static String formatPrice(String price, String currencyCode) {
    try {
      final priceValue = double.tryParse(price) ?? 0.0;
      final upperCode = currencyCode.toUpperCase();
      final symbol = getCurrencySymbol(upperCode);
      
      // Debug: Print currency info
      if (symbol == '\$' && upperCode != 'USD') {
        print('⚠️ CurrencyFormatter Warning: Currency code "$upperCode" returned dollar symbol');
      }
      
      // Format price with proper decimals
      final formattedPrice = priceValue.toStringAsFixed(2);
      
      // Return with currency symbol positioned correctly based on currency
      // For most currencies, symbol goes before number
      return '$symbol$formattedPrice';
    } catch (e) {
      // Fallback if parsing fails
      final symbol = getCurrencySymbol(currencyCode.toUpperCase());
      return '$symbol$price';
    }
  }

  // Format price with currency code (e.g., "USD 10.00")
  static String formatPriceWithCode(String price, String currencyCode) {
    try {
      final priceValue = double.tryParse(price) ?? 0.0;
      final formatter = NumberFormat.currency(
        symbol: '',
        decimalDigits: 2,
      );
      
      return '${formatter.format(priceValue)} $currencyCode';
    } catch (e) {
      return '$price $currencyCode';
    }
  }
}

