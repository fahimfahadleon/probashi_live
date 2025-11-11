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
  List<VIPDiamondPack> _packs = [];
  late Settings settings;
  bool _loading = true;
  late List<Gateway> gateways;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
    _fetchPacks();
  }


  Future<void> _fetchSettings() async {
    try {
      settings = await ApiService.getApiClient().getSettings();
      gateways = settings.gateways!;

    } catch (e) {
      debugPrint('Failed to fetch settings: $e');
    }
  }
  Future<void> _fetchPacks() async {
    try {
      final packs = await ApiService.getApiClient().getDiamondPacks();
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
          ? const Center(child: CircularProgressIndicator())
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
                      title: Text('${pack.diamonds} 💎'),
                      subtitle: Text('\$${pack.price.toStringAsFixed(2)}'),
                      trailing: Text(
                        'Created: ${pack.createdAt.toLocal().toString().split(".")[0]}',
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

  void _showPaymentDialog(BuildContext context, VIPDiamondPack pack) {
    final txnIdController = TextEditingController();
    final methodController = TextEditingController();
    final descController = TextEditingController();
    var selectedIndex = 0;

    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            insetPadding: EdgeInsets.symmetric(
              vertical: 0,
              horizontal: 16,
            ),
            title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Buy ${pack.diamonds} 💎 for \$${pack.price.toStringAsFixed(2)}'),
              SizedBox(height: 16),
              DropdownButton<int>(
                value: selectedIndex,
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
                      selectedIndex = value;
                      final g = gateways[value];
                      Utils.copyToClipboard(g.phone);
                      Utils.showToast(context, "Phone Number Copied!");
                    });
                  }
                },
                isExpanded: true,
              ),
            ],
          ),
            content: SizedBox(
              width: MediaQuery
                  .of(context)
                  .size
                  .width * 0.9,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: txnIdController,
                      decoration: InputDecoration(labelText: 'Transaction ID'),
                    ),
                    TextField(
                      controller: methodController,
                      decoration: InputDecoration(labelText: 'Payment Method'),
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
                  final method = methodController.text.trim();
                  final desc = descController.text.trim();

                  if (txn.isEmpty || method.isEmpty) {
                    Utils.showToast(context, "Transaction ID and Payment Method are required");
                    return;
                  }

                  setState(() => isLoading = true);

                  final dto = CreatePaymentDto(
                    transactionId: txn,
                    method: method,
                    itemId: pack.id,
                    description: desc.isEmpty ? null : desc,
                  );

                  try {
                    await ApiService.getApiClient().requestPayment(dto);
                    Navigator.pop(context);
                    Utils.showToast(context, "Payment request is successful");
                  } catch (e) {
                    debugPrint('Payment error: $e');
                    setState(() => isLoading = false);
                    Utils.showToast(context, "Failed to submit payment request");
                  }
                },
                child: const Text("Submit"),
              ),
            ],
          );
        });
      },
    );
  }




}
