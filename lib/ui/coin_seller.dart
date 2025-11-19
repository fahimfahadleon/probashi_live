import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/coin_seller_models.dart';
import '../models/vip_diamond_pack.dart';
import '../models/user_profile.dart';
import '../utils/api_service.dart';
import '../utils/variables.dart';
import '../utils/utils.dart';
import '../ui/cached_circle_avatar.dart';

enum CoinSellerStatus { loading, notApplied, pending, active, inactive }

class CoinSellerPage extends StatefulWidget {
  const CoinSellerPage({super.key});

  @override
  State<CoinSellerPage> createState() => _CoinSellerPageState();
}

class _CoinSellerPageState extends State<CoinSellerPage> {
  CoinSellerStatus _status = CoinSellerStatus.loading;
  CoinSeller? _seller;
  bool _isSubmitting = false;

  List<ProductVipPackDto> _diamondPacks = [];
  UserProfile? _foundRecipient;
  final TextEditingController _recipientIdController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _canSendCoins = false;

  @override
  void initState() {
    super.initState();
    _loadSeller().then((value) => {});
  }

  Future<void> _loadSeller() async {
    setState(() => _status = CoinSellerStatus.loading);
    try {
      final seller = await ApiService.getApiClient().getSellerById(
        Variables.currentUser!.id,
      );

      if (seller.status == "inactive") {
        setState(() => _status = CoinSellerStatus.inactive);
        return;
      }

      _loadDiamondPacks();

      setState(() {
        _seller = seller;
        _status = CoinSellerStatus.active;
      });
    } catch (e) {
      print('error: $e');

      if (e is DioException) {
        final data = e.response?.data;

        // Backend actual error message
        final message = data is Map<String, dynamic>
            ? data['message']?.toString()
            : null;

        if (message == 'Seller not found') {
          try {
            await ApiService.getApiClient().getUserRequest(
              Variables.currentUser!.id,
            );
            setState(() => _status = CoinSellerStatus.pending);
          } catch (_) {
            setState(() => _status = CoinSellerStatus.notApplied);
          }
          return;
        }
      }

      Utils.showToast(context, 'Failed to load seller info');
      setState(() => _status = CoinSellerStatus.notApplied);
    }
  }

  Future<void> _loadDiamondPacks() async {
    try {
      final packs = await ApiService.getApiClient().getVipPacks();
      setState(() => _diamondPacks = packs);
    } catch (e) {
      debugPrint('Failed to load diamond packs: $e');
    }
  }

  Future<void> _registerSeller({
    required String fullName,
    required String nationalId,
    required String phone,
    required String email,
  }) async {
    setState(() => _isSubmitting = true);
    try {
      final request = ApplyCoinSellerRequest(
        userId: Variables.currentUser!.id,
        fullName: fullName,
        phoneNumber: phone,
        nationalId: nationalId,
        email: email,
      );
      await ApiService.getApiClient().applyAsCoinSeller(request);
      Utils.showToast(context, 'Application submitted successfully!');
      setState(() => _status = CoinSellerStatus.pending);
    } catch (e) {
      debugPrint('Error registering seller: $e');
      Utils.showToast(context, 'Registration failed');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _findRecipient() async {
    final id = _recipientIdController.text.trim();
    if (id.isEmpty) return;
    try {
      final user = await ApiService.getApiClient().getUserProfile(id);
      setState(() {
        _foundRecipient = user;
        _canSendCoins = true;
      });
    } catch (_) {
      setState(() => _canSendCoins = false);
    }
  }

  Future<void> _sendCoins() async {
    if (!_canSendCoins || _amountController.text.isEmpty) return;

    String fromId = Variables.currentUser!.id;
    String toUserId = _foundRecipient!.id;
    String sellerId = _seller!.id;

    int? amount = int.tryParse(_amountController.text);
    if (amount == null) {
      Utils.showToast(context, 'Invalid amount:');
      throw Exception('Invalid amount: ${_amountController.text}');
    }
    SendCoinsRequest request = SendCoinsRequest(
      sellerId: sellerId,
      fromId: fromId,
      toUserId: toUserId,
      amount: amount,
    );

    try {
      await ApiService.getApiClient().sendCoins(request);
    } catch (e) {
      print(e);
      Utils.showToast(context, "Failed to send coins");
    }

    Utils.showToast(
      context,
      'Successfully sent ${_amountController.text} coins to ${_foundRecipient!.name}',
    );

    setState(() {
      _recipientIdController.clear();
      _amountController.clear();
      _foundRecipient = null;
      _canSendCoins = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // default is true
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(child: _buildBody()),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case CoinSellerStatus.loading:
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFDCB3FF), Color(0xFFB3E5FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(child: CircularProgressIndicator()),
        );

      case CoinSellerStatus.notApplied:
        return _buildRegistrationView();

      case CoinSellerStatus.pending:
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFDCB3FF), Color(0xFFB3E5FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.hourglass_top, size: 48, color: Colors.black54),
                SizedBox(height: 12),
                Text(
                  'Your seller request is pending approval',
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                ),
              ],
            ),
          ),
        );

      case CoinSellerStatus.active:
        return _buildSellerDashboard();
      case CoinSellerStatus.inactive:
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFDCB3FF), Color(0xFFB3E5FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text("Seller is not active. Contact administrator."),
          ),
        );
    }
  }

  Widget _buildRegistrationView() {
    final fullNameController = TextEditingController();
    final nationalIdController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFDCB3FF), Color(0xFFB3E5FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 4,
            color: Colors.white.withAlpha((0.9 * 255).toInt()),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Register as a Coin Seller',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField('Full Name', fullNameController),
                  _buildTextField('National ID', nationalIdController),
                  _buildTextField('Phone Number', phoneController),
                  _buildTextField('Email', emailController),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            _registerSeller(
                              fullName: fullNameController.text.trim(),
                              nationalId: nationalIdController.text.trim(),
                              phone: phoneController.text.trim(),
                              email: emailController.text.trim(),
                            );
                          },
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Register'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSellerDashboard() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFDCB3FF), Color(0xFFB3E5FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Page title: fixed at top
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Coin Seller Dashboard',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54, // adjust for your theme
                  ),
                ),
              ),
            ),

            // Seller Info Card: fixed size
            _buildSellerInfoCard(),
            const SizedBox(height: 16),

            // Diamond Packs List with fixed height (scrollable)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Buy Diamond Packs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _buildDiamondPacksList(), // make sure this is a ListView
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Send Coins to a User',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
            _buildSendCoinsCard(),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Full Name: ${_seller!.fullName}',
              style: const TextStyle(fontSize: 16),
            ),
            Text('Email: ${_seller!.email}'),
            Text('Phone: ${_seller!.phoneNumber}'),
            Text('National ID: ${_seller!.nationalId}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDiamondPacksList() {
    return Column(
      children: _diamondPacks
          .map(
            (pack) => Card(
              child: ListTile(
                leading: const Icon(Icons.diamond, color: Colors.lightBlue),
                title: Text('${pack.pack.diamonds} Diamonds'),
                subtitle: Text(
                  'Price: \$${pack.pack.price.toStringAsFixed(2)}',
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    Utils.showToast(context, 'Buying pack ${pack.id}');
                  },
                  child: const Text('Buy'),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSendCoinsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _recipientIdController,
              decoration: const InputDecoration(
                labelText: 'Recipient User ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Find User'),
              onPressed: _findRecipient,
            ),
            if (_foundRecipient != null) ...[
              const SizedBox(height: 12),
              ListTile(
                leading: CachedCircleAvatar(
                  imageUrl: _foundRecipient!.profilePic,
                  user: _foundRecipient!.settings,
                  radius: 20,
                ),
                title: Text(_foundRecipient!.name),
                subtitle: Text('ID: ${_foundRecipient!.id}'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.monetization_on, color: Colors.amber),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _canSendCoins ? _sendCoins : null,
                child: const Text('Send Coins'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  // Widget _buildSectionTitle(String title) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 8),
  //     child: Text(
  //       title,
  //       style: const TextStyle(
  //         fontSize: 18,
  //         fontWeight: FontWeight.bold,
  //         color: Colors.black54,
  //       ),
  //     ),
  //   );
  // }
}
