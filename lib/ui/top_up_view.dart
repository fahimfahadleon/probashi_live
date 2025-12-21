import 'package:flutter/material.dart';
import 'package:probashi_live/models/create_payment_dto.dart';
import 'package:probashi_live/models/gateway_model.dart';
import 'package:probashi_live/models/settings_model.dart';
import 'package:probashi_live/utils/api_service.dart';

import '../models/vip_diamond_pack.dart';
import '../utils/utils.dart';
// your existing ApiService

class TopUpView extends StatefulWidget {
  const TopUpView({super.key});

  @override
  State<TopUpView> createState() => _TopUpViewState();
}

class _TopUpViewState extends State<TopUpView> {
  List<ProductVipPackDto> _packs = [];
  late Settings settings;
  bool _loading = true;
  late List<Gateway> gateways;

  @override
  void initState() {
    super.initState();
    initSettings();
    _fetchPacks();
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

  Future<void> _fetchPacks() async {
    try {
      final packs = await ApiService.getApiClient().getVipPacks();
      setState(() {
        _packs = packs;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Failed to fetch packs: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("VIP Diamond Packs")),
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
          child: const Center(child: CircularProgressIndicator())
      )
          : Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                gradient: LinearGradient(
                  colors: [Color(0xFFDCB3FF), Color(0xFFB3E5FC)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: ListView.builder(
                itemCount: _packs.length,
                itemBuilder: (context, index) {
                  final pack = _packs[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      title: Text('${pack.pack.diamonds} 💎'),
                      subtitle: Text('\$${pack.pack.price.toStringAsFixed(2)}'),
                      trailing: Text(
                        'Created: ${pack.pack.createdAt.toLocal().toString().split(".")[0]}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () => _showPaymentDialog(context, pack),
                    ),
                  );
                },
              ),
            ),
    );
  }

  void _showPaymentDialog(BuildContext context, ProductVipPackDto dto) {
    final txnIdController = TextEditingController();
    final descController = TextEditingController();

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
                'Buy ${dto.pack.diamonds} 💎 for \$${dto.pack.price.toStringAsFixed(2)}',
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
                        decoration: InputDecoration(labelText: 'Description (optional)'),
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

}
