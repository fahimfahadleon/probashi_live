import 'package:flutter/material.dart';
import '../models/create_payment_dto.dart';
import '../models/gateway_model.dart';
import '../models/offer.dart';
import '../models/settings_model.dart';
import '../utils/api_service.dart';
import '../utils/utils.dart'; // For showToast, etc.

class OfferListView extends StatefulWidget {
  const OfferListView({super.key});

  @override
  State<OfferListView> createState() => _OfferListViewState();
}

class _OfferListViewState extends State<OfferListView> {
  List<ProductOfferDto> _offers = [];
  bool _loading = true;
  late List<Gateway> gateways;
  late Settings settings;

  @override
  void initState() {
    super.initState();
    initSettings();
    _fetchOffers();
  }

  Future<void> initSettings() async {
    final fetchedSettings = await Utils.fetchSettings(); // call the static function
    if (fetchedSettings != null) {
      settings = fetchedSettings;
      gateways = fetchedSettings.gateways ?? []; // fallback to empty list
    }else{
      throw Exception('Failed to fetch settings');
    }
  }

  Future<void> _fetchOffers() async {
    try {
      final offers = await ApiService.getApiClient().getOffers();
      setState(() {
        _offers = offers;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      Utils.showSnackbar(context, "Failed to load offers");
    }
  }


  void _showPaymentDialog(BuildContext context, ProductOfferDto dto) {
    final txnIdController = TextEditingController();
    final descController = TextEditingController(text: 'Offer: ${dto.offer.content}');

    int selectedGatewayIndex = 0;


    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final selectedGateway = gateways[selectedGatewayIndex];


            return AlertDialog(
              insetPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              title: Text(
                'Buy ${dto.offer.diamonds} 💎 for \$${dto.offer.price.toStringAsFixed(2)}',
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Payment Gateway Dropdown
                      DropdownButton<int>(
                        value: selectedGatewayIndex,
                        items: List.generate(gateways.length, (index) {
                          final g = gateways[index];
                          return DropdownMenuItem<int>(
                            value: index,
                            child: Text('${g.phone} (${g.provider})'),
                          );
                        }),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedGatewayIndex = value;
                              Utils.copyToClipboard(gateways[value].phone);
                              Utils.showSnackbar(context, "Phone Number Copied!");
                            });
                          }
                        },
                        isExpanded: true,
                      ),



                      TextField(
                        controller: txnIdController,
                        decoration: InputDecoration(labelText: 'Transaction ID'),
                      ),
                      TextField(
                        controller: descController,
                        readOnly: true, // makes the field not editable
                        decoration: InputDecoration(
                          labelText: 'Description (optional)',
                        ),
                      ),
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: CircularProgressIndicator(),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                    final txn = txnIdController.text.trim();
                    final desc = descController.text.trim();
                    final methodName = selectedGateway.provider;
                    final phoneForPayment = selectedGateway.phone;

                    if (txn.isEmpty || methodName.isEmpty) {
                      Utils.showSnackbar(context, "Transaction ID and payment method are required");
                      return;
                    }

                    setState(() => isLoading = true);

                    final payment = CreatePaymentDto(
                      transactionId: txn,
                      method: methodName,
                      productId: dto.id,
                      description: desc.isEmpty ? "" : "$desc (Pay to: $phoneForPayment)",
                    );


                    try {
                      await ApiService.getApiClient().requestPayment(payment);
                      Navigator.pop(context);
                      Utils.showSnackbar(context, "Payment request is successful");
                    } catch (e) {
                      debugPrint('Payment error: $e');
                      setState(() => isLoading = false);
                      Utils.showSnackbar(context, "Failed to submit payment request");
                    }
                  },
                  child: const Text("Submit"),
                ),
              ],
            );
          },
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Offer List", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
      ),
      body: _loading
          ? Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                gradient: LinearGradient(
                  colors: [Color(0xFFDCB3FF), Color(0xFFB3E5FC)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const Center(child: CircularProgressIndicator()),
            )
          : Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                gradient: LinearGradient(
                  colors: [Color(0xFFDCB3FF), Color(0xFFB3E5FC)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: ListView.builder(
                itemCount: _offers.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final offer = _offers[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offer.offer.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            offer.offer.content,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "\$${offer.offer.price.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () =>
                                  _showPaymentDialog(context, offer),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.yellow.shade700,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text("Activate"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
