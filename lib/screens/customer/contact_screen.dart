import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  String _topic = 'Order inquiry';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: const Text('Contact us')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(17, 3, 17, 22),
          children: [
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Open today · 10:00 AM – 10:00 PM',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Compostela hub',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Get in touch',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            const Text(
              'Questions about an order or account? Our sample contact options are below.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 13),
            _ContactCard(
              icon: Icons.mail_outline_rounded,
              label: 'EMAIL US',
              value: 'support@burgerbites.app',
              action: 'Email',
              onTap: () => _notice('Email support'),
            ),
            _ContactCard(
              icon: Icons.call_outlined,
              label: 'CALL US',
              value: '+63 912 345 6789',
              action: 'Call',
              onTap: () => _notice('Phone support'),
            ),
            _ContactCard(
              icon: Icons.public_rounded,
              label: 'OFFICIAL FACEBOOK PAGE',
              value: 'BurgerBites Compostela',
              action: 'View page',
              onTap: () => _notice('Social links'),
            ),
            const SizedBox(height: 7),
            Container(
              height: 122,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE2F3E8), Color(0xFFC6E8D4)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _MapGridPainter()),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 37,
                      height: 37,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.brandOrange,
                        size: 23,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Text(
                        'Compostela, Cebu · map preview',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Store details shown here are sample project content.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 8),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Send us a message',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Messages are validated locally; no support backend is connected yet.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(height: 11),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full name'),
                    validator: (value) =>
                        value == null || value.trim().length < 2
                        ? 'Enter your name.'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email or mobile number',
                    ),
                    validator: (value) =>
                        value == null || value.trim().length < 5
                        ? 'Enter a way for us to contact you.'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _topic,
                    decoration: const InputDecoration(labelText: 'Topic'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Order inquiry',
                        child: Text('Order inquiry'),
                      ),
                      DropdownMenuItem(
                        value: 'Account help',
                        child: Text('Account help'),
                      ),
                      DropdownMenuItem(
                        value: 'Feedback',
                        child: Text('Feedback'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _topic = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _messageController,
                    minLines: 3,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Message'),
                    validator: (value) =>
                        value == null || value.trim().length < 5
                        ? 'Add a short message.'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text('Send message'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Frequently asked',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 7),
            const _FaqTile(
              question: 'Delivery area in Compostela?',
              answer: 'The delivery zone shown in this prototype is sample content. Confirm availability when a real service is connected.',
            ),
            const _FaqTile(
              question: 'What payment options are available?',
              answer: 'Checkout options are display-only in this demo. No payment provider is connected.',
            ),
            const _FaqTile(
              question: 'How do I check order status?',
              answer: 'The order history uses local sample data. Live tracking is not connected yet.',
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Message form validated. Sending is not connected in this demo.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _notice(String feature) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$feature is a sample contact option.'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.action,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 7),
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Container(
          width: 33,
          height: 33,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.brandOrange, size: 17),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            action,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: AppColors.border),
    ),
    child: ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
      ),
      tilePadding: const EdgeInsets.symmetric(horizontal: 11),
      childrenPadding: const EdgeInsets.fromLTRB(11, 0, 11, 11),
      visualDensity: VisualDensity.compact,
      children: [
        Text(
          answer,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 9,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .55)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i < 5; i++) {
      final x = size.width * i / 5;
      final y = size.height * i / 5;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + (i.isEven ? 13 : -8), size.height),
        paint,
      );
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + (i.isEven ? -10 : 8)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
