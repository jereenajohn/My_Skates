import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:my_skates/api.dart';
import 'package:shimmer/shimmer.dart';

class AdminPlatformFeePage extends StatefulWidget {
  const AdminPlatformFeePage({super.key});

  @override
  State<AdminPlatformFeePage> createState() => _AdminPlatformFeePageState();
}

class _AdminPlatformFeePageState extends State<AdminPlatformFeePage>
    with SingleTickerProviderStateMixin {
  // ── Platform Fee ──────────────────────────────────────────────────────────────
  final TextEditingController _feeController = TextEditingController();
  final FocusNode _feeFocusNode = FocusNode();
  String? _currentFee;
  int? _currentFeeId;
  bool _isFeeLoading = true;
  bool _isFeeSaving = false;
  String? _feeError;
  bool _isFeeEditing = false;

  // ── Product Percentage ─────────────────────────────────────────────────────────
  final TextEditingController _percentageController = TextEditingController();
  final FocusNode _percentageFocusNode = FocusNode();
  String? _currentPercentage;
  int? _currentPercentageId;
  bool _isPercentageLoading = true;
  bool _isPercentageSaving = false;
  String? _percentageError;
  bool _isPercentageEditing = false;

  // ── Convenience Fee ────────────────────────────────────────────────────────────
  final TextEditingController _convenienceController = TextEditingController();
  final FocusNode _convenienceFocusNode = FocusNode();
  String? _currentConvenienceFee;
  int? _currentConvenienceFeeId;
  bool $_isConvenienceLoading = true;
  bool $_isConvenienceSaving = false;
  String? $_convenienceError;
  bool $_isConvenienceEditing = false;

  // ── Shipment Charge (three fields: low_charge + high_charge + threshold_amount) ──
  final TextEditingController _lowChargeController = TextEditingController();
  final TextEditingController _highChargeController = TextEditingController();
  final TextEditingController _thresholdController = TextEditingController();
  final FocusNode _lowChargeFocusNode = FocusNode();
  final FocusNode _highChargeFocusNode = FocusNode();
  final FocusNode _thresholdFocusNode = FocusNode();
  String? _currentLowCharge;
  String? _currentHighCharge;
  String? _currentThreshold;
  int? _currentShipmentId;
  bool _isShipmentLoading = true;
  bool _isShipmentSaving = false;
  String? _shipmentError;
  bool _isShipmentEditing = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _fetchPlatformFee();
    _fetchProductPercentage();
    _fetchConvenienceFee();
    _fetchShipmentCharge();
  }

  @override
  void dispose() {
    _feeController.dispose();
    _feeFocusNode.dispose();
    _percentageController.dispose();
    _percentageFocusNode.dispose();
    _convenienceController.dispose();
    _convenienceFocusNode.dispose();
    _lowChargeController.dispose();
    _highChargeController.dispose();
    _thresholdController.dispose();
    _lowChargeFocusNode.dispose();
    _highChargeFocusNode.dispose();
    _thresholdFocusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // FETCH METHODS
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _fetchPlatformFee() async {
    setState(() {
      _isFeeLoading = true;
      _feeError = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      if (token == null) {
        setState(() {
          _feeError = 'Authentication token missing';
          _isFeeLoading = false;
        });
        return;
      }
      final response = await http.get(
        Uri.parse('$api/api/myskates/platform/fee/view/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print("PLATFORM FEE GET STATUS: ${response.statusCode}");
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final dynamic rawData = jsonData['data'];
        final Map<String, dynamic> payload =
            rawData is List && rawData.isNotEmpty
            ? Map<String, dynamic>.from(rawData[0])
            : rawData is Map
            ? Map<String, dynamic>.from(rawData)
            : {};
        _currentFeeId = payload['id'] as int?;
        final dynamic rawFee = payload['platform_fee'];
        final double fee = rawFee is num
            ? rawFee.toDouble()
            : double.tryParse(rawFee?.toString() ?? '0') ?? 0.0;
        setState(() {
          _currentFee = fee.toStringAsFixed(2);
          _feeController.text = _currentFee!;
          _isFeeLoading = false;
        });
        _animController.forward(from: 0);
      } else {
        setState(() {
          _feeError = 'Failed to load platform fee: ${response.statusCode}';
          _isFeeLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _feeError = e.toString();
        _isFeeLoading = false;
      });
    }
  }

  Future<void> _fetchProductPercentage() async {
    setState(() {
      _isPercentageLoading = true;
      _percentageError = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      if (token == null) {
        setState(() {
          _percentageError = 'Authentication token missing';
          _isPercentageLoading = false;
        });
        return;
      }
      final response = await http.get(
        Uri.parse('$api/api/myskates/product/percentage/view/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print("PRODUCT PERCENTAGE GET STATUS: ${response.statusCode}");
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final dynamic rawData = jsonData['data'];
        final Map<String, dynamic> payload =
            rawData is List && rawData.isNotEmpty
            ? Map<String, dynamic>.from(rawData[0])
            : rawData is Map
            ? Map<String, dynamic>.from(rawData)
            : {};
        _currentPercentageId = payload['id'] as int?;
        final dynamic rawPct = payload['product_percentage'];
        final double pct = rawPct is num
            ? rawPct.toDouble()
            : double.tryParse(rawPct?.toString() ?? '0') ?? 0.0;
        setState(() {
          _currentPercentage = pct.toStringAsFixed(2);
          _percentageController.text = _currentPercentage!;
          _isPercentageLoading = false;
        });
      } else {
        setState(() {
          _percentageError =
              'Failed to load product percentage: ${response.statusCode}';
          _isPercentageLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _percentageError = e.toString();
        _isPercentageLoading = false;
      });
    }
  }

  Future<void> _fetchConvenienceFee() async {
    setState(() {
      $_isConvenienceLoading = true;
      $_convenienceError = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      if (token == null) {
        setState(() {
          $_convenienceError = 'Authentication token missing';
          $_isConvenienceLoading = false;
        });
        return;
      }
      final response = await http.get(
        Uri.parse('$api/api/myskates/convenience/fee/view/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print("CONVENIENCE FEE GET STATUS: ${response.statusCode}");
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final dynamic rawData = jsonData['data'];
        final Map<String, dynamic> payload =
            rawData is List && rawData.isNotEmpty
            ? Map<String, dynamic>.from(rawData[0])
            : rawData is Map
            ? Map<String, dynamic>.from(rawData)
            : {};
        _currentConvenienceFeeId = payload['id'] as int?;
        final dynamic rawFee = payload['convenience_fee'];
        final double fee = rawFee is num
            ? rawFee.toDouble()
            : double.tryParse(rawFee?.toString() ?? '0') ?? 0.0;
        setState(() {
          _currentConvenienceFee = fee.toStringAsFixed(2);
          _convenienceController.text = _currentConvenienceFee!;
          $_isConvenienceLoading = false;
        });
      } else {
        setState(() {
          $_convenienceError =
              'Failed to load convenience fee: ${response.statusCode}';
          $_isConvenienceLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        $_convenienceError = e.toString();
        $_isConvenienceLoading = false;
      });
    }
  }

  Future<void> _fetchShipmentCharge() async {
    setState(() {
      _isShipmentLoading = true;
      _shipmentError = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      if (token == null) {
        setState(() {
          _shipmentError = 'Authentication token missing';
          _isShipmentLoading = false;
        });
        return;
      }
      final response = await http.get(
        Uri.parse('$api/api/myskates/shipment/charge/view/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print("SHIPMENT CHARGE GET STATUS: ${response.statusCode}");
      print("SHIPMENT CHARGE GET RESPONSE: ${response.body}");
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final dynamic rawData = jsonData['data'];
        final Map<String, dynamic> payload =
            rawData is List && rawData.isNotEmpty
            ? Map<String, dynamic>.from(rawData[0])
            : rawData is Map
            ? Map<String, dynamic>.from(rawData)
            : {};
        _currentShipmentId = payload['id'] as int?;
        final dynamic rawLow = payload['low_charge'];
        final dynamic rawHigh = payload['high_charge'];
        final dynamic rawThreshold = payload['threshold_amount'];
        final double low = rawLow is num
            ? rawLow.toDouble()
            : double.tryParse(rawLow?.toString() ?? '0') ?? 0.0;
        final double high = rawHigh is num
            ? rawHigh.toDouble()
            : double.tryParse(rawHigh?.toString() ?? '0') ?? 0.0;
        final double threshold = rawThreshold is num
            ? rawThreshold.toDouble()
            : double.tryParse(rawThreshold?.toString() ?? '0') ?? 0.0;
        setState(() {
          _currentLowCharge = low.toStringAsFixed(2);
          _currentHighCharge = high.toStringAsFixed(2);
          _currentThreshold = threshold.toStringAsFixed(2);
          _lowChargeController.text = _currentLowCharge!;
          _highChargeController.text = _currentHighCharge!;
          _thresholdController.text = _currentThreshold!;
          _isShipmentLoading = false;
        });
      } else {
        setState(() {
          _shipmentError =
              'Failed to load shipment charge: ${response.statusCode}';
          _isShipmentLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching shipment charge: $e");
      setState(() {
        _shipmentError = e.toString();
        _isShipmentLoading = false;
      });
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // UPDATE METHODS
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _updatePlatformFee() async {
    final input = _feeController.text.trim();
    if (input.isEmpty) {
      _showSnackBar('Please enter a platform fee amount', isError: true);
      return;
    }
    final parsed = double.tryParse(input);
    if (parsed == null || parsed < 0) {
      _showSnackBar('Enter a valid non-negative number', isError: true);
      return;
    }
    if (_currentFeeId == null) {
      _showSnackBar('Unable to update: Fee record ID not found', isError: true);
      return;
    }
    setState(() => _isFeeSaving = true);
    _feeFocusNode.unfocus();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      if (token == null) {
        _showSnackBar('Authentication token missing', isError: true);
        setState(() => _isFeeSaving = false);
        return;
      }
      final response = await http.put(
        Uri.parse('$api/api/myskates/platform/fee/update/${_currentFeeId}/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'platform_fee': parsed}),
      );
      print("PLATFORM FEE PUT STATUS: ${response.statusCode}");
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _isFeeSaving = false;
          _isFeeEditing = false;
        });
        await _fetchPlatformFee();
        _showSnackBar('Platform fee updated successfully');
      } else {
        setState(() => _isFeeSaving = false);
        _showSnackBar(
          _extractError(response.body, response.statusCode),
          isError: true,
        );
      }
    } catch (e) {
      setState(() => _isFeeSaving = false);
      _showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _updateProductPercentage() async {
    final input = _percentageController.text.trim();
    if (input.isEmpty) {
      _showSnackBar('Please enter a product percentage', isError: true);
      return;
    }
    final parsed = double.tryParse(input);
    if (parsed == null || parsed < 0) {
      _showSnackBar('Enter a valid non-negative number', isError: true);
      return;
    }
    if (parsed > 100) {
      _showSnackBar('Percentage cannot exceed 100%', isError: true);
      return;
    }
    if (_currentPercentageId == null) {
      _showSnackBar(
        'Unable to update: Percentage record ID not found',
        isError: true,
      );
      return;
    }
    setState(() => _isPercentageSaving = true);
    _percentageFocusNode.unfocus();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      if (token == null) {
        _showSnackBar('Authentication token missing', isError: true);
        setState(() => _isPercentageSaving = false);
        return;
      }
      final response = await http.put(
        Uri.parse(
          '$api/api/myskates/product/percentage/update/${_currentPercentageId}/',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'product_percentage': parsed}),
      );
      print("PRODUCT PERCENTAGE PUT STATUS: ${response.statusCode}");
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _isPercentageSaving = false;
          _isPercentageEditing = false;
        });
        await _fetchProductPercentage();
        _showSnackBar('Product percentage updated successfully');
      } else {
        setState(() => _isPercentageSaving = false);
        _showSnackBar(
          _extractError(response.body, response.statusCode),
          isError: true,
        );
      }
    } catch (e) {
      setState(() => _isPercentageSaving = false);
      _showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _updateConvenienceFee() async {
    final input = _convenienceController.text.trim();
    if (input.isEmpty) {
      _showSnackBar('Please enter a convenience fee amount', isError: true);
      return;
    }
    final parsed = double.tryParse(input);
    if (parsed == null || parsed < 0) {
      _showSnackBar('Enter a valid non-negative number', isError: true);
      return;
    }
    if (_currentConvenienceFeeId == null) {
      _showSnackBar(
        'Unable to update: Convenience fee record ID not found',
        isError: true,
      );
      return;
    }
    setState(() => $_isConvenienceSaving = true);
    _convenienceFocusNode.unfocus();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      if (token == null) {
        _showSnackBar('Authentication token missing', isError: true);
        setState(() => $_isConvenienceSaving = false);
        return;
      }
      final response = await http.put(
        Uri.parse(
          '$api/api/myskates/convenience/fee/update/${_currentConvenienceFeeId}/',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'convenience_fee': parsed}),
      );
      print("CONVENIENCE FEE PUT STATUS: ${response.statusCode}");
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          $_isConvenienceSaving = false;
          $_isConvenienceEditing = false;
        });
        await _fetchConvenienceFee();
        _showSnackBar('Convenience fee updated successfully');
      } else {
        setState(() => $_isConvenienceSaving = false);
        _showSnackBar(
          _extractError(response.body, response.statusCode),
          isError: true,
        );
      }
    } catch (e) {
      setState(() => $_isConvenienceSaving = false);
      _showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _updateShipmentCharge() async {
    final lowInput = _lowChargeController.text.trim();
    final highInput = _highChargeController.text.trim();
    final thresholdInput = _thresholdController.text.trim();

    if (lowInput.isEmpty || highInput.isEmpty || thresholdInput.isEmpty) {
      _showSnackBar(
        'Please enter low charge, high charge, and threshold amount',
        isError: true,
      );
      return;
    }
    final parsedLow = double.tryParse(lowInput);
    final parsedHigh = double.tryParse(highInput);
    final parsedThreshold = double.tryParse(thresholdInput);
    
    if (parsedLow == null || parsedLow < 0) {
      _showSnackBar(
        'Enter a valid non-negative number for low charge',
        isError: true,
      );
      return;
    }
    if (parsedHigh == null || parsedHigh < 0) {
      _showSnackBar(
        'Enter a valid non-negative number for high charge',
        isError: true,
      );
      return;
    }
    if (parsedThreshold == null || parsedThreshold < 0) {
      _showSnackBar(
        'Enter a valid non-negative number for threshold amount',
        isError: true,
      );
      return;
    }
    if (parsedLow > parsedHigh) {
      _showSnackBar(
        'Low charge cannot be greater than high charge',
        isError: true,
      );
      return;
    }
    if (_currentShipmentId == null) {
      _showSnackBar(
        'Unable to update: Shipment record ID not found',
        isError: true,
      );
      return;
    }
    setState(() => _isShipmentSaving = true);
    _lowChargeFocusNode.unfocus();
    _highChargeFocusNode.unfocus();
    _thresholdFocusNode.unfocus();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      if (token == null) {
        _showSnackBar('Authentication token missing', isError: true);
        setState(() => _isShipmentSaving = false);
        return;
      }
      final response = await http.put(
        Uri.parse(
          '$api/api/myskates/shipment/charge/update/${_currentShipmentId}/',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'low_charge': parsedLow, 
          'high_charge': parsedHigh,
          'threshold_amount': parsedThreshold
        }),
      );
      print("SHIPMENT CHARGE PUT STATUS: ${response.statusCode}");
      print("SHIPMENT CHARGE PUT RESPONSE: ${response.body}");
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _isShipmentSaving = false;
          _isShipmentEditing = false;
        });
        await _fetchShipmentCharge();
        _showSnackBar('Shipment charges updated successfully');
      } else {
        setState(() => _isShipmentSaving = false);
        _showSnackBar(
          _extractError(response.body, response.statusCode),
          isError: true,
        );
      }
    } catch (e) {
      print("Error updating shipment charge: $e");
      setState(() => _isShipmentSaving = false);
      _showSnackBar('Error: $e', isError: true);
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ───────────────────────────────────────────────────────────────────────────

  String _extractError(String body, int statusCode) {
    try {
      final data = jsonDecode(body);
      return data['message'] ??
          data['error'] ??
          'Failed to update: $statusCode';
    } catch (_) {
      return 'Failed to update: $statusCode';
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? Colors.white : Colors.black,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isError ? Colors.white : Colors.black,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade700 : Colors.tealAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // UI HELPERS
  // ───────────────────────────────────────────────────────────────────────────

  Widget _glassWrap({required Widget child, EdgeInsets? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildShimmerBlock() {
    return Column(
      children: [
        _glassWrap(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Container(
                width: 120,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 160,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _glassWrap(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 140,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Shipment shimmer has three input fields
  Widget _buildShipmentShimmerBlock() {
    return Column(
      children: [
        _glassWrap(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Container(
                width: 140,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _glassWrap(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 140,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1A2B2A),
      highlightColor: const Color(0xFF2F4F4D),
      child: Column(
        children: [
          _buildShimmerBlock(),
          const SizedBox(height: 32),
          _buildShimmerBlock(),
          const SizedBox(height: 32),
          _buildShimmerBlock(),
          const SizedBox(height: 32),
          _buildShipmentShimmerBlock(),
        ],
      ),
    );
  }

  Widget _buildDivider(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: Colors.white.withOpacity(0.08), height: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.25),
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ),
          Expanded(
            child: Divider(color: Colors.white.withOpacity(0.08), height: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoNote(String message, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.12), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: accentColor, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionError(String error, VoidCallback onRetry) {
    return _glassWrap(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 12),
          Text(
            error,
            style: const TextStyle(color: Colors.red, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // GENERIC SINGLE-VALUE CARDS
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildCurrentCard({
    required String label,
    required String? value,
    required Color accent,
    required IconData icon,
    required String subLabel,
    bool isPercentage = false,
  }) {
    final displayValue = value != null
        ? double.tryParse(value)?.toStringAsFixed(2) ?? value
        : '—';
    return _glassWrap(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withOpacity(0.25), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: isPercentage
                  ? [
                      Text(
                        displayValue,
                        style: TextStyle(
                          color: accent,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '%',
                          style: TextStyle(
                            color: accent,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ]
                  : [
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '₹',
                          style: TextStyle(
                            color: accent,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        displayValue,
                        style: TextStyle(
                          color: accent,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subLabel,
            style: TextStyle(
              color: Colors.white.withOpacity(0.28),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditCard({
    required String title,
    required String inputHint,
    required Color accent,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isSaving,
    required bool isEditing,
    required String? currentValue,
    required VoidCallback onSave,
    required VoidCallback onReset,
    required VoidCallback onTapOrChange,
    required String buttonLabel,
    bool isPercentage = false,
  }) {
    return _glassWrap(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.edit_outlined, color: accent, size: 15),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Text(
              inputHint,
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                onTap: onTapOrChange,
                onChanged: (_) => onTapOrChange(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  hintText: '0.00',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.25),
                    fontSize: 18,
                  ),
                  prefixIcon: isPercentage
                      ? null
                      : Container(
                          width: 52,
                          alignment: Alignment.center,
                          child: Text(
                            '₹',
                            style: TextStyle(
                              color: accent,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                  suffixIcon: isPercentage
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (controller.text.isNotEmpty)
                              IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: Colors.white.withOpacity(0.3),
                                  size: 18,
                                ),
                                onPressed: () {
                                  controller.clear();
                                  onTapOrChange();
                                },
                              ),
                            Container(
                              width: 48,
                              alignment: Alignment.center,
                              child: Text(
                                '%',
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        )
                      : controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: Colors.white.withOpacity(0.3),
                            size: 18,
                          ),
                          onPressed: () {
                            controller.clear();
                            onTapOrChange();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: accent, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isSaving ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                disabledBackgroundColor: accent.withOpacity(0.4),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black54,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          buttonLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (isEditing &&
              currentValue != null &&
              controller.text != currentValue)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton(
                  onPressed: onReset,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white38,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.white.withOpacity(0.08)),
                    ),
                  ),
                  child: const Text(
                    'Reset to current value',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SHIPMENT-SPECIFIC WIDGETS (three-field display + three-field edit)
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildShipmentCurrentCard() {
    const accent = Colors.cyanAccent;
    return _glassWrap(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  color: accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Current Shipment Charges',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Low, High, and Threshold in a row (or wrap for smaller screens)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              // Low Charge tile
              Container(
                width: 110,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: accent.withOpacity(0.22),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_downward_rounded,
                            color: Colors.greenAccent,
                            size: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Low',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 11,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₹',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _currentLowCharge != null
                              ? double.tryParse(
                                      _currentLowCharge!,
                                    )?.toStringAsFixed(2) ??
                                    _currentLowCharge!
                              : '—',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // High Charge tile
              Container(
                width: 110,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: accent.withOpacity(0.22),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_upward_rounded,
                            color: Colors.redAccent,
                            size: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'High',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 11,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₹',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _currentHighCharge != null
                              ? double.tryParse(
                                      _currentHighCharge!,
                                    )?.toStringAsFixed(2) ??
                                    _currentHighCharge!
                              : '—',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Threshold tile
              Container(
                width: 130,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: accent.withOpacity(0.22),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.compare_arrows_rounded,
                            color: Colors.blueAccent,
                            size: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Threshold',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 11,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₹',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _currentThreshold != null
                              ? double.tryParse(
                                      _currentThreshold!,
                                    )?.toStringAsFixed(2) ??
                                    _currentThreshold!
                              : '—',
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Low charge (≤ threshold) | High charge (> threshold)',
            style: TextStyle(
              color: Colors.white.withOpacity(0.28),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildShipmentEditCard() {
    const accent = Colors.tealAccent;
    final bool showReset =
        _isShipmentEditing &&
        (_lowChargeController.text != _currentLowCharge ||
            _highChargeController.text != _currentHighCharge ||
            _thresholdController.text != _currentThreshold);

    return _glassWrap(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_outlined, color: accent, size: 15),
              ),
              const SizedBox(width: 10),
              const Text(
                'Update Shipment Charges',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Text(
              'Enter low charge, high charge, and threshold amount in ₹',
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Three input fields in a column on mobile, row on larger screens
          Column(
            children: [
              // Low charge field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_downward_rounded,
                          color: Colors.greenAccent,
                          size: 10,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Low Charge',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: TextField(
                        controller: _lowChargeController,
                        focusNode: _lowChargeFocusNode,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        onTap: () =>
                            setState(() => _isShipmentEditing = true),
                        onChanged: (_) =>
                            setState(() => _isShipmentEditing = true),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.06),
                          hintText: '0.00',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.25),
                            fontSize: 16,
                          ),
                          prefixIcon: Container(
                            width: 40,
                            alignment: Alignment.center,
                            child: const Text(
                              '₹',
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Colors.greenAccent,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // High charge field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.redAccent,
                          size: 10,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'High Charge',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: TextField(
                        controller: _highChargeController,
                        focusNode: _highChargeFocusNode,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        onTap: () =>
                            setState(() => _isShipmentEditing = true),
                        onChanged: (_) =>
                            setState(() => _isShipmentEditing = true),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.06),
                          hintText: '0.00',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.25),
                            fontSize: 16,
                          ),
                          prefixIcon: Container(
                            width: 40,
                            alignment: Alignment.center,
                            child: const Text(
                              '₹',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Colors.redAccent,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Threshold field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.compare_arrows_rounded,
                          color: Colors.blueAccent,
                          size: 10,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Threshold Amount',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: TextField(
                        controller: _thresholdController,
                        focusNode: _thresholdFocusNode,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        onTap: () =>
                            setState(() => _isShipmentEditing = true),
                        onChanged: (_) =>
                            setState(() => _isShipmentEditing = true),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.06),
                          hintText: '0.00',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.25),
                            fontSize: 16,
                          ),
                          prefixIcon: Container(
                            width: 40,
                            alignment: Alignment.center,
                            child: const Text(
                              '₹',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Colors.blueAccent,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isShipmentSaving ? null : _updateShipmentCharge,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                disabledBackgroundColor: accent.withOpacity(0.4),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isShipmentSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black54,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_rounded, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Update Shipment Charges',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          // Reset button
          if (showReset)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton(
                  onPressed: () {
                    _lowChargeController.text = _currentLowCharge ?? '';
                    _highChargeController.text = _currentHighCharge ?? '';
                    _thresholdController.text = _currentThreshold ?? '';
                    _lowChargeFocusNode.unfocus();
                    _highChargeFocusNode.unfocus();
                    _thresholdFocusNode.unfocus();
                    setState(() => _isShipmentEditing = false);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white38,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.white.withOpacity(0.08)),
                    ),
                  ),
                  child: const Text(
                    'Reset to current values',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BUILD
  // ───────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool anyLoading =
        _isFeeLoading ||
        _isPercentageLoading ||
        $_isConvenienceLoading ||
        _isShipmentLoading;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF001F1D), Color(0xFF003A36), Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── App Bar ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'Fees & Charges',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!anyLoading)
                      IconButton(
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: Colors.tealAccent,
                          size: 22,
                        ),
                        onPressed: () {
                          _fetchPlatformFee();
                          _fetchProductPercentage();
                          _fetchConvenienceFee();
                          _fetchShipmentCharge();
                        },
                        tooltip: 'Refresh all',
                      ),
                  ],
                ),
              ),

              // ── Body ──────────────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: anyLoading
                      ? _buildShimmer()
                      : FadeTransition(
                          opacity: _fadeAnim,
                          child: SlideTransition(
                            position: _slideAnim,
                            child: Column(
                              children: [
                                // ── Platform Fee ─────────────────────────
                                _buildDivider('PLATFORM FEE'),
                                const SizedBox(height: 12),
                                if (_feeError != null)
                                  _buildSectionError(
                                    _feeError!,
                                    _fetchPlatformFee,
                                  )
                                else ...[
                                  _buildCurrentCard(
                                    label: 'Current Platform Fee',
                                    value: _currentFee,
                                    accent: Colors.tealAccent,
                                    icon: Icons.account_balance_wallet_outlined,
                                    subLabel:
                                        'Applied to every order at checkout',
                                  ),
                                  const SizedBox(height: 20),
                                  _buildEditCard(
                                    title: 'Update Platform Fee',
                                    inputHint: 'Enter the new fee amount in ₹',
                                    accent: Colors.tealAccent,
                                    controller: _feeController,
                                    focusNode: _feeFocusNode,
                                    isSaving: _isFeeSaving,
                                    isEditing: _isFeeEditing,
                                    currentValue: _currentFee,
                                    onSave: _updatePlatformFee,
                                    onReset: () {
                                      _feeController.text = _currentFee!;
                                      _feeFocusNode.unfocus();
                                      setState(() => _isFeeEditing = false);
                                    },
                                    onTapOrChange: () =>
                                        setState(() => _isFeeEditing = true),
                                    buttonLabel: 'Update Platform Fee',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInfoNote(
                                    'The platform fee is added on top of the order total during checkout. Changes take effect immediately on all new orders.',
                                    Colors.tealAccent,
                                  ),
                                ],

                                const SizedBox(height: 32),

                                // ── Product Percentage ────────────────────
                                _buildDivider('PRODUCT PERCENTAGE'),
                                const SizedBox(height: 12),
                                if (_percentageError != null)
                                  _buildSectionError(
                                    _percentageError!,
                                    _fetchProductPercentage,
                                  )
                                else ...[
                                  _buildCurrentCard(
                                    label: 'Current Product Percentage',
                                    value: _currentPercentage,
                                    accent: Colors.tealAccent,
                                    icon: Icons.percent_rounded,
                                    subLabel:
                                        'Applied as a percentage on product pricing',
                                    isPercentage: true,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildEditCard(
                                    title: 'Update Product Percentage',
                                    inputHint:
                                        'Enter the new percentage value (0–100)',
                                    accent: Colors.tealAccent,
                                    controller: _percentageController,
                                    focusNode: _percentageFocusNode,
                                    isSaving: _isPercentageSaving,
                                    isEditing: _isPercentageEditing,
                                    currentValue: _currentPercentage,
                                    onSave: _updateProductPercentage,
                                    onReset: () {
                                      _percentageController.text =
                                          _currentPercentage!;
                                      _percentageFocusNode.unfocus();
                                      setState(
                                        () => _isPercentageEditing = false,
                                      );
                                    },
                                    onTapOrChange: () => setState(
                                      () => _isPercentageEditing = true,
                                    ),
                                    buttonLabel: 'Update Product Percentage',
                                    isPercentage: true,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInfoNote(
                                    'The product percentage is applied to product pricing calculations. Must be between 0% and 100%. Changes take effect immediately.',
                                    Colors.tealAccent,
                                  ),
                                ],

                                const SizedBox(height: 32),

                                // ── Convenience Fee ───────────────────────
                                _buildDivider('CONVENIENCE FEE'),
                                const SizedBox(height: 12),
                                if ($_convenienceError != null)
                                  _buildSectionError(
                                    $_convenienceError!,
                                    _fetchConvenienceFee,
                                  )
                                else ...[
                                  _buildCurrentCard(
                                    label: 'Current Convenience Fee',
                                    value: _currentConvenienceFee,
                                    accent: Colors.tealAccent,
                                    icon: Icons.local_offer_outlined,
                                    subLabel:
                                        'Charged as a convenience fee per order',
                                  ),
                                  const SizedBox(height: 20),
                                  _buildEditCard(
                                    title: 'Update Convenience Fee',
                                    inputHint: 'Enter the new fee amount in ₹',
                                    accent: Colors.tealAccent,
                                    controller: _convenienceController,
                                    focusNode: _convenienceFocusNode,
                                    isSaving: $_isConvenienceSaving,
                                    isEditing: $_isConvenienceEditing,
                                    currentValue: _currentConvenienceFee,
                                    onSave: _updateConvenienceFee,
                                    onReset: () {
                                      _convenienceController.text =
                                          _currentConvenienceFee!;
                                      _convenienceFocusNode.unfocus();
                                      setState(
                                        () => $_isConvenienceEditing = false,
                                      );
                                    },
                                    onTapOrChange: () => setState(
                                      () => $_isConvenienceEditing = true,
                                    ),
                                    buttonLabel: 'Update Convenience Fee',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInfoNote(
                                    'The convenience fee is charged per order as a service charge. Changes take effect immediately on all new orders.',
                                    Colors.tealAccent,
                                  ),
                                ],

                                const SizedBox(height: 32),

                                // ── Shipment Charge ───────────────────────
                                // _buildDivider('SHIPMENT CHARGE'),
                                // const SizedBox(height: 12),
                                // if (_shipmentError != null)
                                //   _buildSectionError(
                                //     _shipmentError!,
                                //     _fetchShipmentCharge,
                                //   )
                                // else ...[
                                //   _buildShipmentCurrentCard(),
                                //   const SizedBox(height: 20),
                                //   _buildShipmentEditCard(),
                                //   const SizedBox(height: 12),
                                //   _buildInfoNote(
                                //     'Low charge applies when order total ≤ threshold amount; high charge applies when order total > threshold amount. All three values are sent together on update.',
                                //     Colors.tealAccent,
                                //   ),
                                // ],
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}