import 'package:flutter/material.dart';
import 'package:probashi_live/models/vip_diamond_pack.dart';
import 'package:probashi_live/utils/variables.dart';
class MockUser {
  final String id;
  final String name;
  final String avatarUrl;

  MockUser({required this.id, required this.name, required this.avatarUrl});
}

class CoinSeller extends StatefulWidget {
  const CoinSeller({Key? key}) : super(key: key);

  @override
  State<CoinSeller> createState() => _CoinSellerState();
}

class _CoinSellerState extends State<CoinSeller> {
  // --- STATE MANAGEMENT ---
  // This boolean will determine which UI to show.
  // In a real app, you would get this from your settings/backend.
  bool _isCoinSeller = false;

  int _userCoins = 12500; // Mock data for current seller's coins.

  // Controller for the "Send Coins" feature
  final TextEditingController _recipientIdController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  MockUser? _foundRecipient; // To hold the details of the recipient user.

  // --- MOCK DATA ---
  // In a real app, this list would be fetched from your backend.
  final List<VIPDiamondPack> _diamondPacks = [
    VIPDiamondPack(id: 'pack1', price: 9.99, diamonds: 1000, createdAt: DateTime.now(), updatedAt: DateTime.now()),
    VIPDiamondPack(id: 'pack2', price: 19.99, diamonds: 2200, createdAt: DateTime.now(), updatedAt: DateTime.now()),
    VIPDiamondPack(id: 'pack3', price: 49.99, diamonds: 6000, createdAt: DateTime.now(), updatedAt: DateTime.now()),
    VIPDiamondPack(id: 'pack4', price: 99.99, diamonds: 13000, createdAt: DateTime.now(), updatedAt: DateTime.now()),
  ];

  // --- UI LOGIC METHODS ---

  // Shows the registration popup.
  void _showRegistrationPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Register as a Coin Seller'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _buildTextField(label: 'Full Name'),
                _buildTextField(label: 'National ID Number'),
                _buildTextField(label: 'Phone Number'),
                _buildTextField(label: 'Email Address'),
                // You can add more fields like 'Upload ID Scan', etc.
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Register'),
              onPressed: () {
                // --- TODO: Add your registration logic here ---
                print('Registration submitted');
                Navigator.of(context).pop();
                // For demonstration, we'll now pretend the user is a seller.
                setState(() {
                  _isCoinSeller = true;
                });
              },
            ),
          ],
        );
      },
    );
  }

  // Simulates finding a user by ID.
  void _findRecipient() {
    // --- TODO: Implement your logic to find a user by ID from your backend ---
    String userId = _recipientIdController.text;
    if (userId.isNotEmpty) {
      print('Searching for user with ID: $userId');
      // Mock finding a user.
      setState(() {
        _foundRecipient = MockUser(id: userId, name: 'Recipient User', avatarUrl: 'https://i.pravatar.cc/150?u=$userId');
      });
    }
  }

  // Simulates sending coins.
  void _sendCoins() {
    // --- TODO: Implement your logic to send coins ---
    if (_foundRecipient != null && _amountController.text.isNotEmpty) {
      print('Sending ${_amountController.text} coins to user ID: ${_foundRecipient!.id}');
      // Show a confirmation snackbar
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully sent ${_amountController.text} coins to ${_foundRecipient!.name}'))
      );
      // Reset the fields
      setState(() {
        _recipientIdController.clear();
        _amountController.clear();
        _foundRecipient = null;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Using a container with your gradient as the base
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFDCB3FF), Color(0xFFB3E5FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          // Based on the user status, show the correct view
          child: _isCoinSeller ? _buildSellerView() : _buildRegistrationView(),
        ),
      ),
    );
  }

  // --- WIDGET BUILDER METHODS ---

  // View for users who are NOT yet coin sellers.
  Widget _buildRegistrationView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Become a Coin Seller',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, backgroundColor: Colors.amber, // Text color
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            onPressed: _showRegistrationPopup,
            child: const Text('Register as a Coin Seller'),
          ),
        ],
      ),
    );
  }

  // Main view for registered coin sellers.
  Widget _buildSellerView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCurrentBalanceCard(),
          const SizedBox(height: 24),
          _buildSectionTitle('Buy More Coins'),
          _buildBuyPacksList(),
          const SizedBox(height: 24),
          _buildSectionTitle('Send Coins to a User'),
          _buildTransferCard(),
        ],
      ),
    );
  }

  // Card showing the seller's current coin balance.
  Widget _buildCurrentBalanceCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'Your Current Coin Balance',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 36),
                const SizedBox(width: 10),
                Text(
                  '$_userCoins',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // List of VIPDiamondPack items available for purchase.
  Widget _buildBuyPacksList() {
    return Column(
      children: _diamondPacks.map((pack) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: const Icon(Icons.diamond, color: Colors.lightBlue),
          title: Text('${pack.diamonds} Diamonds'),
          subtitle: Text('Price: \$${pack.price.toStringAsFixed(2)}'),
          trailing: ElevatedButton(
            onPressed: () {
              // --- TODO: Add your purchase logic here ---
              print('Buying pack: ${pack.id}');
            },
            child: const Text('Buy'),
          ),
        ),
      )).toList(),
    );
  }

  // Card containing the UI for transferring coins to another user.
  Widget _buildTransferCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recipient User ID'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _recipientIdController,
                    decoration: const InputDecoration(
                      hintText: 'Enter user ID',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _findRecipient,
                  style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white
                  ),
                ),
              ],
            ),
            // This part appears after a user is found
            if (_foundRecipient != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(_foundRecipient!.avatarUrl),
                ),
                title: Text(_foundRecipient!.name),
                subtitle: Text('ID: ${_foundRecipient!.id}'),
              ),
              const SizedBox(height: 16),
              const Text('Amount to Send'),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'e.g., 500',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monetization_on, color: Colors.amber),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _sendCoins,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)
                  ),
                  child: const Text('Confirm & Send'),
                ),
              )
            ],
          ],
        ),
      ),
    );
  }

  // Helper for consistent text field styling in the popup.
  Widget _buildTextField({required String label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  // Helper for consistent section titles.
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
      ),
    );
  }
}
