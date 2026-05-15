import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:my_skates/api.dart';
import 'package:shimmer/shimmer.dart';

class AdminPaymentMethodsPage extends StatefulWidget {
  const AdminPaymentMethodsPage({super.key});

  @override
  State<AdminPaymentMethodsPage> createState() =>
      _AdminPaymentMethodsPageState();
}

class _AdminPaymentMethodsPageState extends State<AdminPaymentMethodsPage>
    with SingleTickerProviderStateMixin {
  // ── Data ──────────────────────────────────────────────────────────────
  List<PaymentMethod> _paymentMethods = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDeleting = false;
  String? _error;

  // ── Form Controllers ──────────────────────────────────────────────────
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _codeFocusNode = FocusNode();

  // ── Edit Mode ─────────────────────────────────────────────────────────
  bool _isAddingNew = false;
  PaymentMethod? _editingMethod;

  // ── Animations ────────────────────────────────────────────────────────
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── Delete Confirmation ───────────────────────────────────────────────
  int? _deletingId;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _fetchPaymentMethods();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _nameFocusNode.dispose();
    _codeFocusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _nameController.clear();
    _codeController.clear();
  }

  // ───────────────────────────────────────────────────────────────────────
  // API METHODS
  // ───────────────────────────────────────────────────────────────────────

  Future<void> _fetchPaymentMethods() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        setState(() {
          _error = 'Authentication token missing';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('$api/api/myskates/payment/methods/view/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("PAYMENT METHODS GET STATUS: ${response.statusCode}");
      print("PAYMENT METHODS GET RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final dynamic rawData = jsonData['data'];

        List<PaymentMethod> methods = [];

        if (rawData is List) {
          for (var item in rawData) {
            if (item is Map<String, dynamic>) {
              methods.add(PaymentMethod.fromJson(item));
            } else if (item is Map) {
              // Convert Map<dynamic, dynamic> to Map<String, dynamic>
              Map<String, dynamic> convertedMap = {};
              item.forEach((key, value) {
                convertedMap[key.toString()] = value;
              });
              methods.add(PaymentMethod.fromJson(convertedMap));
            }
          }
        } else if (rawData is Map) {
          // Convert Map<dynamic, dynamic> to Map<String, dynamic>
          Map<String, dynamic> convertedMap = {};
          rawData.forEach((key, value) {
            convertedMap[key.toString()] = value;
          });
          methods.add(PaymentMethod.fromJson(convertedMap));
        }

        setState(() {
          _paymentMethods = methods;
          _isLoading = false;
        });
        _animController.forward(from: 0);
      } else {
        setState(() {
          _error = 'Failed to load payment methods: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching payment methods: $e");
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createPaymentMethod() async {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim().toUpperCase();

    if (name.isEmpty) {
      _showSnackBar('Please enter payment method name', isError: true);
      return;
    }

    if (code.isEmpty) {
      _showSnackBar('Please enter payment method code', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        _showSnackBar('Authentication token missing', isError: true);
        setState(() => _isSaving = false);
        return;
      }

      final response = await http.post(
        Uri.parse('$api/api/myskates/payment/methods/view/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': name, 'code': code}),
      );

      print("PAYMENT METHOD POST STATUS: ${response.statusCode}");
      print("PAYMENT METHOD POST RESPONSE: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        _clearForm();
        await _fetchPaymentMethods();
        _showSnackBar('Payment method added successfully');
      } else {
        _showSnackBar(
          _extractError(response.body, response.statusCode),
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _updatePaymentMethod() async {
    if (_editingMethod == null) return;

    final name = _nameController.text.trim();
    final code = _codeController.text.trim().toUpperCase();

    if (name.isEmpty) {
      _showSnackBar('Please enter payment method name', isError: true);
      return;
    }

    if (code.isEmpty) {
      _showSnackBar('Please enter payment method code', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        _showSnackBar('Authentication token missing', isError: true);
        setState(() => _isSaving = false);
        return;
      }

      final response = await http.put(
        Uri.parse(
          '$api/api/myskates/payment/methods/update/${_editingMethod!.id}/',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'code': code,
          'is_active': _editingMethod!.isActive,
        }),
      );

      print("PAYMENT METHOD PUT STATUS: ${response.statusCode}");
      print("PAYMENT METHOD PUT RESPONSE: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        _cancelEdit();
        await _fetchPaymentMethods();
        _showSnackBar('Payment method updated successfully');
      } else {
        _showSnackBar(
          _extractError(response.body, response.statusCode),
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _togglePaymentMethodStatus(PaymentMethod method) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        _showSnackBar('Authentication token missing', isError: true);
        setState(() => _isSaving = false);
        return;
      }

      final response = await http.put(
        Uri.parse('$api/api/myskates/payment/methods/update/${method.id}/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': method.name,
          'code': method.code,
          'is_active': !method.isActive,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _fetchPaymentMethods();
        _showSnackBar(
          'Payment method ${!method.isActive ? "activated" : "deactivated"} successfully',
        );
      } else {
        _showSnackBar(
          _extractError(response.body, response.statusCode),
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _deletePaymentMethod(int id) async {
    setState(() {
      _isDeleting = true;
      _deletingId = id;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        _showSnackBar('Authentication token missing', isError: true);
        setState(() {
          _isDeleting = false;
          _deletingId = null;
        });
        return;
      }

      final response = await http.delete(
        Uri.parse('$api/api/myskates/payment/methods/update/$id/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("PAYMENT METHOD DELETE STATUS: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        await _fetchPaymentMethods();
        _showSnackBar('Payment method deleted successfully');
      } else {
        _showSnackBar(
          _extractError(response.body, response.statusCode),
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() {
        _isDeleting = false;
        _deletingId = null;
      });
    }
  }

  // ───────────────────────────────────────────────────────────────────────
  // UI HELPERS
  // ───────────────────────────────────────────────────────────────────────

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

  String _extractError(String body, int statusCode) {
    try {
      final data = jsonDecode(body);
      return data['message'] ?? data['error'] ?? 'Failed: $statusCode';
    } catch (_) {
      return 'Failed: $statusCode';
    }
  }

  void _startAddNew() {
    _nameController.clear();
    _codeController.clear();
    setState(() {
      _isAddingNew = true;
      _editingMethod = null;
    });
    _nameFocusNode.requestFocus();
  }

  void _startEdit(PaymentMethod method) {
    _nameController.text = method.name;
    _codeController.text = method.code;
    setState(() {
      _editingMethod = method;
      _isAddingNew = false;
    });
    _nameFocusNode.requestFocus();
  }

  void _cancelEdit() {
    _nameController.clear();
    _codeController.clear();
    setState(() {
      _isAddingNew = false;
      _editingMethod = null;
    });
    _nameFocusNode.unfocus();
    _codeFocusNode.unfocus();
  }

  void _showDeleteDialog(PaymentMethod method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 28,
            ),
            const SizedBox(width: 5),
            const Text(
              'Delete Payment Method',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${method.name}"?\nThis action cannot be undone.',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePaymentMethod(method.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  // UI COMPONENTS
  // ───────────────────────────────────────────────────────────────────────

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

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1A2B2A),
      highlightColor: const Color(0xFF2F4F4D),
      child: Column(
        children: [
          _glassWrap(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
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
              'Payment Methods',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (!_isLoading && !_isAddingNew && _editingMethod == null)
            IconButton(
              icon: const Icon(
                Icons.add_rounded,
                color: Colors.tealAccent,
                size: 28,
              ),
              onPressed: _startAddNew,
              tooltip: 'Add Payment Method',
            ),
          if (!_isLoading && (_isAddingNew || _editingMethod != null))
            TextButton(
              onPressed: _cancelEdit,
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    if (!_isAddingNew && _editingMethod == null) return const SizedBox.shrink();

    final isEditing = _editingMethod != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 20),
      child: _glassWrap(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.tealAccent.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isEditing ? Icons.edit_outlined : Icons.add_rounded,
                    color: Colors.tealAccent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isEditing ? 'Edit Payment Method' : 'Add New Payment Method',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Name field
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: TextField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.06),
                    hintText: 'e.g., Cash on Delivery, Credit Card',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
                    labelText: 'Payment Method Name',
                    labelStyle: TextStyle(
                      color: Colors.tealAccent.withOpacity(0.8),
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
                        color: Colors.tealAccent,
                        width: 1.5,
                      ),
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

            // Code field
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: TextField(
                  controller: _codeController,
                  focusNode: _codeFocusNode,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_]')),
                  ],
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.06),
                    hintText: 'e.g., COD, CC, UPI',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
                    labelText: 'Payment Code',
                    labelStyle: TextStyle(
                      color: Colors.tealAccent.withOpacity(0.8),
                    ),
                    helperText:
                        'Unique identifier (uppercase letters, numbers, underscore)',
                    helperStyle: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 11,
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
                        color: Colors.tealAccent,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : (isEditing ? _updatePaymentMethod : _createPaymentMethod),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  disabledBackgroundColor: Colors.tealAccent.withOpacity(0.4),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
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
                          Icon(
                            isEditing ? Icons.save_rounded : Icons.add_rounded,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isEditing ? 'Update Method' : 'Add Method',
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
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method, int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      child: _glassWrap(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: method.isActive
                        ? Colors.tealAccent.withOpacity(0.15)
                        : Colors.grey.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.payment_rounded,
                    color: method.isActive ? Colors.tealAccent : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Name and details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.name,
                        style: TextStyle(
                          color: method.isActive
                              ? Colors.white
                              : Colors.white54,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: method.isActive
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              method.code,
                              style: TextStyle(
                                color: method.isActive
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            method.formattedDate,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Actions row - separate row for buttons on small screens
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Status toggle
                Switch(
                  value: method.isActive,
                  onChanged: _isSaving || _isDeleting
                      ? null
                      : (_) => _togglePaymentMethodStatus(method),
                  activeThumbColor: Colors.tealAccent,
                  inactiveThumbColor: Colors.grey,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),

                // Edit button
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    color: Colors.white54,
                    size: 20,
                  ),
                  onPressed: _isSaving || _isDeleting
                      ? null
                      : () => _startEdit(method),
                  tooltip: 'Edit',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),

                _isDeleting && _deletingId == method.id
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.redAccent,
                          strokeWidth: 2,
                        ),
                      )
                    : IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent.withOpacity(0.6),
                          size: 20,
                        ),
                        onPressed: _isSaving || _isDeleting
                            ? null
                            : () => _showDeleteDialog(method),
                        tooltip: 'Delete',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return _glassWrap(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.payment_outlined, color: Colors.white24, size: 64),
          const SizedBox(height: 16),
          Text(
            'No Payment Methods',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Click the + button to add a payment method',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _startAddNew,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Payment Method'),
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

  Widget _buildErrorState() {
    return _glassWrap(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Something went wrong',
            style: const TextStyle(color: Colors.red, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchPaymentMethods,
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


  @override
  Widget build(BuildContext context) {
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
              _buildHeader(),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    children: [
                 
                      _buildFormCard(),

                      if (_isLoading)
                        _buildShimmer()
                      else if (_error != null)
                        _buildErrorState()
                      else if (_paymentMethods.isEmpty)
                        _buildEmptyState()
                      else
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: SlideTransition(
                            position: _slideAnim,
                            child: Column(
                              children: [
                                for (int i = 0; i < _paymentMethods.length; i++)
                                  _buildPaymentMethodCard(
                                    _paymentMethods[i],
                                    i,
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
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



class PaymentMethod {
  final int id;
  final String name;
  final String code;
  final bool isActive;
  final DateTime createdAt;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.code,
    required this.isActive,
    required this.createdAt,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()}y ago';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}mo ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
