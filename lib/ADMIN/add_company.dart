import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:my_skates/api.dart';
import 'package:shimmer/shimmer.dart';

class AdminCompaniesPage extends StatefulWidget {
  const AdminCompaniesPage({super.key});

  @override
  State<AdminCompaniesPage> createState() => _AdminCompaniesPageState();
}

class _AdminCompaniesPageState extends State<AdminCompaniesPage>
    with SingleTickerProviderStateMixin {
  // ── Data ──────────────────────────────────────────────────────────────
  List<Company> _companies = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDeleting = false;
  String? _error;

  // ── Dropdown Data ─────────────────────────────────────────────────────
  List<Country> _countries = [];
  List<StateModel> _states = [];
  List<District> _districts = [];

  // Selected IDs for API submission (POST/PUT)
  int? _selectedCountryId;
  int? _selectedStateId;
  int? _selectedDistrictId;

  // Loading states for dropdowns
  bool _isLoadingCountries = false;
  bool _isLoadingStates = false;
  bool _isLoadingDistricts = false;

  // ── Form Controllers ──────────────────────────────────────────────────
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _gstNumberController = TextEditingController();

  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _addressFocusNode = FocusNode();
  final FocusNode _zipCodeFocusNode = FocusNode();
  final FocusNode _gstNumberFocusNode = FocusNode();

  // ── Edit Mode ─────────────────────────────────────────────────────────
  bool _isAddingNew = false;
  Company? _editingCompany;

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

    _fetchCountries();
    _fetchCompanies();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _zipCodeController.dispose();
    _gstNumberController.dispose();
    _nameFocusNode.dispose();
    _addressFocusNode.dispose();
    _zipCodeFocusNode.dispose();
    _gstNumberFocusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _nameController.clear();
    _addressController.clear();
    _zipCodeController.clear();
    _gstNumberController.clear();
    _selectedCountryId = null;
    _selectedStateId = null;
    _selectedDistrictId = null;
    _states = [];
    _districts = [];
  }

  // ───────────────────────────────────────────────────────────────────────
  // API METHODS FOR DROPDOWNS
  // ───────────────────────────────────────────────────────────────────────

  Future<void> _fetchCountries() async {
    setState(() => _isLoadingCountries = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) return;

      final response = await http.get(
        Uri.parse('$api/api/myskates/country/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("COUNTRIES GET STATUS: ${response.statusCode}");
      print("COUNTRIES GET RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        List<dynamic> countriesList;
        if (jsonData is Map && jsonData.containsKey('data')) {
          countriesList = jsonData['data'] as List<dynamic>;
        } else if (jsonData is List) {
          countriesList = jsonData;
        } else {
          countriesList = [];
        }

        List<Country> countries = [];
        for (var item in countriesList) {
          if (item is Map<String, dynamic>) {
            countries.add(Country.fromJson(item));
          }
        }

        setState(() {
          _countries = countries;
        });
      }
    } catch (e) {
      print("Error fetching countries: $e");
    } finally {
      setState(() => _isLoadingCountries = false);
    }
  }

  Future<void> _fetchStates(int countryId) async {
    setState(() {
      _states = [];
      _districts = [];
      _selectedStateId = null;
      _selectedDistrictId = null;
      _isLoadingStates = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) return;

      final response = await http.get(
        Uri.parse('$api/api/myskates/state/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("STATES GET STATUS: ${response.statusCode}");
      print("STATES GET RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        List<dynamic> statesList;
        if (jsonData is Map && jsonData.containsKey('data')) {
          statesList = jsonData['data'] as List<dynamic>;
        } else if (jsonData is List) {
          statesList = jsonData;
        } else {
          statesList = [];
        }

        List<StateModel> allStates = [];
        for (var item in statesList) {
          if (item is Map<String, dynamic>) {
            allStates.add(StateModel.fromJson(item));
          }
        }

        // Filter states by matching country name
        final selectedCountry = _countries.firstWhere(
          (c) => c.id == countryId,
          orElse: () => Country(id: 0, name: '', code: ''),
        );

        if (selectedCountry.id != 0) {
          setState(() {
            _states = allStates
                .where((s) => s.countryName == selectedCountry.name)
                .toList();
          });
        } else {
          setState(() {
            _states = allStates;
          });
        }
      }
    } catch (e) {
      print("Error fetching states: $e");
    } finally {
      setState(() => _isLoadingStates = false);
    }
  }

  Future<void> _fetchDistricts(int stateId) async {
    setState(() {
      _districts = [];
      _selectedDistrictId = null;
      _isLoadingDistricts = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) return;

      final response = await http.get(
        Uri.parse('$api/api/myskates/district/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("DISTRICTS GET STATUS: ${response.statusCode}");
      print("DISTRICTS GET RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        List<dynamic> districtsList;
        if (jsonData is Map && jsonData.containsKey('data')) {
          districtsList = jsonData['data'] as List<dynamic>;
        } else if (jsonData is List) {
          districtsList = jsonData;
        } else {
          districtsList = [];
        }

        List<District> allDistricts = [];
        for (var item in districtsList) {
          if (item is Map<String, dynamic>) {
            allDistricts.add(District.fromJson(item));
          }
        }

        // Filter districts by matching state name
        final selectedState = _states.firstWhere(
          (s) => s.id == stateId,
          orElse: () =>
              StateModel(id: 0, name: '', countryId: 0, countryName: ''),
        );

        if (selectedState.id != 0) {
          setState(() {
            _districts = allDistricts
                .where((d) => d.stateName == selectedState.name)
                .toList();
          });
        } else {
          setState(() {
            _districts = allDistricts;
          });
        }
      }
    } catch (e) {
      print("Error fetching districts: $e");
    } finally {
      setState(() => _isLoadingDistricts = false);
    }
  }

  // Helper method to find country ID by name
  int? _getCountryIdByName(String countryName) {
    final country = _countries.firstWhere(
      (c) => c.name.toLowerCase() == countryName.toLowerCase(),
      orElse: () => Country(id: 0, name: '', code: ''),
    );
    return country.id != 0 ? country.id : null;
  }

  // Helper method to find state ID by name
  int? _getStateIdByName(String stateName) {
    final state = _states.firstWhere(
      (s) => s.name.toLowerCase() == stateName.toLowerCase(),
      orElse: () => StateModel(id: 0, name: '', countryId: 0, countryName: ''),
    );
    return state.id != 0 ? state.id : null;
  }

  // Helper method to find district ID by name
  int? _getDistrictIdByName(String districtName) {
    final district = _districts.firstWhere(
      (d) => d.name.toLowerCase() == districtName.toLowerCase(),
      orElse: () => District(id: 0, name: '', stateId: 0, stateName: ''),
    );
    return district.id != 0 ? district.id : null;
  }

  // ───────────────────────────────────────────────────────────────────────
  // API METHODS FOR COMPANIES
  // ───────────────────────────────────────────────────────────────────────

  Future<void> _fetchCompanies() async {
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
        Uri.parse('$api/api/myskates/companies/view/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("COMPANIES GET STATUS: ${response.statusCode}");
      print("COMPANIES GET RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        List<dynamic> companiesList;
        if (jsonData is Map && jsonData.containsKey('data')) {
          companiesList = jsonData['data'] as List<dynamic>;
        } else if (jsonData is List) {
          companiesList = jsonData;
        } else {
          companiesList = [];
        }

        List<Company> companies = [];
        for (var item in companiesList) {
          if (item is Map<String, dynamic>) {
            companies.add(Company.fromJson(item));
          }
        }

        setState(() {
          _companies = companies;
          _isLoading = false;
        });
        _animController.forward(from: 0);
      } else {
        setState(() {
          _error = 'Failed to load companies: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching companies: $e");
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createCompany() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final zipCode = _zipCodeController.text.trim();
    final gstNumber = _gstNumberController.text.trim();

    if (name.isEmpty) {
      _showSnackBar('Please enter company name', isError: true);
      return;
    }
    if (address.isEmpty) {
      _showSnackBar('Please enter address', isError: true);
      return;
    }
    if (_selectedCountryId == null) {
      _showSnackBar('Please select a country', isError: true);
      return;
    }
    if (_selectedStateId == null) {
      _showSnackBar('Please select a state', isError: true);
      return;
    }
    if (zipCode.isEmpty) {
      _showSnackBar('Please enter zip code', isError: true);
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

      final body = {
        'name': name,
        'address': address,
        'country': _selectedCountryId,
        'state': _selectedStateId,
        'district': _selectedDistrictId,
        'zip_code': zipCode,
        'gst_number': gstNumber.isNotEmpty ? gstNumber : null,
      };

      final response = await http.post(
        Uri.parse('$api/api/myskates/companies/view/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      print("COMPANY POST STATUS: ${response.statusCode}");
      print("COMPANY POST RESPONSE: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        _clearForm();
        await _fetchCompanies();
        _showSnackBar('Company added successfully');
        _cancelEdit();
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

  Future<void> _updateCompany() async {
    if (_editingCompany == null) return;

    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final zipCode = _zipCodeController.text.trim();
    final gstNumber = _gstNumberController.text.trim();

    if (name.isEmpty) {
      _showSnackBar('Please enter company name', isError: true);
      return;
    }
    if (address.isEmpty) {
      _showSnackBar('Please enter address', isError: true);
      return;
    }
    if (_selectedCountryId == null) {
      _showSnackBar('Please select a country', isError: true);
      return;
    }
    if (_selectedStateId == null) {
      _showSnackBar('Please select a state', isError: true);
      return;
    }
    if (zipCode.isEmpty) {
      _showSnackBar('Please enter zip code', isError: true);
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

      final body = {
        'name': name,
        'address': address,
        'country': _selectedCountryId,
        'state': _selectedStateId,
        'district': _selectedDistrictId,
        'zip_code': zipCode,
        'gst_number': gstNumber.isNotEmpty ? gstNumber : null,
      };

      final response = await http.put(
        Uri.parse('$api/api/myskates/companies/update/${_editingCompany!.id}/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      print("COMPANY PUT STATUS: ${response.statusCode}");
      print("COMPANY PUT RESPONSE: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        _cancelEdit();
        await _fetchCompanies();
        _showSnackBar('Company updated successfully');
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

  Future<void> _deleteCompany(int id) async {
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
        Uri.parse('$api/api/myskates/companies/update/$id/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("COMPANY DELETE STATUS: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        await _fetchCompanies();
        _showSnackBar('Company deleted successfully');
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
    _clearForm();
    setState(() {
      _isAddingNew = true;
      _editingCompany = null;
    });
    _nameFocusNode.requestFocus();
  }

  void _startEdit(Company company) {
    _nameController.text = company.name;
    _addressController.text = company.address;
    _zipCodeController.text = company.zipCode;
    _gstNumberController.text = company.gstNumber ?? '';

    // Convert string names to IDs for dropdown selection
    setState(() {
      _editingCompany = company;
      _isAddingNew = false;
      _selectedCountryId = _getCountryIdByName(company.country);
      _selectedStateId = _getStateIdByName(company.state);
      _selectedDistrictId = company.district != null
          ? _getDistrictIdByName(company.district!)
          : null;
    });

    // Fetch states and districts if IDs are available
    if (_selectedCountryId != null) {
      _fetchStates(_selectedCountryId!);
    }
    if (_selectedStateId != null) {
      _fetchDistricts(_selectedStateId!);
    }

    _nameFocusNode.requestFocus();
  }

  void _cancelEdit() {
    _clearForm();
    setState(() {
      _isAddingNew = false;
      _editingCompany = null;
    });
    _nameFocusNode.unfocus();
    _addressFocusNode.unfocus();
    _zipCodeFocusNode.unfocus();
    _gstNumberFocusNode.unfocus();
  }

  // void _showDeleteDialog(Company company) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       backgroundColor: const Color(0xFF1A1A1A),
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  //       title: Row(
  //         children: [
  //           const Icon(
  //             Icons.warning_amber_rounded,
  //             color: Colors.redAccent,
  //             size: 28,
  //           ),
  //           const SizedBox(width: 5),
  //           const Text(
  //             'Delete Company',
  //             style: TextStyle(
  //               color: Colors.white,
  //               fontWeight: FontWeight.bold,
  //               fontSize: 20,
  //             ),
  //           ),
  //         ],
  //       ),
  //       content: Text(
  //         'Are you sure you want to delete "${company.name}"?\nThis action cannot be undone.',
  //         style: TextStyle(color: Colors.white.withOpacity(0.7)),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text(
  //             'Cancel',
  //             style: TextStyle(color: Colors.white54),
  //           ),
  //         ),
  //         ElevatedButton(
  //           onPressed: () {
  //             Navigator.pop(context);
  //             _deleteCompany(company.id);
  //           },
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: Colors.redAccent,
  //             foregroundColor: Colors.white,
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(12),
  //             ),
  //           ),
  //           child: const Text('Delete'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

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
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 120,
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
              'Companies',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (!_isLoading && !_isAddingNew && _editingCompany == null)
            IconButton(
              icon: const Icon(
                Icons.add_rounded,
                color: Colors.tealAccent,
                size: 28,
              ),
              onPressed: _startAddNew,
              tooltip: 'Add Company',
            ),
          if (!_isLoading && (_isAddingNew || _editingCompany != null))
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
    if (!_isAddingNew && _editingCompany == null) {
      return const SizedBox.shrink();
    }

    final isEditing = _editingCompany != null;

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
                  isEditing ? 'Edit Company' : 'Add New Company',
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
            _buildFormField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              label: 'Company Name *',
              hint: 'e.g., ABC Pvt Ltd',
              icon: Icons.business,
            ),
            const SizedBox(height: 16),

            // Address field
            _buildFormField(
              controller: _addressController,
              focusNode: _addressFocusNode,
              label: 'Address *',
              hint: 'e.g., MG Road, Kochi',
              icon: Icons.location_on,
            ),
            const SizedBox(height: 16),

            // Country Dropdown
            _buildDropdownField<Country>(
              value: _selectedCountryId != null
                  ? _countries.firstWhere(
                      (c) => c.id == _selectedCountryId,
                      orElse: () => Country(id: 0, name: '', code: ''),
                    )
                  : null,
              items: _countries,
              isLoading: _isLoadingCountries,
              label: 'Country *',
              hint: 'Select Country',
              icon: Icons.flag,
              onChanged: (Country? country) {
                setState(() {
                  _selectedCountryId = country?.id;
                  _selectedStateId = null;
                  _selectedDistrictId = null;
                  _states = [];
                  _districts = [];
                });
                if (country != null) {
                  _fetchStates(country.id);
                }
              },
              displayName: (country) => country.name,
            ),
            const SizedBox(height: 16),

            // State Dropdown
            _buildDropdownField<StateModel>(
              value: _selectedStateId != null
                  ? _states.firstWhere(
                      (s) => s.id == _selectedStateId,
                      orElse: () => StateModel(
                        id: 0,
                        name: '',
                        countryId: 0,
                        countryName: '',
                      ),
                    )
                  : null,
              items: _states,
              isLoading: _isLoadingStates,
              label: 'State *',
              hint: 'Select State',
              icon: Icons.map,
              onChanged: (_isLoadingStates || _states.isEmpty)
                  ? null
                  : (StateModel? state) {
                      setState(() {
                        _selectedStateId = state?.id;
                        _selectedDistrictId = null;
                        _districts = [];
                      });
                      if (state != null) {
                        _fetchDistricts(state.id);
                      }
                    },
              displayName: (state) => state.name,
            ),
            const SizedBox(height: 16),

            // District Dropdown
            _buildDropdownField<District>(
              value: _selectedDistrictId != null
                  ? _districts.firstWhere(
                      (d) => d.id == _selectedDistrictId,
                      orElse: () =>
                          District(id: 0, name: '', stateId: 0, stateName: ''),
                    )
                  : null,
              items: _districts,
              isLoading: _isLoadingDistricts,
              label: 'District',
              hint: 'Select District (Optional)',
              icon: Icons.location_city,
              onChanged: (_isLoadingDistricts || _districts.isEmpty)
                  ? null
                  : (District? district) {
                      setState(() {
                        _selectedDistrictId = district?.id;
                      });
                    },
              displayName: (district) => district.name,
            ),
            const SizedBox(height: 16),

            // Zip Code field
            _buildFormField(
              controller: _zipCodeController,
              focusNode: _zipCodeFocusNode,
              label: 'Zip Code *',
              hint: 'e.g., 682001',
              icon: Icons.local_post_office,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 10,
            ),
            const SizedBox(height: 16),

            // GST Number field
            _buildFormField(
              controller: _gstNumberController,
              focusNode: _gstNumberFocusNode,
              label: 'GST Number',
              hint: 'e.g., 32ABCDE1234F1Z5',
              icon: Icons.receipt,
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 20),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : (isEditing ? _updateCompany : _createCompany),
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
                            isEditing ? 'Update Company' : 'Add Company',
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

  Widget _buildDropdownField<T>({
    required T? value,
    required List<T> items,
    required bool isLoading,
    required String label,
    required String hint,
    required IconData icon,
    required void Function(T?)? onChanged,
    required String Function(T) displayName,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: isLoading
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: Colors.tealAccent.withOpacity(0.6),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.tealAccent,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Loading $label...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : DropdownButtonFormField<T>(
              initialValue: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF1A1A1A),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.transparent,
                labelText: label,
                labelStyle: TextStyle(
                  color: Colors.tealAccent.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                floatingLabelStyle: const TextStyle(
                  color: Colors.tealAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Icon(
                  icon,
                  color: Colors.tealAccent.withOpacity(0.7),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
              ),
              hint: Text(
                hint,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 14,
                ),
              ),
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(displayName(item)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.transparent,
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.35),
            fontSize: 14,
          ),
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.tealAccent.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          floatingLabelStyle: const TextStyle(
            color: Colors.tealAccent,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.tealAccent.withOpacity(0.7),
            size: 20,
          ),
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyCard(Company company, int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      child: _glassWrap(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.tealAccent.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.business_center,
                    color: Colors.tealAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (company.gstNumber != null)
                        Text(
                          'GST: ${company.gstNumber}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        color: Colors.white54,
                        size: 20,
                      ),
                      onPressed: _isSaving || _isDeleting
                          ? null
                          : () => _startEdit(company),
                      tooltip: 'Edit',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                    // _isDeleting && _deletingId == company.id
                    //     ? const SizedBox(
                    //         width: 24,
                    //         height: 24,
                    //         child: CircularProgressIndicator(
                    //           color: Colors.redAccent,
                    //           strokeWidth: 2,
                    //         ),
                    //       )
                    //     : IconButton(
                    //         icon: Icon(
                    //           Icons.delete_outline,
                    //           color: Colors.redAccent.withOpacity(0.6),
                    //           size: 20,
                    //         ),
                    //         onPressed: _isSaving || _isDeleting
                    //             ? null
                    //             : () => _showDeleteDialog(company),
                    //         tooltip: 'Delete',
                    //         padding: EdgeInsets.zero,
                    //         constraints: const BoxConstraints(
                    //           minWidth: 36,
                    //           minHeight: 36,
                    //         ),
                    //       ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.tealAccent.withOpacity(0.6),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    company.address,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _buildInfoChip(Icons.flag, company.country),
                _buildInfoChip(Icons.map, company.state),
                if (company.district != null)
                  _buildInfoChip(Icons.location_city, company.district!),
                _buildInfoChip(Icons.local_post_office, company.zipCode),
              ],
            ),

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.access_time,
                  color: Colors.white.withOpacity(0.2),
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  'Updated: ${company.formattedUpdatedAt}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.25),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.tealAccent.withOpacity(0.5), size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return _glassWrap(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.business_center_outlined, color: Colors.white24, size: 64),
          const SizedBox(height: 16),
          Text(
            'No Companies',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Click the + button to add a company',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _startAddNew,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Company'),
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
            onPressed: _fetchCompanies,
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
                      else if (_companies.isEmpty)
                        _buildEmptyState()
                      else
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: SlideTransition(
                            position: _slideAnim,
                            child: Column(
                              children: [
                                for (int i = 0; i < _companies.length; i++)
                                  _buildCompanyCard(_companies[i], i),
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

// ───────────────────────────────────────────────────────────────────────
// MODELS
// ───────────────────────────────────────────────────────────────────────

class Country {
  final int id;
  final String name;
  final String code;

  Country({required this.id, required this.name, required this.code});

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
    );
  }
}

class StateModel {
  final int id;
  final String name;
  final int countryId;
  final String countryName;

  StateModel({
    required this.id,
    required this.name,
    required this.countryId,
    required this.countryName,
  });

  factory StateModel.fromJson(Map<String, dynamic> json) {
    int countryId;
    String countryName;

    final countryValue = json['country'];
    if (countryValue is String) {
      countryName = countryValue;
      countryId = 0;
    } else if (countryValue is int) {
      countryId = countryValue;
      countryName = json['country_name']?.toString() ?? '';
    } else if (countryValue is Map) {
      countryId = countryValue['id'] as int;
      countryName = countryValue['name'] as String;
    } else {
      countryId = 0;
      countryName = '';
    }

    return StateModel(
      id: json['id'] as int,
      name: json['name'] as String,
      countryId: countryId,
      countryName: countryName,
    );
  }
}

class District {
  final int id;
  final String name;
  final int stateId;
  final String stateName;

  District({
    required this.id,
    required this.name,
    required this.stateId,
    required this.stateName,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    int stateId;
    String stateName;

    final stateValue = json['state'];
    if (stateValue is String) {
      stateName = stateValue;
      stateId = 0;
    } else if (stateValue is int) {
      stateId = stateValue;
      stateName = json['state_name']?.toString() ?? '';
    } else if (stateValue is Map) {
      stateId = stateValue['id'] as int;
      stateName = stateValue['name'] as String;
    } else {
      stateId = 0;
      stateName = '';
    }

    return District(
      id: json['id'] as int,
      name: json['name'] as String,
      stateId: stateId,
      stateName: stateName,
    );
  }
}

class Company {
  final int id;
  final String country;
  final String state;
  final String? district;
  final String? createdBy;
  final String name;
  final String address;
  final String zipCode;
  final String? gstNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  Company({
    required this.id,
    required this.country,
    required this.state,
    this.district,
    this.createdBy,
    required this.name,
    required this.address,
    required this.zipCode,
    this.gstNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as int,
      country: json['country'] as String,
      state: json['state'] as String,
      district: json['district'] as String?,
      createdBy: json['created_by'] as String?,
      name: json['name'] as String,
      address: json['address'] as String,
      zipCode: json['zip_code'] as String,
      gstNumber: json['gst_number'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  String get formattedUpdatedAt {
    final now = DateTime.now();
    final diff = now.difference(updatedAt);

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
      'country': country,
      'state': state,
      'district': district,
      'created_by': createdBy,
      'name': name,
      'address': address,
      'zip_code': zipCode,
      'gst_number': gstNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
