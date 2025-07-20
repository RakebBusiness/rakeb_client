import 'package:flutter/material.dart';

class PromotionsScreen extends StatelessWidget {
  const PromotionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Promotions',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF32C156),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Offers',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: ListView(
                children: [
                  _buildPromotionCard(
                    title: '50% OFF First Ride',
                    description: 'Get 50% discount on your first ride with Rakeb',
                    discount: '50%',
                    validUntil: 'Valid until Dec 31, 2024',
                    color: Colors.orange,
                  ),
                  _buildPromotionCard(
                    title: 'Weekend Special',
                    description: '20% off on all weekend rides',
                    discount: '20%',
                    validUntil: 'Valid on weekends',
                    color: Colors.purple,
                  ),
                  _buildPromotionCard(
                    title: 'Student Discount',
                    description: 'Special rates for university students',
                    discount: '30%',
                    validUntil: 'Valid with student ID',
                    color: Colors.blue,
                  ),
                  _buildPromotionCard(
                    title: 'Loyalty Bonus',
                    description: 'Complete 10 rides and get 1 free',
                    discount: 'FREE',
                    validUntil: 'Ongoing offer',
                    color: const Color(0xFF32C156),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionCard({
    required String title,
    required String description,
    required String discount,
    required String validUntil,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      validUntil,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Center(
                child: Text(
                  discount,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}