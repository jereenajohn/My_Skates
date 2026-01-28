import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/ADMIN/slideRightRoute.dart';
import 'package:my_skates/ADMIN/update_product.dart';
import 'package:my_skates/ADMIN/update_product_variant.dart';
import 'package:my_skates/STUDENTS/Home_Page.dart';
import 'package:my_skates/api.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class variant extends StatefulWidget {
  var productId;
   variant({super.key,required this.productId});

  @override
  State<variant> createState() => _variantState();
}

class _variantState extends State<variant> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();


List<Map<String, dynamic>> filteredValues = [];
/// attributeId -> list of valueIds
Map<String, List<String>> selectedAttributes = {};

Map<String, List<Map<String, dynamic>>> groupedValues = {};
String? selectedAttributeId;
bool loadingVariants = true;
bool loadingAttributes = true;
List<String> selectedValueIds = []; // values for selected attribute
String? activeAttributeId;
List<String> tempSelectedValueIds = [];

  @override
  void initState() {
    super.initState();
    loadAllData();
  }
Future<void> loadAllData() async {
  setState(() {
    loadingVariants = true;
    loadingAttributes = true;
  });

  await Future.wait([
    getVariants(),
    getvalues(),
    getattribute(),
  ]);

  setState(() {
    loadingVariants = false;
    loadingAttributes = false;
  });
}


 void toggleAttributeValue({
  required String attributeId,
  required String valueId,
  required bool selected,
}) {
  setState(() {
    selectedAttributes.putIfAbsent(attributeId, () => []);

    if (selected) {
      if (!selectedAttributes[attributeId]!.contains(valueId)) {
        selectedAttributes[attributeId]!.add(valueId);
      }
    } else {
      selectedAttributes[attributeId]!.remove(valueId);
      if (selectedAttributes[attributeId]!.isEmpty) {
        selectedAttributes.remove(attributeId);
      }
    }
  });
}

void cleanSelectedAttributes() {
  selectedAttributes.removeWhere((key, value) => value.isEmpty);
}

List<Map<String, dynamic>> variants = [];

Future<void> getVariants() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    final response = await http.get(
      Uri.parse('$api/api/myskates/products/${widget.productId}/variants/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );


    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      final List data = decoded['data']; // ✅ IMPORTANT

      List<Map<String, dynamic>> temp = [];

      for (var v in data) {

        temp.add({
          'id': v['id'],
          'sku': v['sku'],
          'price': v['price'],
          'discount': v['discount'],
          'stock': v['stock'],
          'attribute_values': v['attribute_values'],
        'image': (v['images'] != null &&
        v['images'] is List &&
        v['images'].isNotEmpty &&
        v['images'][0]['image'] != null)
    ? "$api${v['images'][0]['image']}"
    : null,


        });
      }

      setState(() {
        variants = temp;
      });

    }
  } catch (e) {
  }
}

List<Map<String, dynamic>> values = [];
Future<void> getvalues() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    if (token == null) return;

    final response = await http.get(
      Uri.parse('$api/api/myskates/attributes/values/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final parsed = jsonDecode(response.body);
      final List data = parsed['data'];

      /// reset lists
      values.clear();
      groupedValues.clear();

      for (var item in data) {
        final valueMap = {
          'id': item['id'],
          'name': item['name'],
          'attribute_id': item['attributes'].toString(),
          'attribute_name': item['attribute_name'],
        };

        values.add(valueMap);

        /// group by attribute
        final attrId = item['attributes'].toString();
        groupedValues.putIfAbsent(attrId, () => []);
        groupedValues[attrId]!.add(valueMap);
      }

      setState(() {
        // trigger rebuild
      });

      groupedValues.forEach((k, v) {
      });
    }
  } catch (e) {
  }
}

 List<Map<String, dynamic>> attributes = [];

    Future<void> getattribute() async {
    try {
       final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      var response = await http.get(
        Uri.parse('$api/api/myskates/attributes/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
        
        List<Map<String, dynamic>> statelist = [];
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        
 for (var productData in productsData) {
          String imageUrl = "${productData['image']}";
          statelist.add({
            'id': productData['id'],
            'name': productData['name'],
            
          });
        
        }
        setState(() {
          attributes = statelist;
          print("attributes:$attributes");
                  

          
        });
      }
    } catch (error) {
      
    }
  }
  void _handleUpdateProduct(Map<String, dynamic> product) {
  print("UPDATE ${product['id']}");
 Navigator.push(
  context,
  slideRightToLeftRoute(
    UpdateProductVariant(productId: product['id']),
  ),
);

}
Future<void> submitProduct() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login expired. Please login again.")),
      );
      return;
    }

    if (selectedAttributes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least one attribute value"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    //  BUILD ATTRIBUTES PAYLOAD (attribute_id → [value_ids])
    final Map<String, List<int>> attributesPayload = {};

    selectedAttributes.forEach((attrId, valueIds) {
      if (valueIds.isNotEmpty) {
        attributesPayload[attrId.toString()] =
            valueIds.map((v) => int.parse(v)).toList();
      }
    });

    // PAYLOAD EMPTY AFTER BUILD
    if (attributesPayload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid attribute selection"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    print("Attributes Payload: $attributesPayload");

    var request = http.MultipartRequest(
      "POST",
      Uri.parse(
        "$api/api/myskates/products/${widget.productId}/variants/",
      ),
    );

    request.headers["Authorization"] = "Bearer $token";

   
    request.fields["attributes"] = jsonEncode(attributesPayload);

    print("---- REQUEST FIELDS ----");
    request.fields.forEach((key, value) {
      print("$key : $value");
    });

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    print("STATUS: ${response.statusCode}");
    print("BODY::::::::::::::::::::::::::::::::::::::::::: $responseBody");

    if (response.statusCode == 201 || response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Variants created successfully"),
          backgroundColor: Colors.teal,
        ),
      );

      getVariants();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed: $responseBody"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  } catch (e) {
    print("Error in submitProduct: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Something went wrong"),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),  
  extendBodyBehindAppBar: true,  
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00312D), Color(0xFF000000)],
            begin: Alignment.topLeft,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Align(
  alignment: Alignment.topLeft,
  child: GestureDetector(
    onTap: () {
      Navigator.pop(context);
    },
    child: Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 134, 134, 134).withOpacity(0.15),   
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
      ),
      child: const Icon(
        Icons.keyboard_arrow_left_rounded,
        color: Color.fromARGB(255, 78, 78, 78),
        size: 28,
      ),
    ),
  ),
),

SizedBox(height: 20),
if (loadingAttributes) ...[
  _attributeDropdownSkeleton(),
  _attributeValuesSkeleton(),
  const SizedBox(height: 10),
] else ...[
  _attributeDropdown(),
  _attributeValuesSelector(),
  const SizedBox(height: 10),
  _selectedAttributesPreview(),
],





SizedBox(height: 10,),
                 if (loadingAttributes)
  _submitButtonSkeleton()
else
  SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: () {
        if (!_formKey.currentState!.validate()) return;
        submitProduct();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: const Text(
        "Submit",
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    ),
  ),

                  const SizedBox(height: 24),

if (loadingVariants) ...[
  GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: 4,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.72,
    ),
    itemBuilder: (_, __) => _variantSkeletonCard(),
  ),
] else if (variants.isNotEmpty) ...[
  Align(
    alignment: Alignment.centerLeft,
    child: Text(
      "Created Variants",
      style: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
  const SizedBox(height: 12),

  GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: variants.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.72,
    ),
    itemBuilder: (context, index) {
  final variant = variants[index];

  return Dismissible(
    key: ValueKey(variant['id']),
    direction: DismissDirection.startToEnd, 
    background: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade900,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.edit,
        color: Colors.white,
        size: 28,
      ),
    ),

    confirmDismiss: (_) async {
      _handleUpdateProduct(variant);
  
      return false; //prevent actual dismiss
    },

    child: _variantCard(variant),
  );
},

  ),
]

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      floatingLabelStyle: const TextStyle(color: Colors.white60),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      errorStyle: const TextStyle(
        color: Colors.redAccent,
        fontSize: 12,
      ),
    );
  }

 Widget _dropdownField({
  required String label,
  required String? value,
  required List<Map<String, dynamic>> items,
  required Function(String?) onChange,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: DropdownButtonFormField<String>(
      value: value,
      decoration: _dec(label),
      dropdownColor: Colors.black,
      style: const TextStyle(color: Colors.white),
      items: items.map((e) {
        return DropdownMenuItem<String>(
          value: e["id"].toString(),
          child: Text(e["name"]),
        );
      }).toList(),
      onChanged: onChange,
      validator: (v) =>
          v == null || v.isEmpty ? "$label is required" : null,
    ),
  );
}
void _openAttributeDropdown({
  required String attributeId,
  required String attributeName,
  required List values,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF121212),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Select $attributeName",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: ListView(
                    children: values.map<Widget>((item) {
                      final valueId = item["id"].toString();
                      final isSelected =
                          selectedAttributes[attributeId]
                                  ?.contains(valueId) ??
                              false;

                      return CheckboxListTile(
                        value: isSelected,
                        activeColor: Colors.tealAccent,
                        checkColor: Colors.black,
                        title: Text(
                          item["name"],
                          style: const TextStyle(color: Colors.white),
                        ),
                        onChanged: (val) {
                          setModalState(() {
                            toggleAttributeValue(
                              attributeId: attributeId,
                              valueId: valueId,
                              selected: val ?? false,
                            );
                          });
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Done",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
Widget _variantCard(Map<String, dynamic> v) {
  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.25),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
            ),
            child: v['image'] != null
                ? Image.network(v['image'], fit: BoxFit.cover)
                : const Icon(Icons.inventory, color: Colors.grey, size: 40),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          v['sku']?.isNotEmpty == true
              ? v['sku']
              : "Variant #${v['id']}",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          "₹${v['price']}",
          style: const TextStyle(
            color: Colors.tealAccent,
            fontWeight: FontWeight.bold,
          ),
        ),

        Text(
          "Stock: ${v['stock']}",
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}
Widget _attributeSkeleton() {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}
Widget _variantSkeletonCard() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white10,
      borderRadius: BorderRadius.circular(14),
    ),
  );
}
Widget _attributeDropdown() {
  return DropdownButtonFormField<String>(
    value: activeAttributeId,
    decoration: _dec("Select Attribute"),
    dropdownColor: Colors.black,
    style: const TextStyle(color: Colors.white),
    items: attributes.map((attr) {
      return DropdownMenuItem<String>(
        value: attr["id"].toString(),
        child: Text(attr["name"]),
      );
    }).toList(),
    onChanged: (val) {
      setState(() {
        activeAttributeId = val;
        tempSelectedValueIds.clear();
      });
    },
  );
}
Widget _attributeDropdownSkeleton() {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Container(
      height: 64,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
    ),
  );
}
Widget _attributeValuesSkeleton() {
  return Column(
    children: List.generate(3, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          height: 22,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }),
  );
}
Widget _submitButtonSkeleton() {
  return Container(
    width: double.infinity,
    height: 52,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(10),
    ),
  );
}

Widget _attributeValuesSelector() {
  if (activeAttributeId == null) return const SizedBox();

  final values = groupedValues[activeAttributeId] ?? [];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 12),
      const Text(
        "Select Values",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),

      ...values.map((v) {
        final id = v["id"].toString();
        return CheckboxListTile(
          value: tempSelectedValueIds.contains(id),
          activeColor: Colors.tealAccent,
          title: Text(v["name"], style: const TextStyle(color: Colors.white)),
          onChanged: (checked) {
            setState(() {
              if (checked == true) {
                tempSelectedValueIds.add(id);
              } else {
                tempSelectedValueIds.remove(id);
              }
            });
          },
        );
      }).toList(),

      const SizedBox(height: 10),

     SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    style: _primaryButtonStyle(),
    onPressed: _addAttributeWithValues,
    child: const Text(
      "Add Attribute",
      style: TextStyle(color: Colors.white, fontSize: 16),
    ),
  ),
),

    ],
  );
}
void _addAttributeWithValues() {
  if (activeAttributeId == null || tempSelectedValueIds.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Select attribute and at least one value"),
        backgroundColor: Colors.redAccent,
      ),
    );
    return;
  }

  setState(() {
    selectedAttributes[activeAttributeId!] =
        List.from(tempSelectedValueIds);

    // reset for next attribute
    activeAttributeId = null;
    tempSelectedValueIds.clear();
  });
}
Widget _selectedAttributesPreview() {
  if (selectedAttributes.isEmpty) return const SizedBox();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 16),
      const Text(
        "Selected Attributes",
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 10),

      ...selectedAttributes.entries.map((entry) {
        final attr = attributes.firstWhere(
          (a) => a["id"].toString() == entry.key,
        );
        final attrName = attr["name"];

        final valueNames = entry.value
            .map(
              (id) =>
                  values.firstWhere((v) => v["id"].toString() == id)["name"],
            )
            .join(", ");

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Attribute name
              Expanded(
                flex: 3,
                child: Text(
                  attrName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Values
              Expanded(
                flex: 5,
                child: Text(
                  valueNames,
                  style: const TextStyle(
                    color: Colors.tealAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Remove attribute
              GestureDetector(
                onTap: () {
                  setState(() {
                    selectedAttributes.remove(entry.key);
                  });
                },
                child: const Icon(
                  Icons.close,
                  size: 18,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ],
  );
}

ButtonStyle _primaryButtonStyle() {
  return ElevatedButton.styleFrom(
    backgroundColor: Colors.teal,
    padding: const EdgeInsets.symmetric(vertical: 15),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  );
}

}
